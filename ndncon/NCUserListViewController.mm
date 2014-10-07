//
//  NCUserListViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndnrtc/ndnrtc-library.h>

#import "NCUserListViewController.h"
#import "NCPreferencesController.h"
#import "NSObject+NCAdditions.h"
#import "AppDelegate.h"
#import "User.h"
#import "NCNdnRtcLibraryController.h"
#import "NSDictionary+NCNdnRtcAdditions.h"
#import "NSObject+NCAdditions.h"

NSString* const kNCSessionInfoKey = @"sessionInfo";
NSString* const kNCHubPrefixKey = @"hubPrefix";

using namespace ndnrtc;
using namespace ndnrtc::new_api;

//******************************************************************************
@interface NCSessionInfoContainer()
{
    SessionInfo *_sessionInfo;
}

@end

@implementation NCSessionInfoContainer

-(id)initWithSessionInfo:(void*)sessionInfo
{
    self = [super init];
    
    if (self)
    {
        _sessionInfo = new SessionInfo(*((SessionInfo*)sessionInfo));
    }
    
    return self;
}

-(void)dealloc
{
    delete _sessionInfo;
}

+(NCSessionInfoContainer*)containerWithSessionInfo:(void*)sessionInfo
{
    NCSessionInfoContainer *container = [[NCSessionInfoContainer alloc] initWithSessionInfo:sessionInfo];
    return container;
}

-(void*)sessionInfo
{
    return _sessionInfo;
}

-(NSArray *)audioStreamsConfigurations
{
    NSMutableArray *streams = [NSMutableArray array];
    
    if (_sessionInfo)
        for (std::vector<MediaStreamParams*>::iterator it = _sessionInfo->audioStreams_.begin();
             it != _sessionInfo->audioStreams_.end(); it++)
            [streams addObject:[NSDictionary configurationWithAudioStreamParams:*(*it)]];
    
    return streams;
}

-(NSArray *)videoStreamsConfigurations
{
    NSMutableArray *streams = [NSMutableArray array];
    
    if (_sessionInfo)
        for (std::vector<MediaStreamParams*>::iterator it = _sessionInfo->videoStreams_.begin();
             it != _sessionInfo->videoStreams_.end(); it++)
            [streams addObject:[NSDictionary configurationWithVideoStreamParams:*(*it)]];
    
    return streams;
}

-(BOOL)isEqual:(id)object
{
    if (!object || ![object isKindOfClass:[NCSessionInfoContainer class]])
        return NO;
    
    return [[self audioStreamsConfigurations] isEqual:[object audioStreamsConfigurations]] &&
        [[self videoStreamsConfigurations] isEqual:[object videoStreamsConfigurations]];
}

@end

//******************************************************************************
class RemoteSessionObserver : public IRemoteSessionObserver
{
public:
    RemoteSessionObserver(std::string& username, std::string& prefix):
    username_(username), prefix_(prefix) {};
    
    std::string username_, prefix_, sessionPrefix_;
    NCSessionStatus lastStatus_ = SessionStatusOffline;
    SessionInfo lastSessionInfo_;
    
private:
    bool freshStart_ = true;
    unsigned int nTimeouts_ = 0;
    
    NSDictionary* sessionUserInfo()
    {
        return @{kNCSessionUsernameKey: [NSString stringWithCString:username_.c_str() encoding:NSASCIIStringEncoding],
                 kNCHubPrefixKey: [NSString stringWithCString:prefix_.c_str() encoding:NSASCIIStringEncoding],
                 kNCSessionPrefixKey: [NSString stringWithCString:sessionPrefix_.c_str() encoding:NSASCIIStringEncoding]};
    }
    
    void
    onSessionInfoUpdate(const new_api::SessionInfo& sessionInfo)
    {
        freshStart_ = false;
        lastSessionInfo_ = sessionInfo;
        lastStatus_ = (sessionInfo.audioStreams_.size() == 0 &&
                       sessionInfo.videoStreams_.size() == 0)?SessionStatusOnlineNotPublishing:
        SessionStatusOnlinePublishing;
        NSMutableDictionary *userInfo = [sessionUserInfo() mutableCopy];
        [userInfo setObject:@(lastStatus_)
                     forKey:kNCSessionStatusKey];
        [userInfo setObject:[NCSessionInfoContainer containerWithSessionInfo: (void*)&sessionInfo]
                     forKey:kNCSessionInfoKey];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[NSObject alloc] init]
             notifyNowWithNotificationName:NCRemoteSessionStatusUpdateNotification
             andUserInfo:userInfo];
        });
    }
    
    void
    onUpdateFailedWithTimeout()
    {
        nTimeouts_++;

        if (nTimeouts_ > 5 || freshStart_)
            notifyStatusUpdate(SessionStatusOffline);
        
        freshStart_ = false;
    }
    
    void
    onUpdateFailedWithError(const char* errMsg)
    {
        NSMutableDictionary *userInfo = [sessionUserInfo() mutableCopy];
        
        [userInfo setObject:[NSString stringWithCString:errMsg encoding:NSASCIIStringEncoding]
                     forKey: kNCSessionErrorMessageKey];
        
        NSLog(@"update failed %@", userInfo);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"post update failed");
            [[[NSObject alloc] init]
             notifyNowWithNotificationName:NCRemoteSessionErrorNotification
             andUserInfo:userInfo];
        });
    }
    
    void
    notifyStatusUpdate(NCSessionStatus status)
    {
        lastStatus_ = status;
        
        NSMutableDictionary *userInfo = [sessionUserInfo() mutableCopy];
        
        [userInfo setObject:@(status)
                     forKey:kNCSessionStatusKey];
        
        NSLog(@"status update %@", userInfo);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"post status update");
            [[[NSObject alloc] init]
             notifyNowWithNotificationName:NCRemoteSessionStatusUpdateNotification
             andUserInfo:userInfo];
        });
    }
};

//******************************************************************************
@interface NCUserListViewController()
{
    std::vector<RemoteSessionObserver*> _sessionObservers;
    dispatch_queue_t _observerQueue;
}

+(NCUserListViewController*)sharedInstance;

@property (weak) IBOutlet NSArrayController *userController;
@property (weak) IBOutlet NSTableView *tableView;

@end

@implementation NCUserListViewController

+(NCUserListViewController *)sharedInstance
{
    return ((AppDelegate*)[NSApp delegate]).userListViewController;
}

+(NCSessionStatus)sessionStatusForUser:(NSString *)user withPrefix:(NSString *)prefix
{
    RemoteSessionObserver *observer = [[NCUserListViewController sharedInstance] observerForUser:user andPrefix:prefix];
    NCSessionStatus status = (observer)?observer->lastStatus_:SessionStatusOffline;
    
    return status;
}

-(id)init
{
    self = [super init];
    
    if (self)
        [self initialize];
    
    return self;
}

-(void)awakeFromNib
{
    [self.userController addObserver:self forKeyPaths:@"arrangedObjects.name", @"arrangedObjects.prefix", nil];

    [[NCPreferencesController sharedInstance] addObserver:self
                                              forKeyPaths:NSStringFromSelector(@selector(daemonHost)),
     NSStringFromSelector(@selector(daemonPort)), nil];
}

-(void)initialize
{
    _observerQueue = dispatch_queue_create("queue.observers", DISPATCH_QUEUE_SERIAL);
    [self subscribeForNotificationsAndSelectors:
     NCRemoteSessionStatusUpdateNotification,
     @selector(sessionDidUpdateStatus:),
     nil];
}

- (void)dealloc
{
    [self unsubscribeFromNotifications];
    [self.userController removeObserver:self forKeyPaths: @"arrangedObjects.name", @"arrangedObjects.prefix", nil];
    
    dispatch_sync(_observerQueue, ^{
        while (_sessionObservers.size())
            [self stopObserver: _sessionObservers[0]];
    });
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if (object == [NCPreferencesController sharedInstance])
        [self restartObservers];
    else
        [self checkAndUpdateSessionObservers];
}

-(void)clearSelection
{
    [self.tableView deselectAll:nil];
}

// NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.tableView.selectedRow < [self.userController.arrangedObjects count])
    {
        id user = [self.userController.arrangedObjects objectAtIndex:self.tableView.selectedRow];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(userListViewController:userWasChosen:)])
            [self.delegate userListViewController:self userWasChosen:[self userInfoDictionaryForUser:[user name] withPrefix:[user prefix]]];
    }
}

// private
-(void)sessionDidUpdateStatus:(NSNotification*)notification
{
    NSString *userName = [notification.userInfo objectForKey:kNCSessionUsernameKey];
    NSString *prefix = [notification.userInfo objectForKey:kNCHubPrefixKey];
    NCSessionStatus status = (NCSessionStatus)[[notification.userInfo objectForKey:kNCSessionStatusKey] intValue];
    
    if (userName && prefix)
    {
        [self.userController.arrangedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([[obj name] isEqualToString:userName] && [[obj prefix] isEqualToString:prefix])
                [obj setStatusImage:[[NCNdnRtcLibraryController sharedInstance] imageForSessionStatus:status]];
        }];
    }
}

-(void)checkAndUpdateSessionObservers
{
    [self stopOldObservers];
    
    BOOL updated = NO;
    
    for (id obj in self.userController.arrangedObjects)
    {
        NSString *userName = [obj name];
        NSString *prefix = [obj prefix];
        
        if (![userName isEqualToString:@"username"])
            if (![self hasObserverForUser:userName andPrefix:prefix])
            {
                updated = YES;
                [self startObserverForUser:userName andPrefix:prefix];
            }
    }
    
    if (updated)
        if (self.delegate && [self.delegate respondsToSelector:@selector(userListViewControllerUserListUpdated:)])
            [self.delegate userListViewControllerUserListUpdated:self];
}

-(void)stopOldObservers
{
    __block BOOL updated = NO;
    __block int i = 0;
    while (i < _sessionObservers.size())
    {
        dispatch_sync(_observerQueue, ^{
            if (![self isObserverPresentedInUserList:_sessionObservers[i]])
            {
                [self stopObserver:_sessionObservers[i]];
                updated = YES;
            }
            else
                i++;
        });
    }
    
    if (updated)
        if (self.delegate && [self.delegate respondsToSelector:@selector(userListViewControllerUserListUpdated:)])
            [self.delegate userListViewControllerUserListUpdated:self];
}

-(void)startObserverForUser:(NSString*)aUserName andPrefix:(NSString*)aPrefix
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    std::string username = [aUserName cStringUsingEncoding:NSASCIIStringEncoding];
    std::string prefix = [aPrefix cStringUsingEncoding:NSASCIIStringEncoding];
    
    GeneralParams generalParams;
    
    [[NCPreferencesController sharedInstance] getNdnRtcGeneralParameters:&generalParams];
    RemoteSessionObserver *observer = new RemoteSessionObserver(username, prefix);
    std::string sessionPrefix = lib->setRemoteSessionObserver(username, prefix, generalParams, observer);
    observer->sessionPrefix_ = sessionPrefix;
    
    dispatch_sync(_observerQueue, ^{
        _sessionObservers.push_back(observer);
    });
    
    NSLog(@"started observer for %@:%@", aPrefix, aUserName);
}

-(void)stopObserver:(RemoteSessionObserver*)observer
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    lib->removeRemoteSessionObserver(observer->sessionPrefix_);
    
    std::vector<RemoteSessionObserver*>::iterator it = _sessionObservers.begin();
    while (*it != observer && it != _sessionObservers.end()) it++;
    
    if (it != _sessionObservers.end())
        _sessionObservers.erase(it);
    
    NSLog(@"stopped observer for %s:%s", observer->prefix_.c_str(), observer->username_.c_str());
    delete observer;
}

-(BOOL)hasObserverForUser:(NSString*)aUserName andPrefix:(NSString*)aPrefix
{
    return ([self observerForUser:aUserName andPrefix:aPrefix] != NULL);
}

-(RemoteSessionObserver*)observerForUser:(NSString*)aUserName andPrefix:(NSString*)aPrefix
{
    std::string username = [aUserName cStringUsingEncoding:NSASCIIStringEncoding];
    std::string prefix = [aPrefix cStringUsingEncoding:NSASCIIStringEncoding];
    
    __block RemoteSessionObserver *observer = NULL;
    
    dispatch_sync(_observerQueue, ^{
        std::vector<RemoteSessionObserver*>::iterator it = _sessionObservers.begin();
        
        while (it != _sessionObservers.end() && !observer)
        {
            if (((*it)->username_ == username) && ((*it)->prefix_ == prefix))
                observer = *it;
            it++;
        }
    });
    
    return observer;
}

-(BOOL)isObserverPresentedInUserList:(RemoteSessionObserver*)observer
{
    NSString *userName = [NSString stringWithCString:observer->username_.c_str()
                                            encoding:NSASCIIStringEncoding];
    NSString *prefix = [NSString stringWithCString:observer->prefix_.c_str()
                                          encoding:NSASCIIStringEncoding];
    
    NSIndexSet *set = [self.userController.arrangedObjects indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        *stop = (([userName isEqualToString:[obj name]]) &&
                 [prefix isEqualToString:[obj prefix]]);
        return *stop;
    }];
    
    if (set.count > 1)
        NSLog(@"two or more observers for %@:%@", prefix, userName);
    
    return (set.count == 1);
}

-(NSDictionary*)userInfoDictionaryForUser:(NSString*)userName withPrefix:(NSString*)prefix
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    [userInfo setObject:userName forKey:kNCSessionUsernameKey];
    [userInfo setObject:prefix forKey:kNCHubPrefixKey];
    
    RemoteSessionObserver *observer = [self observerForUser:userName andPrefix:prefix];
    
    if (observer)
    {
        [userInfo setObject:@(observer->lastStatus_) forKey:kNCSessionStatusKey];
        [userInfo setObject:[NCSessionInfoContainer containerWithSessionInfo:(void*)&observer->lastSessionInfo_] forKey:kNCSessionInfoKey];
        [userInfo setObject:[NSString stringWithCString:observer->sessionPrefix_.c_str() encoding:NSASCIIStringEncoding] forKey:kNCSessionPrefixKey];
    }
    
    return userInfo;
}

-(void)restartObservers
{
    NSLog(@"restarting observers");
          
    [self.userController.arrangedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *user = [obj name];
        NSString *prefix = [obj prefix];
        
        // remove observer
        [self stopObserver:[self observerForUser:user andPrefix:prefix]];
        [self startObserverForUser:user andPrefix:prefix];
    }];
}

@end

@interface NCUserListCell : NSTableCellView

@property (nonatomic, weak) IBOutlet NSTextField *hintTextField;


@end

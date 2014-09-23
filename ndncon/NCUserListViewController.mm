//
//  NCUserListViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndnrtc/ndnrtc-library.h>

#import "NCUserListViewController.h"
#import "NCNdnRtcLibraryController.h"
#import "NCPreferencesController.h"
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

@end

//******************************************************************************
class RemoteSessionObserver : public IRemoteSessionObserver
{
public:
    RemoteSessionObserver(std::string& username, std::string& prefix):
    username_(username), prefix_(prefix) {};
    
    std::string username_, prefix_;
    
private:
    bool freshStart_ = true;
    unsigned int nTimeouts_ = 0;
    
    NSDictionary* sessionUserInfo()
    {
        return @{kNCSessionUsernameKey: [NSString stringWithCString:username_.c_str() encoding:NSASCIIStringEncoding],
                 kNCHubPrefixKey: [NSString stringWithCString:prefix_.c_str() encoding:NSASCIIStringEncoding]};
    }
    
    void
    onSessionInfoUpdate(const new_api::SessionInfo& sessionInfo)
    {
//        std::cout << "session update: " << std::endl << sessionInfo;
        
        freshStart_ = false;
        
        NCSessionStatus status = (sessionInfo.audioStreams_.size() == 0 &&
                                  sessionInfo.videoStreams_.size() == 0)?SessionStatusOnlineNotPublishing:
                                    SessionStatusOnlinePublishing;
        NSMutableDictionary *userInfo = [sessionUserInfo() mutableCopy];
        [userInfo setObject:@(status)
                     forKey:kNCSessionStatusKey];
        [userInfo setObject:[NCSessionInfoContainer containerWithSessionInfo: (void*)&sessionInfo]
                     forKey:kNCSessionInfoKey];
        
        [[[NSObject alloc] init]
         notifyNowWithNotificationName:NCSessionStatusUpdateNotification
         andUserInfo:userInfo];
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
        
        [[[NSObject alloc] init]
         notifyNowWithNotificationName:NCSessionErrorNotification
         andUserInfo:userInfo];
    }
    
    void
    notifyStatusUpdate(NCSessionStatus status)
    {
        NSMutableDictionary *userInfo = [sessionUserInfo() mutableCopy];
        
        [userInfo setObject:@(status)
                     forKey:kNCSessionStatusKey];
        
        [[[NSObject alloc] init]
         notifyNowWithNotificationName:NCSessionStatusUpdateNotification
         andUserInfo:userInfo];
    }
};

//******************************************************************************
@interface NCUserListViewController()
{
    std::vector<RemoteSessionObserver*> _sessionObservers;
}

@property (weak) IBOutlet NSArrayController *userController;
@property (weak) IBOutlet NSTableView *tableView;

@end

@implementation NCUserListViewController

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
}

-(void)initialize
{
    [self subscribeForNotificationsAndSelectors:NCSessionStatusUpdateNotification, @selector(sessionDidUpdateStatus:), nil];
}

- (void)dealloc
{
    [self unsubscribeFromNotifications];
    [self.userController removeObserver:self forKeyPaths: @"arrangedObjects.name", @"arrangedObjects.prefix", nil];
    
    while (_sessionObservers.size())
        [self stopObserver: _sessionObservers[0]];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self checkAndUpdateSessionObservers];
}

// NSTableViewDelegate
- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    
}

// private
-(void)sessionDidUpdateStatus:(NSNotification*)notification
{
    NSString *userName = [notification.userInfo objectForKey:kNCSessionUsernameKey];
    NSString *prefix = [notification.userInfo objectForKey:kNCHubPrefixKey];
    NCSessionStatus status = (NCSessionStatus)[[notification.userInfo objectForKey:kNCSessionStatusKey] intValue];
    
    if (userName && prefix)
    {
        NSTableColumn *column = [self.tableView tableColumnWithIdentifier:@"UserCell"];

    }
}

-(void)checkAndUpdateSessionObservers
{
    [self stopOldObservers];
    
    for (id obj in self.userController.arrangedObjects)
    {
        NSString *userName = [obj name];
        NSString *prefix = [obj prefix];
        
        if (![userName isEqualToString:@"username"])
            if (![self hasObserverForUser:userName andPrefix:prefix])
                [self startObserverForUser:userName andPrefix:prefix];
    }
}

-(void)stopOldObservers
{
    int i = 0;
    while (i < _sessionObservers.size())
    {
        if (![self isObserverPresentedInUserList:_sessionObservers[i]])
            [self stopObserver:_sessionObservers[i]];
        else
            i++;
    }
}

-(void)startObserverForUser:(NSString*)aUserName andPrefix:(NSString*)aPrefix
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    std::string username = [aUserName cStringUsingEncoding:NSASCIIStringEncoding];
    std::string prefix = [aPrefix cStringUsingEncoding:NSASCIIStringEncoding];
    
    GeneralParams generalParams;
    
    [[NCPreferencesController sharedInstance] getNdnRtcGeneralParameters:&generalParams];
    RemoteSessionObserver *observer = new RemoteSessionObserver(username, prefix);
    lib->setRemoteSessionObserver(username, prefix, generalParams, observer);
    _sessionObservers.push_back(observer);
    
    NSLog(@"started observer for %@:%@", aPrefix, aUserName);
}

-(void)stopObserver:(RemoteSessionObserver*)observer
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    lib->removeRemoteSessionObserver(observer->username_, observer->prefix_);
    
    std::vector<RemoteSessionObserver*>::iterator it = _sessionObservers.begin();
    while (*it != observer && it != _sessionObservers.end()) it++;
    
    if (it != _sessionObservers.end())
        _sessionObservers.erase(it);
    
    NSLog(@"stopped observer for %s:%s", observer->prefix_.c_str(), observer->username_.c_str());
    delete observer;
}

-(BOOL)hasObserverForUser:(NSString*)aUsername andPrefix:(NSString*)aPrefix
{
    std::string username = [aUsername cStringUsingEncoding:NSASCIIStringEncoding];
    std::string prefix = [aPrefix cStringUsingEncoding:NSASCIIStringEncoding];
    
    std::vector<RemoteSessionObserver*>::iterator it = _sessionObservers.begin();
    BOOL hasObserver = NO;
    
    while (it != _sessionObservers.end() && !hasObserver)
    {
        hasObserver = (((*it)->username_ == username) && ((*it)->prefix_ == prefix));
        it++;
    }

    return hasObserver;
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

@end

@interface NCUserListCell : NSTableCellView

@property (nonatomic, weak) IBOutlet NSTextField *hintTextField;


@end

//
//  NCUserListViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndnrtc/ndnrtc-library.h>
#include <ndnrtc/error-codes.h>

#import "NCUserListViewController.h"
#import "NCPreferencesController.h"
#import "NSObject+NCAdditions.h"
#import "AppDelegate.h"
#import "User.h"
#import "NCNdnRtcLibraryController.h"
#import "NSDictionary+NCNdnRtcAdditions.h"
#import "NSObject+NCAdditions.h"
#import "NSString+NCAdditions.h"
#import "ChatRoom.h"
#import "ChatMessage.h"
#import "NCStreamBrowserController.h"

NSString* const kSessionInfoKey = @"sessionInfo";
NSString* const kHubPrefixKey = @"hubPrefix";

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
    username_(username), prefix_(prefix), nTimeouts_(0) {};
    
    std::string username_, prefix_, sessionPrefix_;
    NCSessionStatus lastStatus_ = SessionStatusOffline;
    SessionInfo lastSessionInfo_;
    
    void
    notifyStatusUpdate(NCSessionStatus status)
    {
        NCSessionStatus oldStatus = lastStatus_;
        lastStatus_ = status;
        
        NSMutableDictionary *userInfo = [sessionUserInfo() mutableCopy];
        
        userInfo[kSessionStatusKey]= @(status);
        userInfo[kSessionOldStatusKey] = @(oldStatus);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[NSObject alloc] init]
             notifyNowWithNotificationName:NCRemoteSessionStatusUpdateNotification
             andUserInfo:userInfo];
        });
    }
    
private:
    bool freshStart_ = true;
    unsigned int nTimeouts_;
    
    NSDictionary* sessionUserInfo()
    {
        return @{kSessionUsernameKey: [NSString ncStringFromCString:username_.c_str()],
                 kHubPrefixKey: [NSString ncStringFromCString:prefix_.c_str()],
                 kSessionPrefixKey: [NSString ncStringFromCString:sessionPrefix_.c_str()]};
    }
    
    void
    onSessionInfoUpdate(const new_api::SessionInfo& sessionInfo)
    {
        NCSessionStatus oldStatus = lastStatus_;
        nTimeouts_ = 0;
        freshStart_ = false;
        lastSessionInfo_ = sessionInfo;
        lastStatus_ = (sessionInfo.audioStreams_.size() == 0 &&
                       sessionInfo.videoStreams_.size() == 0)?SessionStatusOnlineNotPublishing:
        SessionStatusOnlinePublishing;
        
        if (oldStatus != lastStatus_)
        {
            NSMutableDictionary *userInfo = [sessionUserInfo() mutableCopy];
            userInfo[kSessionStatusKey] = @(lastStatus_);
            userInfo[kSessionOldStatusKey] = @(oldStatus);
            userInfo[kSessionInfoKey] = [NCSessionInfoContainer containerWithSessionInfo: (void*)&sessionInfo];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[NSObject alloc] init]
                 notifyNowWithNotificationName:NCRemoteSessionStatusUpdateNotification
                 andUserInfo:userInfo];
            });
        }
    }
    
    void
    onUpdateFailedWithTimeout()
    {
        nTimeouts_++;

        if (nTimeouts_ == 3 || freshStart_)
            notifyStatusUpdate(SessionStatusOffline);
        
        freshStart_ = false;
    }
    
    void
    onUpdateFailedWithError(int errCode, const char* errMsg)
    {
        NSMutableDictionary *userInfo = [sessionUserInfo() mutableCopy];
        
        [userInfo setObject:[NSString stringWithCString:errMsg
                                               encoding:NSASCIIStringEncoding]
                     forKey: kSessionErrorMessageKey];
        
        // check for specific error codes
        if (errCode == NRTC_ERR_LIBERROR)
            notifyStatusUpdate(SessionStatusOffline);
        
        NSLog(@"update failed %@", userInfo);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[NSObject alloc] init]
             notifyNowWithNotificationName:NCRemoteSessionErrorNotification
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
@property (weak) User *selectedUser;

@end

@implementation NCUserListViewController

+(NCUserListViewController *)sharedInstance
{
    return ((AppDelegate*)[NSApp delegate]).userListViewController;
}

+(NCSessionStatus)sessionStatusForUser:(NSString *)user withPrefix:(NSString *)prefix
{
    if (user && prefix)
    {
        RemoteSessionObserver *observer = [[NCUserListViewController sharedInstance] observerForUser:user andPrefix:prefix];
        NCSessionStatus status = (observer)?observer->lastStatus_:SessionStatusOffline;
        
        return status;
    }
    
    return SessionStatusOffline;
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
    [self.tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
     
    [self.userController addObserver:self forKeyPaths:@"arrangedObjects.name", @"arrangedObjects.prefix", nil];

    [[NCPreferencesController sharedInstance] addObserver:self
                                              forKeyPaths:NSStringFromSelector(@selector(daemonHost)),
     NSStringFromSelector(@selector(daemonPort)), nil];
    
    NSResponder *nextResponder = [self.tableView nextResponder];

    if (self != nextResponder)
    {
        [self.tableView setNextResponder:self];
        [self setNextResponder:nextResponder];
    }
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
}

-(void)initialize
{
    _observerQueue = dispatch_queue_create("queue.observers", DISPATCH_QUEUE_SERIAL);
    [self subscribeForNotificationsAndSelectors:
     NCRemoteSessionStatusUpdateNotification, @selector(onRemoteSessionStatusUpdate:),
     NCLocalSessionStatusUpdateNotification, @selector(onLocalSessionStatusUpdate:),
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
    self.selectedUser = nil;
    [self.tableView deselectAll:nil];
}

// NCChatViewControllerDelegate
-(void)chatViewControllerDidFinishLoadingMessages:(NCChatViewController *)chatViewController
{
    NSInteger selected = [self.tableView selectedRow];
    
    [self.tableView reloadData];
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected] byExtendingSelection:NO];
}

// NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.tableView.selectedRow == -1)
        self.selectedUser = nil;
    else if (self.tableView.selectedRow < [self.userController.arrangedObjects count])
    {
        id user = [self.userController.arrangedObjects objectAtIndex:self.tableView.selectedRow];
        
        if (user != self.selectedUser)
        {
            self.selectedUser = user;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(userListViewController:userWasChosen:)])
                [self.delegate userListViewController:self userWasChosen:[self userInfoDictionaryForUser:[user name] withPrefix:[user prefix]]];
        }
    }
}

// NSTableViewDataSource
- (id <NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
    id user = [self.userController.arrangedObjects objectAtIndex:row];
    
    return [NSString stringWithFormat:kNCNdnRtcUserUrlFormat, [user prefix], [user name]];
}

// NSUserNotificationCenterDelegate
-(BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
    shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

-(void)userNotificationCenter:(NSUserNotificationCenter *)center
      didActivateNotification:(NSUserNotification *)notification
{
    User *user = [User userByName:notification.userInfo[kUserNameKey]
                        andPrefix:notification.userInfo[kHubPrefixKey]
                      fromContext:self.userController.managedObjectContext];
    [self.userController setSelectedObjects:@[user]];
}

// private
- (IBAction)deleteSelectedEntry:(id)sender
{
    [self.userController remove:nil];
    [self.tableView reloadData];
}

-(void)onRemoteSessionStatusUpdate:(NSNotification*)notification
{
    NSString *userName = [notification.userInfo objectForKey:kSessionUsernameKey];
    NSString *prefix = [notification.userInfo objectForKey:kHubPrefixKey];
    NCSessionStatus status = (NCSessionStatus)[[notification.userInfo objectForKey:kSessionStatusKey] intValue];

    if (userName && prefix)
    {
        [self.userController.arrangedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([[obj name] isEqualToString:userName] && [[obj prefix] isEqualToString:prefix])
            {
                [obj setStatusImage:[[NCNdnRtcLibraryController sharedInstance] imageForSessionStatus:status]];
                *stop = YES;
            }
        }];
    }
}

-(void)onLocalSessionStatusUpdate:(NSNotification*)notification
{
    NCSessionStatus status = (NCSessionStatus)[notification.userInfo[kSessionStatusKey] integerValue];
    NCSessionStatus oldStatus = (NCSessionStatus)[notification.userInfo[kSessionOldStatusKey] integerValue];
    
    if (status == SessionStatusOffline)
    {
        dispatch_sync(_observerQueue, ^{
            while (_sessionObservers.size())
                [self stopObserver: _sessionObservers[0]];
        });
    }
    else
        if (oldStatus == SessionStatusOffline)
        {
            [self.userController.arrangedObjects enumerateObjectsUsingBlock:
             ^(id obj, NSUInteger idx, BOOL *stop) {
                 NSString *user = [obj name];
                 NSString *prefix = [obj prefix];
                 
                 if (user && prefix)
                     [self startObserverForUser:user andPrefix:prefix];
             }];
        }
}

-(void)checkAndUpdateSessionObservers
{
    [self stopOldObservers];
    
    if ([NCNdnRtcLibraryController sharedInstance].sessionStatus != SessionStatusOffline)
    {
        BOOL updated = NO;
        
        for (id obj in self.userController.arrangedObjects)
        {
            NSString *userName = [obj name];
            NSString *prefix = [obj prefix];
            
            if (userName && prefix &&
                ![userName isEqualToString:@"username"])
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
    
    if (sessionPrefix == "")
    {
        delete observer;
    }
    else
    {
        dispatch_sync(_observerQueue, ^{
            _sessionObservers.push_back(observer);
        });
        
        NSLog(@"started observer for %@:%@", aPrefix, aUserName);
    }
}

-(void)stopObserver:(RemoteSessionObserver*)observer
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    lib->removeRemoteSessionObserver(observer->sessionPrefix_);
    
    std::vector<RemoteSessionObserver*>::iterator it = _sessionObservers.begin();
    while (*it != observer && it != _sessionObservers.end()) it++;
    
    if (it != _sessionObservers.end())
    {
        // we won't see user statuses while being offline
        (*it)->notifyStatusUpdate(SessionStatusOffline);
        _sessionObservers.erase(it);
    }
    
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
    if (userName && prefix)
    {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        
        userInfo[kSessionUsernameKey] = userName;
        userInfo[kHubPrefixKey] = prefix;
        
        RemoteSessionObserver *observer = [self observerForUser:userName andPrefix:prefix];
        
        if (observer)
        {
            [userInfo setObject:@(observer->lastStatus_) forKey:kSessionStatusKey];
            [userInfo setObject:[NCSessionInfoContainer containerWithSessionInfo:(void*)&observer->lastSessionInfo_] forKey:kSessionInfoKey];
            [userInfo setObject:[NSString stringWithCString:observer->sessionPrefix_.c_str() encoding:NSASCIIStringEncoding] forKey:kSessionPrefixKey];
        }
        
        return userInfo;
    }
    
    return nil;
}

-(void)updateCellBadgeNumber:(NSUInteger)number
             forCellWithUser:(User*)user
{
    [self.tableView reloadData];
}

-(void)restartObservers
{
    NSLog(@"restarting observers");
          
    [self.userController.arrangedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *user = [obj name];
        NSString *prefix = [obj prefix];

        if (user && prefix)
        {
            // remove observer
            [self stopObserver:[self observerForUser:user andPrefix:prefix]];
            [self startObserverForUser:user andPrefix:prefix];
        }
    }];
}

@end

@interface NCUserListCell : NSTableCellView

@property (nonatomic, weak) IBOutlet NSImageView *unreadMessagesBackImageView;
@property (nonatomic, weak) IBOutlet NSTextField *unreadMessagesTextField;

@end

@implementation NCUserListCell

-(void)setObjectValue:(id)objectValue
{
    [super setObjectValue:objectValue];
    
    if (objectValue)
    {
        NSManagedObjectContext *context = [(AppDelegate*)[NSApp delegate] managedObjectContext];
        ChatRoom *chatRoom = [ChatRoom chatRoomWithId:[objectValue privateChatRoomId]
                                          fromContext:context];
        NSArray *unreadMessages = [ChatMessage unreadTextMessagesFromUser:objectValue inChatroom:chatRoom];
        
        if (unreadMessages.count)
        {
            self.unreadMessagesBackImageView.hidden = NO;
            self.unreadMessagesTextField.hidden = NO;
            self.unreadMessagesTextField.stringValue = [NSString stringWithFormat:@"%lu", (unsigned long)unreadMessages.count];
        }
        else
        {
            self.unreadMessagesBackImageView.hidden = YES;
            self.unreadMessagesTextField.hidden = YES;
        }
    }
}

@end

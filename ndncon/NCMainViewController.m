//
//  NCMainViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCMainViewController.h"
#import "NCPreferencesController.h"
#import "NSObject+NCAdditions.h"
#import "NCNdnRtcLibraryController.h"
#import "NCConversationInfoView.h"
#import "NCErrorController.h"
#import "AppDelegate.h"
#import "NSString+NCAdditions.h"
#import "NCConferenceViewController.h"
#import "NCDiscoveryLibraryController.h"
#import "NCChatLibraryController.h"
#import "ChatMessage.h"
#import "ChatRoom.h"
#import "User.h"

#define STATUS_POPUP_OFFLINE_IDX 0
#define STATUS_POPUP_PASSIVE_IDX 1
#define STATUS_POPUP_ONLINE_IDX 2

@interface NCMainViewController ()

@property (nonatomic, strong) NSDictionary *conversationConfiguration;

@property (nonatomic, strong) NCConversationViewController *conversationViewController;
@property (weak) IBOutlet NSPopUpButton *statusPopUpButton;
@property (weak) IBOutlet NCConversationInfoView *conversationInfoView;
@property (weak) IBOutlet NSTextField *conversationInfoStatusLabel;
@property (nonatomic, strong) NCUserViewController *userViewController;
@property (weak) IBOutlet NSButton *startPublishingButton;
@property (nonatomic, strong) NCConferenceViewController *conferenceViewController;
@property (nonatomic, readonly) NSManagedObjectContext *context;
@property (weak) IBOutlet NSTabView *userlistTabView;
@property (weak) IBOutlet NCConferenceListViewController *conferenceListViewController;

@end

@implementation NCMainViewController

-(id)init
{
    self = [super init];
    
    if (self)
        [self initialize];
    
    return self;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
        [self initialize];
    
    return self;
}

-(void)initialize
{
    [self subscribeForNotificationsAndSelectors:
     NCLocalSessionStatusUpdateNotification, @selector(onSessionStatusUpdate:),
     NCLocalSessionErrorNotification, @selector(onSessionError:),
     NSApplicationWillTerminateNotification, @selector(onAppWillTerminate:),
     NCChatMessageNotification, @selector(onNewChatMessage:),
     nil];
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
}

-(void)awakeFromNib
{
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    self.view.layer.borderColor = [NSColor darkGrayColor].CGColor;
    self.view.layer.borderWidth = 1.f;
    self.conversationInfoView.status = [NCMainViewController fromSessionSatus:[NCNdnRtcLibraryController sharedInstance].sessionStatus];
    [self.conversationInfoView registerForDraggedTypes: @[NSStringPboardType]];
}

- (IBAction)changeStatus:(id)sender
{
    if ([self.statusPopUpButton.itemArray indexOfObject:self.statusPopUpButton.selectedItem] == STATUS_POPUP_OFFLINE_IDX &&
        [NCNdnRtcLibraryController sharedInstance].sessionStatus != SessionStatusOffline)
    {
        if (self.conversationViewController.participants.count > 0)
            [self.conversationViewController endConversation:self];
        
        [[NCNdnRtcLibraryController sharedInstance] stopSession];
    }
    
    if ([self.statusPopUpButton.itemArray indexOfObject:self.statusPopUpButton.selectedItem] == STATUS_POPUP_PASSIVE_IDX &&
        [NCNdnRtcLibraryController sharedInstance].sessionStatus != SessionStatusOnlineNotPublishing)
    {
        if ([NCNdnRtcLibraryController sharedInstance].sessionStatus == SessionStatusOffline)
            [[NCNdnRtcLibraryController sharedInstance] startSession];
        else
        {
            [self.conversationViewController endConversation:self];
        }
    }
}

- (IBAction)startPublishing:(id)sender
{
    [self startConverstaionIfNotStarted];
    [self.conversationViewController startPublishingWithConfiguration:self.conversationConfiguration];
    [self loadCurrentView:self.conversationViewController.view];
}

- (IBAction)startPublishingCustom:(id)sender {
    NSLog(@"customize...");
}

#pragma mark - NCConferenceListViewControllerDelegate
-(void)conferenceListController:(NCConferenceListViewController *)conferenceListController
               didAddConference:(Conference *)conference
{
    self.conferenceViewController = [[NCConferenceViewController alloc] init];
    self.conferenceViewController.delegate = self;
    [self loadCurrentView:self.conferenceViewController.view];
    
    self.conferenceViewController.isOwner = YES;
    self.conferenceViewController.isEditable = YES;
    self.conferenceViewController.conference = conference;
    
    [self toggleUserList:YES];
    [self.userListViewController clearSelection];
}

-(void)conferenceListController:(NCConferenceListViewController *)conferenceListController
            didSelectConference:(id)conference
{
    self.conferenceViewController = [[NCConferenceViewController alloc] init];
    self.conferenceViewController.delegate = self;
    [self loadCurrentView:self.conferenceViewController.view];

    self.conferenceViewController.isOwner = ![conference isRemote];
    self.conferenceViewController.isEditable = NO;
    self.conferenceViewController.conference = conference;    
}
-(void)conferenceListController:(NCConferenceListViewController *)conferenceListController
            wantsDeleteConference:(Conference *)conference
{
    [self withdrawConference:conference];
}


#pragma mark - NCConferenceViewControllerDelegate
-(void)conferenceViewControllerDidCancelConference:(NCConferenceViewController *)conferenceViewController
{
    [self withdrawConference:conferenceViewController.conference];
    [self toggleUserList:NO];
}

-(void)conferenceViewControllerDidJoinConference:(NCConferenceViewController *)conferenceViewController
{
    [self startConverstaionIfNotStarted];
    [self loadCurrentView:self.conversationViewController.view];
    [self.conversationViewController startConference:conferenceViewController.conference];
    [self.conferenceListViewController clearSelection];
}

-(void)conferenceViewControllerDidPublishConference:(NCConferenceViewController *)conferenceViewController
{
    [self toggleUserList:NO];
    [self.conferenceListViewController reloadData];
}

#pragma mark - NCConversationViewControllerDelegate
-(void)viewWasClicked:(NCClickableView *)view
{
    if (self.conversationInfoView == view)
    {
        if (self.conversationViewController.currentConversationStatus == SessionStatusOffline ||
            (self.conversationViewController.participants.count == 0 &&
             self.conversationViewController.currentConversationStatus == SessionStatusOnlineNotPublishing))
        {
            [self loadCurrentView: self.initialView];
        }
        else
        {
            [self loadCurrentView:self.conversationViewController.view];
        }
        
        [self.userListViewController clearSelection];
        [self.conferenceListViewController clearSelection];
    }
}

-(BOOL)dragAndDropView:(NSView *)view shouldAcceptDraggedUrls:(NSArray *)nrtcUserUrlArray
{
    __block BOOL hasOnline = NO;
    
    [nrtcUserUrlArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *username = [obj userNameFromNrtcUrlString];
        NSString *prefix = [obj prefixFromNrtcUrlString];
        
        NSDictionary *userInfo = [self.userListViewController userInfoDictionaryForUser:username
                                                                             withPrefix:prefix];
        
        if (userInfo)
        {
            NCSessionStatus status = [userInfo[kSessionStatusKey] integerValue];
            hasOnline = (status == SessionStatusOnlinePublishing);
        }
        *stop = hasOnline;
    }];
    
    return hasOnline;
}

-(void)dragAndDropView:(NSView *)view didAcceptDraggedUrls:(NSArray *)nrtcUserUrlArray
{
    [nrtcUserUrlArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *username = [obj userNameFromNrtcUrlString];
        NSString *prefix = [obj prefixFromNrtcUrlString];
        
        NSDictionary *userInfo = [self.userListViewController userInfoDictionaryForUser:username
                                                                             withPrefix:prefix];
        
        if (userInfo)
        {
            NCSessionStatus status = [userInfo[kSessionStatusKey] integerValue];
            if (status == SessionStatusOnlinePublishing)
                [self startFetchingFromUser:userInfo];
        }

    }];
}

#pragma mark - NCUserListViewControllerDelegate
-(void)userListViewController:(NCUserListViewController *)userListViewController
                userWasChosen:(NSDictionary *)user
{
    NCSessionInfoContainer *sessionInfo = [user valueForKey:kSessionInfoKey];
    
    self.userViewController = [[NCUserViewController alloc] init];
    self.userViewController.chatViewController.delegate = self.userListViewController;
    self.userViewController.userInfo = user;
    self.userViewController.sessionInfo = sessionInfo;
    self.userViewController.delegate = self;
    
    [self loadCurrentView:self.userViewController.view];
}

-(void)userListViewControllerUserListUpdated:(NCUserListViewController *)userListViewController
{
    [(AppDelegate*)[NSApp delegate] commitManagedContext];
}

#pragma mark - NCConversationViewControllerDelegate
-(void)conversationViewControllerDidEndConversation:(NCConversationViewController *)converstaionVc
{
    self.conversationViewController = nil;
    [self loadCurrentView:self.initialView];
}

#pragma mark - NCUserViewControllerDelegate
-(void)userViewControllerFetchStreamsClicked:(NCUserViewController *)userVc
{
    [self startFetchingFromUser:userVc.userInfo];
}

-(void)onAppWillTerminate:(NSNotification*)notification
{
    if (self.conversationViewController.participants.count > 0)
        [self.conversationViewController endConversation:nil];
    
    [[NCNdnRtcLibraryController sharedInstance] releaseLibrary];
}

#pragma mark - NCConferenceListViewControllerDelegate
-(void)conferenceListController:(NCConferenceListViewController *)conferenceListController remoteConferenceWithdrawed:(id<ConferenceEntityProtocol>)conference
{
    if (self.conferenceViewController.conference == conference)
        [self loadCurrentView:self.initialView];
}

// private
-(void)onNewChatMessage:(NSNotification*)notification
{
    NSString *chatRoomId = notification.userInfo[NCChatRoomIdKey];
    User *user = notification.userInfo[NCChatMessageUserKey];
    
    if ([chatRoomId isEqualTo:self.userViewController.chatViewController.chatRoomId] &&
        self.userViewController.view == self.currentView)
    {
        [self.userViewController.chatViewController newChatMessage:notification];
    }
    else if (user) // for messages from self - user is nil
    {
        if ([notification.userInfo[NCChatMessageTypeKey] isEqualTo:kChatMesageTypeText])
        {
            NSUserNotification *userNotification = [[NSUserNotification alloc] init];
            userNotification.title = user.name;
            userNotification.informativeText = notification.userInfo[NCChatMessageBodyKey];
            userNotification.soundName = NSUserNotificationDefaultSoundName;
            userNotification.userInfo = @{kUserNameKey:user.name,
                                          kHubPrefixKey:user.prefix};
            
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
        }
        
        ChatRoom *chatRoom = [ChatRoom chatRoomWithId:chatRoomId
                                          fromContext:self.context];
        NSArray *unreadMessages = [ChatMessage unreadTextMessagesFromUser:user
                                                               inChatroom:chatRoom];
        // update cell and post notification
        [self.userListViewController updateCellBadgeNumber:unreadMessages.count
                                           forCellWithUser:user];
    }
}
-(void)withdrawConference:(Conference*)conference
{
    [[NCDiscoveryLibraryController sharedInstance] withdrawConference:conference];
    [self.context deleteObject:conference];
    [self.context save:NULL];
    [self.conferenceListViewController reloadData];
    [self loadCurrentView:self.initialView];
}

-(void)toggleUserList:(BOOL)userListVisible
{
    [self.userlistTabView selectTabViewItemWithIdentifier:(userListVisible)?@"UserList":@"ConferencesList"];
}

-(NSManagedObjectContext *)context
{
    return [(AppDelegate*)[NSApp delegate] managedObjectContext];
}

-(void)startFetchingFromUser:(NSDictionary*)userInfo
{
    [self.userListViewController clearSelection];
    [self startConverstaionIfNotStarted];
    [self loadCurrentView:self.conversationViewController.view];
    [self.conversationViewController startFetchingWithConfiguration:userInfo];
}

-(void)startConverstaionIfNotStarted
{
    if (!self.conversationViewController)
    {
        self.conversationConfiguration = [NCPreferencesController sharedInstance].producerConfigurationCopy;
        self.conversationViewController = [[NCConversationViewController alloc] init];
        self.conversationViewController.delegate = self;
    }
}

-(void)loadCurrentView:(NSView *)currentView
{
    [self.currentView removeFromSuperview];
    self.currentView = currentView;
    
    [self.view addSubview:self.currentView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[currentView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(currentView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[currentView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(currentView)]];
}

-(void)onSessionStatusUpdate:(NSNotification*)notification
{
    [self updateSessionStatus:[[notification.userInfo objectForKey:kSessionStatusKey] intValue]];
    self.conversationInfoView.status = [NCMainViewController fromSessionSatus:[[notification.userInfo objectForKey:kSessionStatusKey] intValue]];
    [self.conversationInfoView setNeedsDisplay:YES];
    [self.startPublishingButton setEnabled:([[notification.userInfo objectForKey:kSessionStatusKey] intValue] != SessionStatusOffline)];
}

-(void)onSessionError:(NSNotification*)notification
{
    [[NCErrorController sharedInstance]
     postErrorWithCode:[[notification.userInfo objectForKey:kSessionErrorCodeKey] intValue]
     andMessage:[notification.userInfo objectForKey:kSessionErrorMessageKey]];
    
    [self updateSessionStatus:[[notification.userInfo objectForKey:kSessionStatusKey] intValue]];
}

-(void)updateSessionStatus:(NCSessionStatus)status
{
    [self removeOnlinePublishingStatusIfPresent];
    
    switch (status) {
        case SessionStatusOnlineNotPublishing:
        {
            [self.statusPopUpButton selectItemAtIndex:STATUS_POPUP_PASSIVE_IDX];
        }
            break;
        case SessionStatusOnlinePublishing:
        {
            [self.statusPopUpButton addItemWithTitle:@""];
            NSMenuItem *activeItem = [self.statusPopUpButton.itemArray lastObject];
            activeItem.image = [[NCNdnRtcLibraryController sharedInstance] imageForSessionStatus:status];
            [self.statusPopUpButton selectItem:activeItem];
        }
            break;
        default:
        {
            [self.statusPopUpButton selectItemAtIndex:STATUS_POPUP_OFFLINE_IDX];
        }
            break;
    }
}

-(void)removeOnlinePublishingStatusIfPresent
{
    if (self.statusPopUpButton.itemArray.count == 3)
        [self.statusPopUpButton removeItemAtIndex:STATUS_POPUP_ONLINE_IDX];
}

+(NCConversationInfoStatus)fromSessionSatus:(NCSessionStatus)status
{
    switch (status) {
        case SessionStatusOnlineNotPublishing:
            return NCConversationInfoStatusOnlineNotPublishing;
        case SessionStatusOnlinePublishing:
            return NCConversationInfoStatusOnline;
        default:
            return NCConversationInfoStatusOffline;
    }
}

@end

@interface NCParticipantsValueTransformer : NSValueTransformer
@end

@implementation NCParticipantsValueTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}

-(id)transformedValue:(id)value
{
    if (!value || ![value isKindOfClass:[NSArray class]] || [value count] == 0)
        return @"no one";
    
    __block NSString *outputString = @"";
    NSArray *participants = [value valueForKeyPath:kSessionUsernameKey];
    
    if ([participants containsObject:[NCPreferencesController sharedInstance].userName])
        outputString = (participants.count == 1)?@"only me":@"me";
    
    [participants enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj isEqualToString:[NCPreferencesController sharedInstance].userName])
        {
            if (outputString.length > 0)
                outputString = [NSString stringWithFormat:@"%@,", outputString];
            
            outputString = [NSString stringWithFormat:@"%@ %@", outputString, obj];
        }
    }];
    
    return outputString;
}

@end

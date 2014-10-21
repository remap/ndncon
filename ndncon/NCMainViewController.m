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

// NCConversationViewControllerDelegate
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
    }
}

// NCUserListViewControllerDelegate
-(void)userListViewController:(NCUserListViewController *)userListViewController
                userWasChosen:(NSDictionary *)user
{
    NCSessionInfoContainer *sessionInfo = [user valueForKey:kNCSessionInfoKey];
    
    self.userViewController = [[NCUserViewController alloc] init];
    self.userViewController.userInfo = user;    
    self.userViewController.sessionInfo = sessionInfo;
    self.userViewController.delegate = self;
    
    [self loadCurrentView:self.userViewController.view];
}

-(void)userListViewControllerUserListUpdated:(NCUserListViewController *)userListViewController
{
    [(AppDelegate*)[NSApp delegate] commitManagedContext];
}

// NCConversationViewControllerDelegate
-(void)conversationViewControllerDidEndConversation:(NCConversationViewController *)converstaionVc
{
    self.conversationViewController = nil;
    [self loadCurrentView:self.initialView];
}

// NCUserViewControllerDelegate
-(void)userViewControllerFetchStreamsClicked:(NCUserViewController *)userVc
{
    [self.userListViewController clearSelection];
    [self startConverstaionIfNotStarted];
    [self loadCurrentView:self.conversationViewController.view];
    [self.conversationViewController startFetchingWithConfiguration:userVc.userInfo];
}

-(void)onAppWillTerminate:(NSNotification*)notification
{
    if (self.conversationViewController.participants.count > 0)
        [self.conversationViewController endConversation:nil];
    
    [[NCNdnRtcLibraryController sharedInstance] releaseLibrary];
}

// private
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
    [self updateSessionStatus:[[notification.userInfo objectForKey:kNCSessionStatusKey] intValue]];
    self.conversationInfoView.status = [NCMainViewController fromSessionSatus:[[notification.userInfo objectForKey:kNCSessionStatusKey] intValue]];
    [self.conversationInfoView setNeedsDisplay:YES];
    [self.startPublishingButton setEnabled:([[notification.userInfo objectForKey:kNCSessionStatusKey] intValue] != SessionStatusOffline)];
}

-(void)onSessionError:(NSNotification*)notification
{
    [[NCErrorController sharedInstance]
     postErrorWithCode:[[notification.userInfo objectForKey:kNCSessionErrorCodeKey] intValue]
     andMessage:[notification.userInfo objectForKey:kNCSessionErrorMessageKey]];
    
    [self updateSessionStatus:[[notification.userInfo objectForKey:kNCSessionStatusKey] intValue]];
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
    NSArray *participants = [value valueForKeyPath:kNCSessionUsernameKey];
    
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

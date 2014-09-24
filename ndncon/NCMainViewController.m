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
#import "NCUserViewController.h"

@interface NCMainViewController ()

@property (nonatomic, strong) NSDictionary *conversationConfiguration;

@property (nonatomic, strong) NCConversationViewController *converstaionViewController;
@property (weak) IBOutlet NSPopUpButton *statusPopUpButton;
@property (weak) IBOutlet NCConversationInfoView *conversationInfoView;
@property (weak) IBOutlet NSTextField *conversationInfoStatusLabel;
@property (nonatomic, strong) NCUserViewController *userViewController;

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
     NCSessionStatusUpdateNotification, @selector(onSessionStatusUpdate:),
     NCSessionErrorNotification, @selector(onSessionError:),
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
    if ([self.statusPopUpButton.itemArray indexOfObject:self.statusPopUpButton.selectedItem] == 0 &&
        [NCNdnRtcLibraryController sharedInstance].sessionStatus != SessionStatusOffline)
        [[NCNdnRtcLibraryController sharedInstance] stopSession];
    
    if ([self.statusPopUpButton.itemArray indexOfObject:self.statusPopUpButton.selectedItem] == 1 &&
        [NCNdnRtcLibraryController sharedInstance].sessionStatus != SessionStatusOnlineNotPublishing)
        [[NCNdnRtcLibraryController sharedInstance] startSession];
}

- (IBAction)startPublishing:(id)sender
{
    self.conversationConfiguration = [NCPreferencesController sharedInstance].producerConfigurationCopy;
    self.converstaionViewController = [[NCConversationViewController alloc] init];
    self.converstaionViewController.delegate = self;
    
    [self loadCurrentView:self.converstaionViewController.view];
    [self.converstaionViewController startPublishingWithConfiguration:self.conversationConfiguration];
}

- (IBAction)startPublishingCustom:(id)sender {
    NSLog(@"customize...");
}

// NCConversationViewControllerDelegate
-(void)converstaionInfoViewWasClicked:(NCConversationInfoView *)infoView
{
    if (self.converstaionViewController.currentConversationStatus == SessionStatusOffline ||
        (self.converstaionViewController.participants.count == 0 &&
         self.converstaionViewController.currentConversationStatus == SessionStatusOnlineNotPublishing))
    {
        [self loadCurrentView: self.initialView];
    }
    else
    {
        [self loadCurrentView:self.converstaionViewController.view];
    }
}

// NCUserListViewControllerDelegate
-(void)userListViewController:(NCUserListViewController *)userListViewController userWasChosen:(NSDictionary *)user
{
    NSString *userName = [user valueForKey:kNCSessionUsernameKey];
    NSString *hubPrefix = [user valueForKey:kNCHubPrefixKey];
    NCSessionInfoContainer *sessionInfo = [user valueForKey:kNCSessionInfoKey];
    
    NSLog(@"selected %@:%@", userName, hubPrefix);
    
    self.userViewController = [[NCUserViewController alloc] init];
    self.userViewController.sessionInfo = sessionInfo;
    self.userViewController.userInfo = user;
    
    [self loadCurrentView:self.userViewController.view];
}

// NCConversationViewControllerDelegate
-(void)conversationViewControllerDidEndConversation:(NCConversationViewController *)converstaionVc
{
    self.converstaionViewController = nil;
    [self loadCurrentView:self.initialView];
}

// private
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
    NSString *sessionPrefix = [notification.userInfo objectForKey:kNCSessionPrefixKey];
    NSString *sessionUserName = [notification.userInfo objectForKey:kNCSessionUsernameKey];
    
    if ([sessionPrefix isEqualToString:[NCNdnRtcLibraryController sharedInstance].sessionPrefix] &&
        [sessionUserName isEqualToString:[NCPreferencesController sharedInstance].userName])
    {
        NSLog(@"received session status update: %d",
              [[notification.userInfo objectForKey:kNCSessionStatusKey] intValue]);
        
        [self updateSessionStatus:[[notification.userInfo objectForKey:kNCSessionStatusKey] intValue]];
        
        self.conversationInfoView.status = [NCMainViewController fromSessionSatus:[[notification.userInfo objectForKey:kNCSessionStatusKey] intValue]];
        [self.conversationInfoView setNeedsDisplay:YES];
    }
}

-(void)onSessionError:(NSNotification*)notification
{
    NSString *sessionPrefix = [notification.userInfo objectForKey:kNCSessionPrefixKey];
    NSString *sessionUserName = [notification.userInfo objectForKey:kNCSessionUsernameKey];
    
    if ([sessionPrefix isEqualToString:[NCNdnRtcLibraryController sharedInstance].sessionPrefix] &&
        [sessionUserName isEqualToString:[NCPreferencesController sharedInstance].userName])
    {
        NSLog(@"received session error: %d %@",
              [[notification.userInfo objectForKey:kNCSessionErrorCodeKey] intValue],
              [notification.userInfo objectForKey:kNCSessionErrorMessageKey]);
        
        [self updateSessionStatus:[[notification.userInfo objectForKey:kNCSessionStatusKey] intValue]];
    }
}

-(void)updateSessionStatus:(NCSessionStatus)status
{
    switch (status) {
        case SessionStatusOnlineNotPublishing:
        {
            [self removeOnlinePublishingStatusIfPresent];
            [self.statusPopUpButton selectItemAtIndex:1];
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
            [self removeOnlinePublishingStatusIfPresent];
            [self.statusPopUpButton selectItemAtIndex:0];
        }
            break;
    }
}

-(void)removeOnlinePublishingStatusIfPresent
{
    if (self.statusPopUpButton.itemArray.count == 3)
        [self.statusPopUpButton removeItemAtIndex:2];
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
        outputString = (participants.count == 1)?@"only you":@"you";
    
    [participants enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj isEqualToString:[NCPreferencesController sharedInstance].userName])
            outputString = [NSString stringWithFormat:@"%@, %@", outputString, obj];
    }];
    
    return outputString;
}

@end

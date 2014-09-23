//
//  NCMainViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCMainViewController.h"
#import "NCConversationViewController.h"
#import "NCPreferencesController.h"
#import "NSObject+NCAdditions.h"
#import "NCNdnRtcLibraryController.h"

@interface NCMainViewController ()

@property (nonatomic, strong) NSDictionary *conversationConfiguration;
@property (nonatomic, strong) NCConversationViewController *converstaionViewController;
@property (weak) IBOutlet NSPopUpButton *statusPopUpButton;

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

- (IBAction)startPublishing:(id)sender {
    self.conversationConfiguration = [NCPreferencesController sharedInstance].producerConfigurationCopy;
    self.converstaionViewController = [[NCConversationViewController alloc] init];
    
    [self loadCurrentView:self.converstaionViewController.view];
    [self.converstaionViewController startPublishingWithConfiguration:self.conversationConfiguration];
}

- (IBAction)startPublishingCustom:(id)sender {
    NSLog(@"customize...");
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

// private
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
            activeItem.image = [NSImage imageNamed:@"session_active"];
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

@end

//
//  NCUserViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCUserViewController.h"
#import "NCStreamEditorViewController.h"
#import "NCPreferencesController.h"
#import "NSScrollView+NCAdditions.h"
#import "NCUserStreamViewController.h"
#import "NSObject+NCAdditions.h"
#import "NCNdnRtcLibraryController.h"
#import "NCStreamViewerController.h"
#import "NCChatViewController.h"
#import "NCChatLibraryController.h"

@interface NCUserViewController ()

@property (weak) IBOutlet NSScrollView *scrollView;
@property (nonatomic) NCStreamViewerController *streamEditorController;
@property (weak) IBOutlet NSButton *fetchAllButton;
@property (nonatomic) NCChatViewController *chatViewController;
@property (nonatomic) BOOL isChatVisible;

@property (weak) IBOutlet NSButton *chatButton;
@property (weak) IBOutlet NSButton *publishingInfoButton;

@end

@implementation NCUserViewController

-(id)init
{
    self = [super initWithNibName:@"NCUserView" bundle:nil];
    
    if (self)
    {
        self.streamEditorController = [[NCStreamViewerController alloc] init];
        self.chatViewController = [[NCChatViewController alloc] init];
        self.statusImage = [[NCNdnRtcLibraryController sharedInstance]
                            imageForSessionStatus:SessionStatusOffline];

        [self subscribeForNotificationsAndSelectors:
         NCRemoteSessionStatusUpdateNotification, @selector(onSessionStatusUpdate:),
         nil];
    }
    
    return self;
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
}

-(void)awakeFromNib
{
    [self.scrollView addStackView:self.streamEditorController.stackView
                  withOrientation:NSUserInterfaceLayoutOrientationVertical];
    [self.streamEditorController awakeFromNib];

    NCSessionStatus status = [[self.userInfo valueForKey:kNCSessionStatusKey] integerValue];
    [self.fetchAllButton setEnabled:(status == SessionStatusOnlinePublishing)];
    self.isChatVisible = YES;
    
    self.chatViewController.chatRoomId = [[NCChatLibraryController sharedInstance] startChatWithUser: [self.userInfo valueForKey:kNCSessionUsernameKey]];
}

-(void)setUserInfo:(NSDictionary *)userInfo
{
    _userInfo = userInfo;
    self.streamEditorController.userName = [userInfo valueForKey:kNCSessionUsernameKey];
    self.streamEditorController.userPrefix = [userInfo valueForKey:kNCHubPrefixKey];
    
    NCSessionStatus status = [[_userInfo valueForKey:kNCSessionStatusKey] integerValue];
    
    self.statusImage = [[NCNdnRtcLibraryController sharedInstance]
                        imageForSessionStatus:status];
    [self.fetchAllButton setEnabled:(status == SessionStatusOnlinePublishing)];
}

-(void)setSessionInfo:(NCSessionInfoContainer *)sessionInfo
{
    if (![_sessionInfo isEqual:sessionInfo] &&
        !(sessionInfo == _sessionInfo))
    {
        _sessionInfo = sessionInfo;
        [self updateStreams];
    }
}

- (IBAction)fetchAll:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(userViewControllerFetchStreamsClicked:)])
        [self.delegate userViewControllerFetchStreamsClicked:self];
}

- (IBAction)showChat:(id)sender {
    self.publishingInfoButton.state = !self.chatButton.state;
    self.isChatVisible = !self.isChatVisible;
}

- (IBAction)showPublishingInfo:(id)sender
{
    self.chatButton.state = !self.publishingInfoButton.state;
    self.isChatVisible = !self.isChatVisible;
}

// private
-(void)setIsChatVisible:(BOOL)isChatVisible
{
    if (_isChatVisible != isChatVisible)
    {
        _isChatVisible = isChatVisible;
        if (_isChatVisible)
        {
            [self.scrollView removeFromSuperview];
            [self presentView: self.chatViewController.view];
        }
        else
        {
            [self.chatViewController.view removeFromSuperview];
            [self presentView: self.scrollView];
        }
    }
}

-(void)presentView:(NSView*)view
{
    [self.view addSubview:view];
    
    NSButton *button = self.chatButton;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(view)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(view)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[button]-4-[view]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(button, view)]];
}

-(void)updateStreams
{
    [self.streamEditorController setAudioStreams:[NSMutableArray arrayWithArray: [self.sessionInfo audioStreamsConfigurations]]
                                 andVideoStreams:[NSMutableArray arrayWithArray:[self.sessionInfo videoStreamsConfigurations]]];
}

-(void)onSessionStatusUpdate:(NSNotification*)notification
{
    if ([[self.userInfo objectForKey:kNCSessionPrefixKey]
         isEqualTo:[notification.userInfo objectForKey:kNCSessionPrefixKey]])
    {
        self.userInfo = notification.userInfo;
        self.sessionInfo = [self.userInfo valueForKey:kNCSessionInfoKey];
    }
}

@end

@interface NCSessionStatusTransformer : NSValueTransformer
@end

@implementation NCSessionStatusTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

-(id)transformedValue:(id)value
{
    NCSessionStatus status = [value intValue];
    
    switch (status) {
        case SessionStatusOnlineNotPublishing:
            return @"online, not publishing";
        case SessionStatusOnlinePublishing:
            return @"publishing";
        default:
            return @"offline";
    }
}

@end

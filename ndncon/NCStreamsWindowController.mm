//
//  NCStreamsWindowController.m
//  NdnCon
//
//  Created by Peter Gusev on 7/9/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import <IOKit/pwr_mgt/IOPMLib.h>

#include <ndnrtc/ndnrtc-library.h>
#include <ndnrtc/params.h>

#import "NCStreamsWindowController.h"
#import "NSObject+NCAdditions.h"
#import "NCStreamingController.h"
#import "NCStreamBrowserController.h"
#import "NSScrollView+NCAdditions.h"
#import "NCNdnRtcLibraryController.h"
#import "AVCaptureDeviceFormat+NdnConAdditions.h"
#import "NSDictionary+NCNdnRtcAdditions.h"
#import "NSDictionary+NCAdditions.h"
#import "NSArray+NCAdditions.h"
#import "NSString+NCAdditions.h"
#import "NSObject+NCAdditions.h"
#import "NCErrorController.h"
#import "NCVideoStreamViewController.h"
#import "NCVideoPreviewController.h"
#import "NCPreferencesController.h"
#import "NCCameraCapturer.h"
#import "NCDiscoveryLibraryController.h"
#import "NCReporter.h"
#import "NCChatLibraryController.h"
#import "NCScreenCapturer.h"

using namespace ndnrtc;
using namespace ndnrtc::new_api;

//******************************************************************************
@interface NCStreamsWindowController ()

@property (nonatomic) IOPMAssertionID iopmAssertionId;

@property (weak) IBOutlet NSScrollView *localStreamsScrollView;
@property (weak) IBOutlet NSScrollView *remoteStreamsScrollView;
@property (weak) IBOutlet NSView *activeStreamViewerContainer;
@property (weak) IBOutlet NSView *noPublishingView;
@property (weak) IBOutlet NSView *noFetchingView;

@property (nonatomic, strong) NCUserStreamsController *localStreamViewer;
@property (nonatomic, strong) NCUserStreamsController *remoteStreamViewer;

@property (nonatomic, weak) NCVideoPreviewController *activeVideoPreviewController;
@property (nonatomic, strong) NCActiveStreamViewer *activeStreamViewer;
@property (nonatomic, strong) NCChatViewController *chatViewController;

@property (weak) IBOutlet NSView *chatContentView;
@property (nonatomic) NSArray *chatrooms;
@property (nonatomic) NCChatRoom *activeChatroom;
@property (nonatomic) NCChatRoom *publishedChatroom;
@property (nonatomic) BOOL isPublishingChatroom;
@property (nonatomic) NSString *publishedChatroomName;

@property (weak) IBOutlet NSButton *createChatroomButton;
@property (weak) IBOutlet NSPopUpButton *chatroomPopup;

@end

@implementation NCStreamsWindowController

-(instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

-(void)initialize
{
    self.localStreamViewer = [[NCUserStreamsController alloc] init];
    self.localStreamViewer.delegate = self;
    self.remoteStreamViewer = [[NCUserStreamsController alloc] init];
    self.remoteStreamViewer.delegate = self;
    self.activeStreamViewer = [[NCActiveStreamViewer alloc] init];
    self.activeStreamViewer.delegate = self;
    self.chatViewController = [[NCChatViewController alloc] init];
    self.chatViewController.delegate = self;
    
    [self subscribeForNotificationsAndSelectors:
     kNCFetchedStreamsAddedNotification, @selector(onFetchedStreamsAdded:),
     kNCFetchedStreamsRemovedNotification, @selector(onFetchedStreamsRemoved:),
     kNCFetchedUserAddedNotification, @selector(onFetchedUserAdded:),
     kNCFetchedUserRemovedNotification, @selector(onFetchedUserRemoved:),
     kNCPublishedStreamsAddedNotification, @selector(onPubslihedStreamsAdded:),
     kNCPublishedStreamsRemovedNotification, @selector(onPublishedStreamsRemoved:),
     NCChatroomDiscoveredNotification, @selector(onChatroomAppeared:),
     NCChatroomWithdrawedNotification, @selector(onChatroomWithdrawned:),
     NCChatroomUpdatedNotificaiton, @selector(onChatroomUpdated:),
     NCChatMessageNotification, @selector(onChatMessage:),
     nil];
}

-(void)awakeFromNib
{
    [self.localStreamsScrollView addStackView:self.localStreamViewer.stackView
                              withOrientation:NSUserInterfaceLayoutOrientationHorizontal];
    [self.remoteStreamsScrollView addStackView:self.remoteStreamViewer.stackView
                               withOrientation:NSUserInterfaceLayoutOrientationHorizontal];
    [self subscribeForNotificationsAndSelectors:
     kNCStreamPreviewSelectedNotification, @selector(onRemotePreviewSelected:),
     nil];
    
    [self.activeStreamViewerContainer addSubview:self.activeStreamViewer.view];
    self.activeStreamViewer.view.frame = self.activeStreamViewerContainer.bounds;
    NSView *activeStreamView = self.activeStreamViewer.view;
    
    [self.activeStreamViewerContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[activeStreamView]|"
                                                                                         options:0
                                                                                         metrics:nil
                                                                                           views:NSDictionaryOfVariableBindings(activeStreamView)]];
    [self.activeStreamViewerContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[activeStreamView]|"
                                                                                         options:0
                                                                                         metrics:nil
                                                                                           views:NSDictionaryOfVariableBindings(activeStreamView)]];
    [self setNoPublishingViewVisible:YES];
    [self setNoFetchingViewVisible:YES];
    
    [self.chatContentView addSubview:self.chatViewController.view];
    self.chatViewController.view.frame = self.chatContentView.bounds;
    
    NSView *chatView = self.chatViewController.view;
    [self.chatContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[chatView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(chatView)]];
    [self.chatContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[chatView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(chatView)]];
    self.chatViewController.isActive = NO;
    [self.chatroomPopup selectItemAtIndex:0];
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
    self.localStreamViewer = nil;
    self.remoteStreamViewer = nil;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

#pragma mark - NCUserStreamsControllerDelegate
-(void)userStreamsController:(NCUserStreamsController *)userStreamsController
              didDropStreams:(NSArray *)streamConfigurations
                     forUser:(NSString *)username
                  withPrefix:(NSString *)prefix
{
    if (userStreamsController == self.localStreamViewer)
    {
        [[NCStreamingController sharedInstance]
         stopPublishingStreams:streamConfigurations];
    }
    else
    {
        [[NCStreamingController sharedInstance]
         stopFetchingStreams:streamConfigurations
         fromUser:username
         withPrefix:prefix];
    }
}

-(void)userStreamsController:(NCUserStreamsController *)userStreamsController
         didDropUserWithName:(NSString *)username
                   andPrefix:(NSString *)prefix
                 withStreams:(NSArray *)streamConfigurations
{
    if (self.localStreamViewer == userStreamsController)
        [[NCStreamingController sharedInstance] stopPublishingStreams:streamConfigurations];
    else
        [[NCStreamingController sharedInstance] stopFetchingStreams:streamConfigurations
                                                           fromUser:username
                                                         withPrefix:prefix];
}

-(void)userStreamsController:(NCUserStreamsController *)userStreamsController
      needMoreStreamsIsAudio:(BOOL)isAudioRequired
                     forUser:(NSString *)username
                  withPrefix:(NSString *)prefix
{
    if (userStreamsController == self.localStreamViewer)
    {
        if (isAudioRequired)
            [[NCStreamingController sharedInstance] publishStreams:[NCPreferencesController sharedInstance].audioStreams];
        else
            [[NCStreamingController sharedInstance] publishStreams:[NCPreferencesController sharedInstance].videoStreams];
    }
    else
    {
        NCActiveUserInfo *userInfo = [[NCUserDiscoveryController sharedInstance] userWithName:username andHubPrefix:prefix];

        if (userInfo){
            if (isAudioRequired)
                [[NCStreamingController sharedInstance] fetchStreams:[userInfo getDefaultFetchAudioThreads]
                                                            fromUser:userInfo.username
                                                          withPrefix:userInfo.hubPrefix];
            else
                [[NCStreamingController sharedInstance] fetchStreams:[userInfo getDefaultFetchVideoThreads]
                                                            fromUser:userInfo.username
                                                          withPrefix:userInfo.hubPrefix];
        }
    }
}

-(NSArray *)chatrooms
{
    NSMutableArray *chatrooms = [NSMutableArray array];
    
    if (self.isPublishingChatroom)
    {
        [chatrooms addObject: self.publishedChatroom];
    }
    
    [chatrooms addObjectsFromArray:[NCChatroomDiscoveryController sharedInstance].discoveredChatrooms];
    
    return [NSArray arrayWithArray:chatrooms];
}

-(void)setIsPublishingChatroom:(BOOL)isPublishingChatroom
{
    _isPublishingChatroom = isPublishingChatroom;
    
    if (_isPublishingChatroom)
        [self.createChatroomButton setTitle:@"Close chatroom"];
    else
        [self.createChatroomButton setTitle:@"Create chatroom"];
}

- (IBAction)selectChatroom:(NSPopUpButton*)sender
{
    NSInteger selectedIndex = sender.indexOfSelectedItem;
    NCChatRoom *chatroom = (selectedIndex == 0)? nil : [self.chatrooms objectAtIndex:(selectedIndex-1)];
    
    if (self.isPublishingChatroom &&
        ![chatroom.chatroomName isEqualToString:self.publishedChatroom.chatroomName])
    {
        self.isPublishingChatroom = NO;
        [[NCChatroomDiscoveryController sharedInstance] withdrawChatroom:self.publishedChatroom];
    }
    
    if (self.activeChatroom)
        [[NCChatLibraryController sharedInstance] leaveChat:self.activeChatroom.chatroomName];
    
    if (chatroom)
    {
        [[NCChatLibraryController sharedInstance] joinChatroom:chatroom];
        self.chatViewController.chatRoomId = chatroom.chatroomName;
    }
    else
        self.chatViewController.chatRoomId = nil;
    
    self.activeChatroom = chatroom;
    self.chatViewController.isActive = (chatroom != nil);
}

- (IBAction)chatroomNameEntered:(NSTextField*)sender {
    if (sender.stringValue && ![sender.stringValue isEqualToString:@""])
    {
        self.isPublishingChatroom = YES;
        [self createChatroom:nil];
    }
}

- (IBAction)createChatroom:(id)sender
{
    if (self.isPublishingChatroom)
    {
        NCChatRoom *chatroom = [NCChatRoom chatRoomWithName:self.publishedChatroomName
                                            andParticipants:@[[NCNdnRtcLibraryController sharedInstance].sessionPrefix]];
        [[NCChatroomDiscoveryController sharedInstance] announceChatroom:chatroom];
        [self willChangeValueForKey:@"chatrooms"];
        self.publishedChatroom = chatroom;
        [self didChangeValueForKey:@"chatrooms"];
        
        [self.chatroomPopup selectItemAtIndex:1];
        [self selectChatroom:self.chatroomPopup];
    }
    else
    {
        if (self.publishedChatroomName &&
            ![self.publishedChatroomName isEqualToString:@""])
        {
            [self willChangeValueForKey:@"chatrooms"];
            [[NCChatroomDiscoveryController sharedInstance] withdrawChatroom:self.publishedChatroom];
            self.publishedChatroom = nil;
            [self didChangeValueForKey:@"chatrooms"];
            [self.chatroomPopup selectItemAtIndex:0];
            [self selectChatroom:self.chatroomPopup];
        }
    }
}

#pragma mark - NCActiveStreamViewer
-(void)activeStreamViewer:(NCActiveStreamViewer *)activeStreamViewer didSelectThreadWithConfiguration:(NSDictionary *)threadConfiguration
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    lib->switchThread([activeStreamViewer.streamPrefix cStringUsingEncoding:NSASCIIStringEncoding],
                      [[threadConfiguration valueForKey:kNameKey] cStringUsingEncoding:NSASCIIStringEncoding]);
}

#pragma mark - NSSplitView
-(BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    if ([[splitView subviews] indexOfObject:subview] == 0)
        return YES;
    
    return NO;
}

#pragma mark - notificaitons
-(void)onFetchedUserAdded:(NSNotification*)notification
{
    if (!self.window.visible)
        [self showWindow:nil];
}

-(void)onFetchedUserRemoved:(NSNotification*)notification
{
    NCFetchedUser *fetchedUser = notification.object;
    NSArray *streamConfigurations = notification.userInfo[kNCStreamConfigurationsKey];
    
    for (NSDictionary *configuration in streamConfigurations)
    {
        [self.remoteStreamViewer removeStream:configuration
                                      forUser:fetchedUser.username
                                   withPrefix:fetchedUser.prefix];
        [self removeRemoteStreamWithConfiguration:configuration
                                          forUser:fetchedUser.username
                                       withPrefix:fetchedUser.prefix];
    }
    
    if ([[NCStreamingController sharedInstance] allFetchedStreams].count == 0)
    {
        self.activeVideoPreviewController = nil;
        [self.activeStreamViewer clear];
        [self setNoFetchingViewVisible:YES];
    }
}

-(void)onFetchedStreamsAdded:(NSNotification*)notification
{
    if (!self.window.visible)
        [self showWindow:nil];
    
    NCFetchedUser *user = notification.object;
    NSArray *streams = notification.userInfo[kNCStreamConfigurationsKey];
    
    for (NSDictionary *streamConf in streams)
    {
        [self addRemoteStreamWithConfiguration:streamConf
                                       forUser:user.username
                                    withPrefix:user.hubPrefix];
    }
    
    [self setNoFetchingViewVisible:NO];
}

-(void)onFetchedStreamsRemoved:(NSNotification*)notification
{
    NCFetchedUser *fetchedUser = notification.object;
    NSArray *streamConfigurations = notification.userInfo[kNCStreamConfigurationsKey];
    
    for (NSDictionary *configuration in streamConfigurations)
    {
        [self.remoteStreamViewer removeStream:configuration
                                      forUser:fetchedUser.username
                                   withPrefix:fetchedUser.prefix];
        [self removeRemoteStreamWithConfiguration:configuration
                                          forUser:fetchedUser.username
                                       withPrefix:fetchedUser.prefix];
        
        if ([self.activeStreamViewer.userInfo.username isEqualToString:fetchedUser.username] &&
            [self.activeStreamViewer.userInfo.hubPrefix isEqualToString:fetchedUser.hubPrefix] &&
            [self.activeStreamViewer.activeStreamConfiguration[kNameKey] isEqualToString:configuration[kNameKey]])
        {
            self.activeVideoPreviewController = nil;
            [self.activeStreamViewer clear];
        }
    }
    
    if ([[NCStreamingController sharedInstance] allFetchedStreams].count == 0)
        [self setNoFetchingViewVisible:YES];
}

-(void)onPubslihedStreamsAdded:(NSNotification*)notification
{
    if (!self.window.visible)
        [self showWindow:nil];
    
    NSArray *streams = notification.userInfo[kNCStreamConfigurationsKey];
    
    for (NSDictionary *streamConf in streams)
    {
        if ([streamConf isVideoStream])
            [self startVideoStreamWithConfiguration:streamConf];
        else
            [self startAudioStreamWithConfiguration:streamConf];
    }
    
    [self setNoPublishingViewVisible:NO];
}

-(void)onPublishedStreamsRemoved:(NSNotification*)notification
{
    for (NSDictionary *streamConf in notification.userInfo[kNCStreamConfigurationsKey])
    {
        [self.localStreamViewer removeStream:streamConf
                                     forUser:[NCPreferencesController sharedInstance].userName
                                  withPrefix:[NCPreferencesController sharedInstance].prefix];
        
        NSString *streamPrefix = [NSString streamPrefixForStream:streamConf[kNameKey]
                                                            user:[NCPreferencesController sharedInstance].userName
                                                      withPrefix:[NCPreferencesController sharedInstance].prefix];
        
        NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
        lib->removeLocalStream([[NCNdnRtcLibraryController sharedInstance].sessionPrefix cStringUsingEncoding:NSASCIIStringEncoding],
                               [streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    }
    
    if ([[NCStreamingController sharedInstance] allPublishedStreams].count == 0)
        [self setNoPublishingViewVisible:YES];
}

-(void)onRemotePreviewSelected:(NSNotification*)notification
{
    NCUserPreviewController *userPreviewController = notification.object;
    NCVideoPreviewController *previewController = notification.userInfo[kNCStreamPreviewControllerKey];
    
    if (previewController != self.activeVideoPreviewController)
    {
        NCActiveUserInfo *userInfo = [[NCUserDiscoveryController sharedInstance] userWithName:userPreviewController.username
                                                                                 andHubPrefix:userPreviewController.prefix];
        
        if (userInfo)
            [self switchActiveToUser:userInfo withPreviewController:previewController];
    }
}

-(void)onChatroomAppeared:(NSNotification*)notification
{
    [self willChangeValueForKey:@"chatrooms"];
    [self didChangeValueForKey:@"chatrooms"];
}

-(void)onChatroomWithdrawned:(NSNotification*)notification
{
    [self willChangeValueForKey:@"chatrooms"];
    [self didChangeValueForKey:@"chatrooms"];
    
    if ([self.chatViewController.chatRoomId isEqualToString: notification.userInfo[kChatroomKey]])
    {
        if (self.isPublishingChatroom)
            self.chatViewController.chatRoomId = nil;
        
        [[NCChatLibraryController sharedInstance] leaveChat:self.activeChatroom.chatroomName];
        self.chatViewController.isActive = NO;
        self.activeChatroom = nil;
    }
}

-(void)onChatroomUpdated:(NSNotification*)notification
{
    [self willChangeValueForKey:@"chatrooms"];
    [self didChangeValueForKey:@"chatrooms"];
}

-(void)onChatMessage:(NSNotification*)notification
{
    NSString *chatRoomId = notification.userInfo[NCChatRoomIdKey];
    User *user = notification.userInfo[NCChatMessageUserKey];
    
    if ([chatRoomId isEqualTo:self.chatViewController.chatRoomId])
    {
        [self.chatViewController newChatMessage:notification];
    }
}

#pragma mark - private
-(void)setNoPublishingViewVisible:(BOOL)isVisible
{
    if (isVisible)
    {
        [self.localStreamViewer.stackView addView:self.noPublishingView
                                        inGravity:NSStackViewGravityCenter];
    }
    else
    {
        [self.localStreamViewer.stackView removeView:self.noPublishingView];
    }
}

-(void)setNoFetchingViewVisible:(BOOL)isVisible
{
    if (isVisible)
    {
        [self.remoteStreamViewer.stackView addView:self.noFetchingView
                                         inGravity:NSStackViewGravityCenter];
    }
    else
    {
        [self.remoteStreamViewer.stackView removeView:self.noFetchingView];
    }
}

-(void)stopComputerSleep
{
    IOPMAssertionID assertionID;
    CFStringRef activityReason = CFSTR("Video Conference");
    IOReturn result = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep,
                                                  kIOPMAssertionLevelOn,
                                                  activityReason,
                                                  &assertionID);
    if (result == kIOReturnSuccess)
        self.iopmAssertionId = assertionID;
}

-(void)resumeComputerSleep
{
    IOPMAssertionRelease(self.iopmAssertionId);
}

-(void)switchActiveToUser:(NCActiveUserInfo*)userInfo
    withPreviewController:(NCVideoPreviewController*)previewController
{
    NCVideoStreamRenderer *activeRenderer = previewController.renderer;
    NCVideoStreamRenderer *previousRenderer = self.activeStreamViewer.renderer;
    
    [previewController setPreviewForVideoRenderer:nil];
    self.activeStreamViewer.renderer = activeRenderer;
    [self.activeVideoPreviewController setPreviewForVideoRenderer:previousRenderer];
    ((NCVideoPreviewView*)self.activeVideoPreviewController.streamPreview).isSelected = NO;
    self.activeVideoPreviewController = previewController;
    ((NCVideoPreviewView*)previewController.streamPreview).isSelected = YES;
    
    [self.activeStreamViewer setActiveStream:previewController.streamConfiguration
                                        user:userInfo.username
                                   andPrefix:userInfo.hubPrefix];
}

#pragma mark - NDN-RTC
-(void)startAudioStreamWithConfiguration:(NSDictionary*)streamConfiguration
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    std::string sessionPrefix([[NCNdnRtcLibraryController sharedInstance].sessionPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    IExternalCapturer *nilCapturer = NULL;
    std::string streamPrefix = lib->addLocalStream(sessionPrefix,
                                                   [streamConfiguration asAudioStreamParams],
                                                   &nilCapturer);
    
    if (streamPrefix != "")
    {
        [self.localStreamViewer addStream:streamConfiguration
                                  forUser:[NCPreferencesController sharedInstance].userName
                               withPrefix:[NCPreferencesController sharedInstance].prefix];
    }
    else
        [[NCErrorController sharedInstance] postErrorWithMessage:@"Couldn't start audio stream"];
}

-(void)startVideoStreamWithConfiguration:(NSDictionary*)streamConfiguration
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    std::string sessionPrefix([[NCNdnRtcLibraryController sharedInstance].sessionPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    IExternalCapturer *externalCapturer;
    NSInteger deviceIdx = [[streamConfiguration valueForKey:kInputDeviceKey] intValue];
    NCBaseCapturer *capturer = nil;
    BOOL shouldStartStream = NO;
    
    if (deviceIdx >= 0)
    {
        AVCaptureDevice *device = [[NCPreferencesController sharedInstance].videoDevices
                                   objectAtIndexOrNil:deviceIdx];
        AVCaptureDeviceFormat *format = [device.formats
                                         objectAtSignedIndexOrNil:[[streamConfiguration valueForKey:kDeviceConfigurationKey] intValue]];
        
        if (!format)
        {
            format = [device.formats lastObject];
            NSLog(@"device %@ doesn't have configuration with index %@, falling back to last configuration in the list %@",
                  device.localizedName, [streamConfiguration valueForKey:kDeviceConfigurationKey], [format localizedName]);
        }
        
        if (device)
        {
            capturer = [[NCCameraCapturer alloc]
                        initWithDevice: device
                        andFormat:format];
            shouldStartStream = YES;
        }
        else
            NSLog(@"device with index %@ was not found", [streamConfiguration valueForKey:kInputDeviceKey]);
    }
    else // screen sharing
    {
        capturer = [[NCScreenCapturer alloc] initWithDisplayId:(CGDirectDisplayID)(-deviceIdx)];
        shouldStartStream = YES;
    }
    
    if (shouldStartStream)
    {
        std::string streamPrefix = lib->addLocalStream(sessionPrefix,
                                                       [streamConfiguration asVideoStreamParams],
                                                       &externalCapturer);
        
        if (streamPrefix != "")
        {
            NCVideoPreviewController *videoPreviewVc = [self.localStreamViewer addStream:streamConfiguration
                                                                                 forUser:[NCPreferencesController sharedInstance].userName
                                                                              withPrefix:[NCPreferencesController sharedInstance].prefix];
            [videoPreviewVc setPreviewForCapturer:capturer];
            [capturer setNdnRtcExternalCapturer:externalCapturer];
            [capturer startCapturing];
        }
        else
            [[NCErrorController sharedInstance] postErrorWithMessage:@"Couldn't start video stream"];
    }
}

-(void)addRemoteStreamWithConfiguration:(NSDictionary*)streamConfiguration
                                forUser:(NSString*)username
                             withPrefix:(NSString*)prefix
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    std::string sessionPrefix([[NSString userSessionPrefixForUser:username
                                                   withHubPrefix:prefix] cStringUsingEncoding:NSASCIIStringEncoding]);
    GeneralConsumerParams consumerParams;
    [[NCPreferencesController sharedInstance] getNdnRtcGeneralConsumerParameters:&consumerParams];
    GeneralParams generalParams;
    [[NCPreferencesController sharedInstance] getNdnRtcGeneralParameters:&generalParams];
    BOOL isVideoStream = [streamConfiguration isVideoStream];
    NSDictionary *streamConfigurationFull = [[[NCUserDiscoveryController sharedInstance] userWithName:username andHubPrefix:prefix].streamConfigurations streamWithName:streamConfiguration[kNameKey]];
    std::string threadToFetch = [streamConfiguration[kThreadsArrayKey][0][kNameKey] cStringUsingEncoding:NSASCIIStringEncoding];
    MediaStreamParams streamParams = isVideoStream ? [streamConfigurationFull asVideoStreamParams] : [streamConfigurationFull asAudioStreamParams];
    NCVideoStreamRenderer *renderer = isVideoStream ? [[NCVideoStreamRenderer alloc] init] : nil;
    std::string streamPrefix = lib->addRemoteStream(sessionPrefix,
                                                    threadToFetch,
                                                    streamParams,
                                                    generalParams,
                                                    consumerParams,
                                                    (isVideoStream?(IExternalRenderer*)renderer.ndnRtcRenderer:NULL));
    if (streamPrefix != "")
    {
        if (isVideoStream)
        {
            NCVideoPreviewController *videoPreviewVc = [self.remoteStreamViewer addStream:streamConfiguration
                                                                                  forUser:username
                                                                               withPrefix:prefix];
            [videoPreviewVc setPreviewForVideoRenderer:renderer];
            
            if (!self.activeVideoPreviewController)
            {
                NCActiveUserInfo *userInfo = [[NCUserDiscoveryController sharedInstance] userWithName:username
                                                                                         andHubPrefix:prefix];
                if (userInfo)
                    [self switchActiveToUser:userInfo withPreviewController:videoPreviewVc];
            }
            
        }
        else
        {
            [self.remoteStreamViewer addStream:streamConfiguration
                                       forUser:username
                                    withPrefix:prefix];
        }
    }
    else
        [[NCErrorController sharedInstance] postErrorWithMessage:@"Couldn't add media stream"];

}

-(void)removeRemoteStreamWithConfiguration:(NSDictionary*)streamConfiguration
                                   forUser:(NSString*)username
                                withPrefix:(NSString*)prefix
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    NSString *streamPrefix = [NSString streamPrefixForStream:streamConfiguration[kNameKey]
                                                        user:username
                                                  withPrefix:prefix];
    ndnrtc::new_api::statistics::StatisticsStorage stat = lib->getRemoteStreamStatistics([streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    std::string logFile = lib->removeRemoteStream([streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    
    [[NCReporter sharedInstance] addStatReport:[NSString stringWithCString:logFile.c_str() encoding:NSUTF8StringEncoding]];
}

@end

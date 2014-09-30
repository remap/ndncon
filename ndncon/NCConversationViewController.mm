//
//  NCConversationViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndnrtc/ndnrtc-library.h>
#include <ndnrtc/params.h>

#import "NCConversationViewController.h"
#import "NSScrollView+NCAdditions.h"
#import "NCStreamPreviewController.h"
#import "NCPreferencesController.h"
#import "NCStreamViewController.h"
#import "NCVideoStreamViewController.h"
#import "NCAudioPreviewController.h"
#import "NCVideoPreviewController.h"
#import "NCVideoThreadViewController.h"
#import "NCAudioThreadViewController.h"
#import "NCCameraCapturer.h"
#import "NSArray+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"
#import "AVCaptureDeviceFormat+NdnConAdditions.h"
#import "NSDictionary+NCNdnRtcAdditions.h"
#import "NSObject+NCAdditions.h"
#import "NCUserListViewController.h"
#import "NCVideoStreamRenderer.h"
#import "NCActiveStreamViewer.h"

using namespace ndnrtc;
using namespace ndnrtc::new_api;

NSString* const kCameraCapturerKey = @"cameraCapturer";
NSString* const kRendererKey = @"videoRenderer";
NSString* const kNCLocalStreamsDictionaryKey = @"localStreamsDictionary";
NSString* const kNCRemoteStreamsDictionaryKey = @"remoteStreamsDictionary";

@interface NCConversationViewController ()

@property (nonatomic) NSMutableDictionary *localStreams;

@property (weak) IBOutlet NSScrollView *localStreamsScrollView;
@property (weak) IBOutlet NSScrollView *remoteStreamsScrollView;
@property (weak) IBOutlet NSView *activeStreamContentView;
@property (strong) IBOutlet NSView *startPublishingView;

@property (nonatomic, strong) NCStreamBrowserController *localStreamViewer;
@property (nonatomic, strong) NCStreamBrowserController *remoteStreamViewer;

@property (nonatomic, strong) NCActiveStreamViewer *activeStreamViewer;
@property (nonatomic, weak) NCStreamPreviewController *currentlySelectedPreview;

@end

@implementation NCConversationViewController

-(id)init
{
    self = [self initWithNibName:@"NCConversationView" bundle:nil];
    
    if (self)
        [self initialize];
    
    return self;
}

-(void)initialize
{
    self.participants = [[NSMutableArray alloc] init];
    self.localStreams = [NSMutableDictionary dictionary];
    
    self.localStreamViewer = [[NCStreamBrowserController alloc] init];
    self.localStreamViewer.delegate = self;
    
    self.remoteStreamViewer = [[NCStreamBrowserController alloc] init];
    self.remoteStreamViewer.delegate = self;
    
    self.activeStreamViewer = [[NCActiveStreamViewer alloc] init];
    
    [self subscribeForNotificationsAndSelectors:
     NCSessionStatusUpdateNotification, @selector(onSessionStatusUpdate:),
     NSApplicationWillTerminateNotification, @selector(onAppWillTerminate:),
     nil];
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
    
    self.localStreamViewer = nil;
    self.remoteStreamViewer = nil;
}

-(void)awakeFromNib
{
    [self.remoteStreamsScrollView addStackView:self.remoteStreamViewer.stackView
                               withOrientation:NSUserInterfaceLayoutOrientationVertical];
    
    if (self.currentConversationStatus != SessionStatusOnlinePublishing)
        [self.localStreamsScrollView setDocumentView:self.startPublishingView];
    else
        [self.localStreamsScrollView addStackView:self.localStreamViewer.stackView
                                  withOrientation:NSUserInterfaceLayoutOrientationHorizontal];
    
    [self.activeStreamContentView addSubview:self.activeStreamViewer.view];
    NSView *activeStreamView = self.activeStreamViewer.view;
    
    [self.activeStreamContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[activeStreamView]|"
                                                                                         options:0
                                                                                         metrics:nil
                                                                                           views:NSDictionaryOfVariableBindings(activeStreamView)]];
    [self.activeStreamContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[activeStreamView]|"
                                                                                         options:0
                                                                                         metrics:nil
                                                                                           views:NSDictionaryOfVariableBindings(activeStreamView)]];
}

- (IBAction)startPublishing:(id)sender
{
    [self.localStreamsScrollView addStackView:self.localStreamViewer.stackView
                              withOrientation:NSUserInterfaceLayoutOrientationHorizontal];
    [self startPublishingWithConfiguration:[NCPreferencesController sharedInstance].producerConfigurationCopy];
}

- (IBAction)endConversation:(id)sender
{
    [self.localStreamViewer closeAllStreams];
    [self.remoteStreamViewer closeAllStreams];
    
    self.participants = @[];
    [self checkConversationDidEnd];
}

-(void)startPublishingWithConfiguration:(NSDictionary *)streamsConfiguration
{
    for (NSDictionary *audioConfiguration in [streamsConfiguration valueForKey:kAudioStreamsKey])
        [self startAudioStreamWithConfiguration: audioConfiguration];
    
    for (NSDictionary *videoConfiguration in [streamsConfiguration valueForKey:kVideoStreamsKey])
        [self startVideoStreamWithConfiguration: videoConfiguration];
}

-(void)startFetchingWithConfiguration:(NSDictionary *)userInfo
{
    BOOL hasRemoteParticipants = ([self numberOfRemoteParticipants] > 0);
    
    NSArray *audioStreams = [[userInfo valueForKeyPath:kNCSessionInfoKey] audioStreamsConfigurations];
    NSArray *videoStreams = [[userInfo valueForKeyPath:kNCSessionInfoKey] videoStreamsConfigurations];
    
    [self addRemoteAudioStreams: audioStreams withUserInfo:userInfo];
    [self addRemoteVideoStreams: videoStreams withUserInfo:userInfo];
    
    if (!hasRemoteParticipants)
        [self setStreamWithPrefixActive:[[self getStreamsForPariticpant:[userInfo valueForKeyPath:kNCSessionUsernameKey]
                                                              isRemote:YES].allKeys firstObject]];
}

-(void)setParticipants:(NSArray *)participants
{
    _participants = participants;
    _currentConversationStatus = [NCNdnRtcLibraryController sharedInstance].sessionStatus;
}

// NCStackEditorEntryDelegate
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    
}

// NCStreamBrowserControllerDelegate
-(void)streamBrowserController:(NCStreamBrowserController *)browserController
               streamWasClosed:(NCStreamPreviewController *)previewController
                       forUser:(NSString *)userName
                     forPrefix:(NSString *)streamPrefix
{
    if (browserController == self.localStreamViewer)
    {
        NCCameraCapturer *cameraCapturer = (NCCameraCapturer*)[previewController.userData objectForKey:kCameraCapturerKey];
        if (cameraCapturer)
            [cameraCapturer stopCapturing];
        [self removeLocalStreamWithPrefix:(NSString*)[previewController.userData objectForKey:kStreamPrefixKey]];
    }
    else
        [self removeRemoteStreamWithPrefix:[previewController.userData objectForKey:kStreamPrefixKey]];
    
    [self checkConversationDidEnd];
}

-(void)streamBrowserController:(NCStreamBrowserController *)browserController
               willCloseStream:(NCStreamPreviewController *)previewController
                       forUser:(NSString *)userName forPrefix:(NSString *)streamPrefix
{
    if (browserController == self.localStreamViewer)
    {
        NCCameraCapturer *cameraCapturer = (NCCameraCapturer*)[previewController.userData objectForKey:kCameraCapturerKey];
        if (cameraCapturer)
            [cameraCapturer stopCapturing];
        [self removeLocalStreamWithPrefix:[previewController.userData objectForKey:kStreamPrefixKey]];
    }
    else
        [self removeRemoteStreamWithPrefix:[previewController.userData objectForKey:kStreamPrefixKey]];
}

// NCStreamPreviewControllerDelegate
-(void)streamPreviewControllerWasSelected:(NCStreamPreviewController *)streamPreviewController
{
    if (self.currentlySelectedPreview && [self.currentlySelectedPreview isKindOfClass:[NCVideoPreviewController class]])
    {
        [((NCVideoPreviewController*)self.currentlySelectedPreview) setPreviewForVideoRenderer:self.activeStreamViewer.renderer];
    }
    
    NSString *streamPrefix = [streamPreviewController.userData valueForKey:kStreamPrefixKey];
    [self setStreamWithPrefixActive:streamPrefix];
}

// private
-(void)setStreamWithPrefixActive:(NSString*)streamPrefix
{
    NSMutableDictionary *participantInfo = [self getParticipantInfoForStream:streamPrefix];
    NSString *username = [participantInfo valueForKey:kNCSessionUsernameKey];
    
    self.activeStreamViewer.userName = username;
    self.activeStreamViewer.streamName = [streamPrefix lastPathComponent];
//    self.activeStreamViewer.mediaThreads = [self getStreamsForPariticpant:username isRemote:NO];
    
    NCVideoPreviewController *previewController = [[participantInfo objectForKey:kNCRemoteStreamsDictionaryKey] valueForKey:streamPrefix];

    if (previewController && [previewController isKindOfClass:[NCVideoPreviewController class]])
    {
        [self.remoteStreamViewer removeEntryHighlight];
        [self.remoteStreamViewer highlightEntryWithcontroller:previewController];
        self.currentlySelectedPreview = previewController;
        
        NCVideoStreamRenderer *renderer = [[(NCVideoPreviewController*)previewController userData] valueForKey:kRendererKey];
        [previewController setPreviewForVideoRenderer:nil];
        
        self.activeStreamViewer.renderer = renderer;
    }
}

-(void)onAppWillTerminate:(NSNotification*)notification
{
    if (self.participants.count > 0)
        [self endConversation:nil];
}

-(void)onSessionStatusUpdate:(NSNotification*)notification
{
    if ([[notification.userInfo valueForKey:kNCSessionPrefixKey] isEqualToString:[NCNdnRtcLibraryController sharedInstance].sessionPrefix])
    {
        _currentConversationStatus = (NCSessionStatus)[[notification.userInfo valueForKey:kNCSessionStatusKey] integerValue];
    }
}

-(void)addUserToConversation:(NSMutableDictionary*)participantInfo
{
    NSMutableArray *newParticipants = [NSMutableArray arrayWithArray:self.participants];
    [newParticipants addObject:participantInfo];
    
    self.participants = [NSArray arrayWithArray:newParticipants];
}

-(void)removeUserFromConversation:(NSMutableDictionary*)participantInfo
{
    if ([[self.participants valueForKeyPath:kNCSessionPrefixKey]
         containsObject:[participantInfo valueForKeyPath:kNCSessionPrefixKey]])
    {
        self.participants = [self.participants arrayByRemovingObject:participantInfo];
    }
}

-(void)addStreamToConversation:(NSString*)streamPrefix
                 sessionPrefix:(NSString*)sessionPrefix
                      userName:(NSString*)userName
                      isRemote:(BOOL)isStreamRemote
                      userInfo:(id)userInfo
{
    NSString *streamsArrayKey = (isStreamRemote)?kNCRemoteStreamsDictionaryKey:kNCLocalStreamsDictionaryKey;
    NSString *otherStreamsArrayKey = (isStreamRemote)?kNCLocalStreamsDictionaryKey:kNCRemoteStreamsDictionaryKey;
    
    if ([[self.participants valueForKeyPath:kNCSessionPrefixKey]
         containsObject:sessionPrefix])
    {
        NSArray *participantArray = [self.participants filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"prefix==%@", sessionPrefix]];
        NSAssert((participantArray.count == 1), @"should have 1 object");
        
        NSMutableDictionary *participantInfo = [participantArray firstObject];
        [[participantInfo valueForKey:streamsArrayKey] setObject:userInfo forKey:streamPrefix];
    }
    else
    {
        [self addUserToConversation:[@{
                                      kNCSessionPrefixKey:sessionPrefix,
                                      kNCSessionUsernameKey:userName,
                                      streamsArrayKey:[@{streamPrefix:userInfo} deepMutableCopy],
                                      otherStreamsArrayKey:@{}
                                      } deepMutableCopy]];
    }
}

-(void)removeStreamFromConversation:(NSString*)streamPrefix
                           isRemote:(BOOL)isStreamRemote
{
    NSString *streamsArrayKey = (isStreamRemote)?kNCRemoteStreamsDictionaryKey:kNCLocalStreamsDictionaryKey;
    NSString *otherStreamsArrayKey = (isStreamRemote)?kNCLocalStreamsDictionaryKey:kNCRemoteStreamsDictionaryKey;
    __block NSMutableDictionary *participantForRemoval = nil;
    
    [self.participants enumerateObjectsUsingBlock:^(NSMutableDictionary *obj, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *streams = [obj valueForKey:streamsArrayKey];
        if ([streams.allKeys containsObject:streamPrefix])
        {
            [streams removeObjectForKey:streamPrefix];
            
            if (streams.count == 0 && [[obj valueForKey:otherStreamsArrayKey] count] == 0)
                participantForRemoval = obj;
        }
    }];
    
    if (participantForRemoval)
        [self removeUserFromConversation:participantForRemoval];
}

-(void)checkConversationDidEnd
{
    if (self.participants.count == 0)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(conversationViewControllerDidEndConversation:)])
            [self.delegate conversationViewControllerDidEndConversation:self];
    }
}

-(void)addRemoteAudioStreams:(NSArray*)streamConfigurations
                withUserInfo:(NSDictionary*)userInfo
{
    for (NSDictionary *streamConfiguration in streamConfigurations)
        [self addRemoteAudioStreamWithConfiguration:streamConfiguration
                                        andUserInfo:userInfo];
}

-(void)addRemoteVideoStreams:(NSArray*)streamConfigurations
                withUserInfo:(NSDictionary*)userInfo
{
    for (NSDictionary *streamConfiguration in streamConfigurations)
        [self addRemoteVideoStreamWithConfiguration:streamConfiguration
                                        andUserInfo:userInfo];
}

-(GeneralConsumerParams)consumerParams
{
    GeneralConsumerParams params;
    [[NCPreferencesController sharedInstance] getNdnRtcGeneralConsumerParameters:&params];
    return params;
}

-(GeneralProducerParams)producerParams
{
    GeneralProducerParams params;
    [[NCPreferencesController sharedInstance] getNdnRtcGeneralProducerParameters:&params];
    return params;
}

-(GeneralParams)generalParams
{
    GeneralParams params;
    [[NCPreferencesController sharedInstance] getNdnRtcGeneralParameters:&params];
    return params;
}

-(NSMutableDictionary*)getParticipantInfo:(NSString*)username
{
    return [[self.participants filteredArrayUsingPredicate:
     [NSPredicate predicateWithFormat:@"self.%@==%@",
      kNCSessionUsernameKey, username]] firstObject];
}

-(NSMutableDictionary*)getParticipantInfoForStream:(NSString*)streamPrefix
{
    __block NSMutableDictionary *participantInfo = nil;
    
    [self.participants enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
       if ([[[obj valueForKey:kNCRemoteStreamsDictionaryKey] allKeys] containsObject:streamPrefix])
           participantInfo = obj;
        else if ([[[obj valueForKey:kNCLocalStreamsDictionaryKey] allKeys] containsObject:streamPrefix])
            participantInfo = obj;
        
        *stop = (participantInfo != nil);
    }];
    
    return participantInfo;
}

-(NSUInteger)numberOfRemoteParticipants
{
    return [self.participants filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"self.%@!=%@",
             kNCSessionUsernameKey,
             [NCPreferencesController sharedInstance].userName]].count;
}

-(NSDictionary*)getStreamsForPariticpant:(NSString*)username isRemote:(BOOL)isRemote
{
    NSDictionary *participantInfo = [self getParticipantInfo:username];
    return (isRemote)?[participantInfo valueForKey:kNCRemoteStreamsDictionaryKey]:[participantInfo valueForKey:kNCLocalStreamsDictionaryKey];
}

// NdnRtc
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
        NSString *streamPrefixStr = [NSString stringWithCString:streamPrefix.c_str() encoding:NSASCIIStringEncoding];
        NCAudioPreviewController *audioPreviewVc = (NCAudioPreviewController*)[self.localStreamViewer addStreamWithConfiguration:streamConfiguration
                                                                                                           andStreamPreviewClass:[NCAudioPreviewController class]
                                                                                                                 forStreamPrefix:streamPrefixStr];
        audioPreviewVc.userData = @{
                                    kStreamPrefixKey: streamPrefixStr
                                    };
        [self addStreamToConversation:streamPrefixStr
                        sessionPrefix:[NCNdnRtcLibraryController sharedInstance].sessionPrefix
                             userName:[NCPreferencesController sharedInstance].userName
                             isRemote:NO
                             userInfo:audioPreviewVc];
    }
}

-(void)startVideoStreamWithConfiguration:(NSDictionary*)streamConfiguration
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    std::string sessionPrefix([[NCNdnRtcLibraryController sharedInstance].sessionPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    IExternalCapturer *externalCapturer;
    
    
    AVCaptureDevice *device = [[NCPreferencesController sharedInstance].videoDevices
                               objectAtIndexOrNil:[[streamConfiguration valueForKey:kInputDeviceKey] intValue]];
    
    if (device)
    {
        std::string streamPrefix = lib->addLocalStream(sessionPrefix,
                                                       [streamConfiguration asVideoStreamParams],
                                                       &externalCapturer);
        
        if (streamPrefix != "")
        {
            NSString *streamPrefixStr = [NSString stringWithCString:streamPrefix.c_str() encoding:NSASCIIStringEncoding];
            NCVideoPreviewController *videoPreviewVc = (NCVideoPreviewController*)[self.localStreamViewer
                                                                                   addStreamWithConfiguration:streamConfiguration
                                                                                   andStreamPreviewClass:[NCVideoPreviewController class]
                                                                                   forStreamPrefix:streamPrefixStr];
            
            AVCaptureDeviceFormat *format = [device.formats
                                             objectAtSignedIndexOrNil:[[streamConfiguration valueForKey:kDeviceConfigurationKey] intValue]];
            
            if (!format)
            {
                format = [device.formats lastObject];
                NSLog(@"device %@ doesn't have configuration with index %@, falling back to last configuration in the list %@",
                      device.localizedName, [streamConfiguration valueForKey:kDeviceConfigurationKey], [format localizedName]);
            }
            
            NCCameraCapturer *cameraCapturer = [[NCCameraCapturer alloc]
                                                initWithDevice: device
                                                andFormat:format];
            [cameraCapturer setNdnRtcExternalCapturer:externalCapturer];
            [videoPreviewVc setPreviewForCameraCapturer:cameraCapturer];
            [cameraCapturer startCapturing];
            
            videoPreviewVc.userData = @{
                                        kCameraCapturerKey: cameraCapturer,
                                        kStreamPrefixKey: streamPrefixStr
                                        };
            [self addStreamToConversation:streamPrefixStr
                            sessionPrefix:[NCNdnRtcLibraryController sharedInstance].sessionPrefix
                                 userName:[NCPreferencesController sharedInstance].userName
                                 isRemote:NO
                                 userInfo:videoPreviewVc];
        }
    }
    else
    {
        NSLog(@"device with index %@ was not found", [streamConfiguration valueForKey:kInputDeviceKey]);
    }
}

-(void)removeLocalStreamWithPrefix:(NSString*)streamPrefix
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    lib->removeLocalStream([[NCNdnRtcLibraryController sharedInstance].sessionPrefix cStringUsingEncoding:NSASCIIStringEncoding],
                           [streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    
    [self removeStreamFromConversation:streamPrefix isRemote:NO];
}

-(void)addRemoteAudioStreamWithConfiguration:(NSDictionary*)streamConfiguration
                                 andUserInfo:(NSDictionary*)userInfo
{
    
}

-(void)addRemoteVideoStreamWithConfiguration:(NSDictionary*)streamConfiguration
                                 andUserInfo:(NSDictionary*)userInfo
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    std::string sessionPrefix([[userInfo valueForKeyPath:kNCSessionPrefixKey] cStringUsingEncoding:NSASCIIStringEncoding]);
    NCVideoStreamRenderer *renderer = [[NCVideoStreamRenderer alloc] init];
    
    std::string streamPrefix = lib->addRemoteStream(sessionPrefix,
                                                    [streamConfiguration asVideoStreamParams],
                                                    [self generalParams],
                                                    [self consumerParams],
                                                    (IExternalRenderer*)renderer.ndnRtcRenderer);
    
    if (streamPrefix != "")
    {
        NSString *streamPrefixStr = [NSString stringWithCString:streamPrefix.c_str() encoding:NSASCIIStringEncoding];
        NCVideoPreviewController *videoPreviewVc = (NCVideoPreviewController*)[self.remoteStreamViewer addStreamWithConfiguration:streamConfiguration
                                                                                                            andStreamPreviewClass:[NCVideoPreviewController class]
                                                                                                                  forStreamPrefix:streamPrefixStr];
        videoPreviewVc.delegate = self;
        [videoPreviewVc setPreviewForVideoRenderer:renderer];
        videoPreviewVc.userData = @{
                                    kRendererKey: renderer,
                                    kStreamPrefixKey:streamPrefixStr
                                    };
        [self addStreamToConversation:streamPrefixStr
                        sessionPrefix:[userInfo valueForKeyPath:kNCSessionPrefixKey]
                             userName:[userInfo valueForKeyPath:kNCSessionUsernameKey]
                             isRemote:YES
                             userInfo:videoPreviewVc];
        
    }
}

-(void)removeRemoteStreamWithPrefix:(NSString*)streamPrefix
{  
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    lib->removeRemoteStream([streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    
    [self removeStreamFromConversation:streamPrefix isRemote:YES];
    
}

@end

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
#import "NSString+NCAdditions.h"
#import "NCErrorController.h"
#import "NCStatisticsWindowController.h"
#import "NCDropScrollview.h"

using namespace ndnrtc;
using namespace ndnrtc::new_api;

NSString* const kCameraCapturerKey = @"cameraCapturer";
NSString* const kRendererKey = @"videoRenderer";
NSString* const kNCLocalStreamsDictionaryKey = @"localStreamsDictionary";
NSString* const kNCRemoteStreamsDictionaryKey = @"remoteStreamsDictionary";

NSString* const NCStreamRebufferingNotification = @"NCStreamRebufferingNotification";
NSString* const NCStreamObserverEventNotification = @"NCStreamObserverEventNotification";
NSString* const kStreamObserverEventTypeKey = @"eventType";
NSString* const kStreamObserverEventDataKey = @"eventData";

//******************************************************************************
class StreamObserver : public IConsumerObserver
{
public:
    StreamObserver(NCActiveStreamViewer* viewer):
    viewer_(viewer){}
    
    ~StreamObserver()
    {
        unregisterObserver();
    }
    
    void
    setStreamPrefix(NSString* streamPrefix)
    {
        streamPrefix_ = std::string([streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    }
    
    int
    registerObserver()
    {
        NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
        return lib->setStreamObserver(streamPrefix_, this);
    }
    
    NSString*
    getStreamPrefix()
    {
        return [NSString ncStringFromCString:streamPrefix_.c_str()];
    }
    
    void
    unregisterObserver()
    {
        NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
        lib->removeStreamObserver(streamPrefix_);
    }
    
    void
    onStatusChanged(ConsumerStatus newStatus)
    {
        static std::string statusToImageName[] = {
            [ConsumerStatusStopped] =     "status_stopped",
            [ConsumerStatusNoData] =     "status_nodata",
            [ConsumerStatusChasing] =      "status_chasing",
            [ConsumerStatusBuffering] =   "status_buffering",
            [ConsumerStatusFetching] =     "status_fetching",
        };
        static std::string statusToString[] = {
            [ConsumerStatusStopped] =     "stopped",
            [ConsumerStatusNoData] =     "no data",
            [ConsumerStatusChasing] =      "chasing",
            [ConsumerStatusBuffering] =   "buffering",
            [ConsumerStatusFetching] =     "fetching",
        };
        
        lastStatus_ = newStatus;
        
        viewer_.statusLabel.stringValue = [NSString ncStringFromCString:statusToString[newStatus].c_str()];
        
        NSString *imageName = [NSString ncStringFromCString:statusToImageName[newStatus].c_str()];
        NSImage *image = [NSImage imageNamed: imageName];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (viewer_)
                [viewer_.statusImageView setImage: image];
        });
    }
    
    void
    onRebufferingOccurred()
    {
        [[[NSObject alloc] init] notifyNowWithNotificationName:NCStreamRebufferingNotification
                                                   andUserInfo:nil];
    }
    
    void
    onPlaybackEventOccurred(PlaybackEvent event, unsigned int frameSeqNo)
    {
        [[[NSObject alloc] init] notifyNowWithNotificationName:NCStreamObserverEventNotification
                                                   andUserInfo:@{
                                                                 kStreamObserverEventTypeKey:@(event),
                                                                 kStreamObserverEventDataKey:@(frameSeqNo)
                                                                 }];
    }
    
    void
    onThreadSwitched(const std::string& threadName)
    {
        NSLog(@"active thread is %s for %s", threadName.c_str(),
              streamPrefix_.c_str());
    }
    
private:
    ConsumerStatus lastStatus_;
    std::string streamPrefix_;
    __weak NCActiveStreamViewer* viewer_;
};

//******************************************************************************
@interface NCConversationViewController ()
{
    StreamObserver *_activeStreamObserver;
}

@property (nonatomic) NSMutableDictionary *localStreams;

@property (weak) IBOutlet NSScrollView *localStreamsScrollView;
@property (weak) IBOutlet NCDropScrollView *remoteStreamsScrollView;
@property (weak) IBOutlet NSView *activeStreamContentView;
@property (strong) IBOutlet NSView *startPublishingView;

@property (nonatomic, strong) NCStreamBrowserController *localStreamViewer;
@property (nonatomic, strong) NCStreamBrowserController *remoteStreamViewer;

@property (nonatomic, strong) NCActiveStreamViewer *activeStreamViewer;
@property (nonatomic, weak) NCStreamPreviewController *currentlySelectedPreview;
@property (nonatomic, strong) NCStatisticsWindowController *statisticsController;
@property (weak) IBOutlet NSButton *statisticsButton;

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
    _activeStreamObserver = new StreamObserver(self.activeStreamViewer);
    
    [self subscribeForNotificationsAndSelectors:
     NCLocalSessionStatusUpdateNotification, @selector(onSessionStatusUpdate:),
     NCStreamObserverEventNotification, @selector(onStreamEvent:),
     NCStreamRebufferingNotification, @selector(onStreamEvent:),
     nil];
}

-(void)dealloc
{
    _activeStreamObserver->unregisterObserver();
    delete _activeStreamObserver;
    
    [self unsubscribeFromNotifications];
    
    self.localStreamViewer = nil;
    self.remoteStreamViewer = nil;
}

-(void)awakeFromNib
{
    self.remoteStreamsScrollView.delegate = self.delegate;
    [self.remoteStreamsScrollView registerForDraggedTypes:@[NSStringPboardType]];    
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
    
    self.activeStreamViewer.view.layer.backgroundColor = self.remoteStreamsScrollView.backgroundColor.CGColor;
    self.activeStreamViewer.delegate = self;
    
    self.localStreamViewer.backgroundColor = self.localStreamsScrollView.backgroundColor;
    self.remoteStreamViewer.backgroundColor = self.remoteStreamsScrollView.backgroundColor;
}

- (IBAction)startPublishing:(id)sender
{
    [self.localStreamsScrollView addStackView:self.localStreamViewer.stackView
                              withOrientation:NSUserInterfaceLayoutOrientationHorizontal];
    [self startPublishingWithConfiguration:[NCPreferencesController sharedInstance].producerConfigurationCopy];
}

- (IBAction)endConversation:(id)sender
{
    [self.remoteStreamViewer closeAllStreams];
    [self.localStreamViewer closeAllStreams];    
    
    self.participants = @[];
    
    if (self.statisticsController)
    {
        [self.statisticsController stopStatUpdate];
        self.statisticsController = nil;
    }
    
    [self checkConversationDidEnd];
}

- (IBAction)showStatistics:(id)sender
{
    if ([self.statisticsController.window isVisible])
        [self.statisticsController close];
    else
    {
        if (!self.statisticsController)
        {
            self.statisticsController = [[NCStatisticsWindowController alloc] init];
            self.statisticsController.delegate = self;
        }
        [self.statisticsController showWindow:nil];
    }
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
    if ([self getParticipantInfo:[userInfo valueForKey:kNCSessionUsernameKey]])
        return;
    
    BOOL hasRemoteParticipants = ([self numberOfRemoteParticipants] > 0);
    
    NSArray *audioStreams = [[userInfo valueForKeyPath:kNCSessionInfoKey] audioStreamsConfigurations];
    NSArray *videoStreams = [[userInfo valueForKeyPath:kNCSessionInfoKey] videoStreamsConfigurations];
    
    [self addRemoteVideoStreams: videoStreams withUserInfo:userInfo];

    // select first video stream if no stream selected
    if (!hasRemoteParticipants)
        [self setStreamWithPrefixActive:[[self getStreamsForPariticpant:[userInfo valueForKeyPath:kNCSessionUsernameKey]
                                                               isRemote:YES].allKeys firstObject]];
    
    [self addRemoteAudioStreams: audioStreams withUserInfo:userInfo];
}

-(void)setParticipants:(NSArray *)participants
{
    _participants = participants;
    _currentConversationStatus = [NCNdnRtcLibraryController sharedInstance].sessionStatus;
}

// NCActiveStreamViewerDelegate
-(void)activeStreamViewer:(NCActiveStreamViewer *)activeStreamViewer didSelectThreadWithConfiguration:(NSDictionary *)threadConfiguration
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    lib->switchThread([activeStreamViewer.streamPrefix cStringUsingEncoding:NSASCIIStringEncoding],
                      [[threadConfiguration valueForKey:kNameKey] cStringUsingEncoding:NSASCIIStringEncoding]);
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
    if ([streamPreviewController isKindOfClass:[NCVideoPreviewController class]])
    {
        NSString *streamPrefix = [streamPreviewController.userData valueForKey:kStreamPrefixKey];
        
        if (streamPrefix != self.activeStreamViewer.streamPrefix)
        {
            if ([self.currentlySelectedPreview isKindOfClass:[NCVideoPreviewController class]])
                [((NCVideoPreviewController*)self.currentlySelectedPreview) setPreviewForVideoRenderer:self.activeStreamViewer.renderer];
            [self setStreamWithPrefixActive:streamPrefix];
        }
    }
}

// NCStatisticsWindowControllerDelegate
-(NSArray *)statisticsWindowControllerNeedParticipantsArray:(NCStatisticsWindowController *)wc
{
    return self.participants;
}

-(void)statisticsWindowControllerWindowWillClose:(NCStatisticsWindowController *)wc
{
    self.statisticsButton.state = NSOffState;
}

// private
-(void)setStreamWithPrefixActive:(NSString*)streamPrefix
{
    NSMutableDictionary *participantInfo = [self getParticipantInfoForStream:streamPrefix];
    NCVideoPreviewController *previewController = [[participantInfo objectForKey:kNCRemoteStreamsDictionaryKey] valueForKey:streamPrefix];

    [self.remoteStreamViewer removeEntryHighlight];
    [self.remoteStreamViewer highlightEntryWithcontroller:previewController];
    
    if (previewController && [previewController isKindOfClass:[NCVideoPreviewController class]])
    {
        [self.activeStreamViewer clearStreamEventView];
        // set active stream viewer parameters
        self.activeStreamViewer.streamPrefix = streamPrefix;
        self.activeStreamViewer.userInfo = participantInfo;

        // set active stream viewer observer
        if (![_activeStreamObserver->getStreamPrefix() isEqualToString:@""])
            _activeStreamObserver->unregisterObserver();
        
        _activeStreamObserver->setStreamPrefix(streamPrefix);
        _activeStreamObserver->registerObserver();
        
        // set current thread
        NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
        std::string activeThreadName = lib->getStreamThread(std::string([streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]));
        
        if (activeThreadName != "")
            self.activeStreamViewer.currentThreadIdx = @([[self.activeStreamViewer.mediaThreads valueForKeyPath:kNameKey]
             indexOfObject:[NSString ncStringFromCString:activeThreadName.c_str()]]);

        self.currentlySelectedPreview.isSelected = NO;
        self.currentlySelectedPreview = previewController;
        self.currentlySelectedPreview.isSelected = YES;
        
        NCVideoStreamRenderer *renderer = [[(NCVideoPreviewController*)previewController userData] valueForKey:kRendererKey];
        [previewController setPreviewForVideoRenderer:nil];
        
        self.activeStreamViewer.renderer = renderer;
    }
}

-(void)onSessionStatusUpdate:(NSNotification*)notification
{
    _currentConversationStatus = (NCSessionStatus)[[notification.userInfo valueForKey:kNCSessionStatusKey] integerValue];
}

-(void)onStreamEvent:(NSNotification*)notification
{
    if ([notification.name isEqualToString:NCStreamRebufferingNotification])
        [self.activeStreamViewer renderStreamEvent:@"rebuffering"];

    if ([notification.name isEqualToString:NCStreamObserverEventNotification])
    {
        PlaybackEvent event = (PlaybackEvent)[[notification.userInfo valueForKey:kStreamObserverEventTypeKey] integerValue];
        NSInteger frameNo = [[notification.userInfo valueForKey:kStreamObserverEventDataKey] integerValue];
        static std::string eventToString[] = {
            [PlaybackEventDeltaSkipIncomplete] = "skip delta: incomplete",
            [PlaybackEventDeltaSkipInvalidGop] = "skip delta: bad gop",
            [PlaybackEventDeltaSkipNoKey] = "skip delta: no key",
            [PlaybackEventKeySkipIncomplete] = "skip key: incomplete"
        };
        
        NSString *eventStr = [NSString ncStringFromCString:eventToString[event].c_str()];
        [self.activeStreamViewer renderStreamEvent:
         [NSString stringWithFormat:@"%@ (#%ld)", eventStr, (long)frameNo]];
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
                      userDict:(NSDictionary*)userDictionary
                      isRemote:(BOOL)isStreamRemote
                      userInfo:(id)userInfo
{
    NSString *sessionPrefix = [userDictionary objectForKey:kNCSessionPrefixKey];
    NSString *streamsArrayKey = (isStreamRemote)?kNCRemoteStreamsDictionaryKey:kNCLocalStreamsDictionaryKey;
    NSString *otherStreamsArrayKey = (isStreamRemote)?kNCLocalStreamsDictionaryKey:kNCRemoteStreamsDictionaryKey;
    
    if ([[self.participants valueForKeyPath:kNCSessionPrefixKey]
         containsObject:sessionPrefix])
    {
        NSArray *participantArray = [self.participants filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"prefix==%@", sessionPrefix]];
        NSAssert((participantArray.count == 1), @"should have 1 object");
        
        NSMutableDictionary *participantInfo = [participantArray firstObject];
        [[participantInfo valueForKey:streamsArrayKey] setObject:userInfo forKey:streamPrefix];
        
        // update session info
        [participantInfo setValue:[userDictionary valueForKey:kNCSessionInfoKey] forKey:kNCSessionInfoKey];
    }
    else
    {
        NSMutableDictionary *newParticipantDict = [userDictionary deepMutableCopy];
        [newParticipantDict setValue:[@{streamPrefix:userInfo} deepMutableCopy]
                              forKey:streamsArrayKey];
        [newParticipantDict setValue:[@{} mutableCopy]
                              forKey:otherStreamsArrayKey];
        [self addUserToConversation:newParticipantDict];
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
                             userDict:@{
                                        kNCSessionPrefixKey:[NCNdnRtcLibraryController sharedInstance].sessionPrefix,
                                        kNCSessionUsernameKey:[NCPreferencesController sharedInstance].userName
                                        }
                             isRemote:NO
                             userInfo:audioPreviewVc];
    }
    else
        [[NCErrorController sharedInstance] postErrorWithMessage:@"Couldn't start audio stream"];
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
                                 userDict:@{
                                            kNCSessionPrefixKey:[NCNdnRtcLibraryController sharedInstance].sessionPrefix,
                                            kNCSessionUsernameKey:[NCPreferencesController sharedInstance].userName
                                            }
                                 isRemote:NO
                                 userInfo:videoPreviewVc];
        }
        else
            [[NCErrorController sharedInstance] postErrorWithMessage:@"Couldn't start video stream"];
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
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    std::string sessionPrefix([[userInfo valueForKeyPath:kNCSessionPrefixKey] cStringUsingEncoding:NSASCIIStringEncoding]);
    std::string streamPrefix = lib->addRemoteStream(sessionPrefix,
                                                    [streamConfiguration asAudioStreamParams],
                                                    [self generalParams],
                                                    [self consumerParams],
                                                    NULL);
    if (streamPrefix != "")
    {
        NSString *streamPrefixStr = [NSString stringWithCString:streamPrefix.c_str() encoding:NSASCIIStringEncoding];
        NCAudioPreviewController *audioPreviewVc = (NCAudioPreviewController*)[self.remoteStreamViewer addStreamWithConfiguration:streamConfiguration
                                                                                                            andStreamPreviewClass:[NCAudioPreviewController class]
                                                                                                                  forStreamPrefix:streamPrefixStr];
        audioPreviewVc.userData = @{
                                    kStreamPrefixKey:streamPrefixStr
                                    };
        [self addStreamToConversation:streamPrefixStr
                             userDict:userInfo
                             isRemote:YES
                             userInfo:audioPreviewVc];
    }
    else
        [[NCErrorController sharedInstance] postErrorWithMessage:@"Couldn't add audio stream"];
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
                             userDict:userInfo
                             isRemote:YES
                             userInfo:videoPreviewVc];
    }
    else
        [[NCErrorController sharedInstance] postErrorWithMessage:@"Couldn't add video stream"];
}

-(void)removeRemoteStreamWithPrefix:(NSString*)streamPrefix
{
    NSLog(@"*** removing stream %@", streamPrefix);
    
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    lib->removeRemoteStream([streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    
    [self removeStreamFromConversation:streamPrefix isRemote:YES];
    
}

@end

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
#import "NCNdnRtcLibraryController.h"
#import "NCVideoThreadViewController.h"
#import "NCAudioThreadViewController.h"
#import "NCCameraCapturer.h"
#import "NSArray+NCAdditions.h"
#import "AVCaptureDeviceFormat+NdnConAdditions.h"

using namespace ndnrtc;
using namespace ndnrtc::new_api;

const NSString *kCameraCapturerKey = @"cameraCapturer";
const NSString *kStreamPrefixKey = @"streamPrefix";

@interface NSDictionary (NdnRtcParamsAdditions)

-(MediaStreamParams)asAudioStreamParams;
-(MediaStreamParams)asVideoStreamParams;
-(VideoThreadParams)asVideoThreadParams;
-(AudioThreadParams)asAudioThreadParams;

@end

@interface NCConversationViewController ()

@property (nonatomic) NSMutableDictionary *localStreams;

@property (weak) IBOutlet NSScrollView *localStreamsScrollView;
@property (weak) IBOutlet NSScrollView *remoteStreamsScrollView;
@property (weak) IBOutlet NSView *activeStreamContentView;

@property (nonatomic, strong) NCStreamBrowserController *localStreamViewer;
@property (nonatomic, strong) NCStreamBrowserController *remoteStreamViewer;

@end

@implementation NCConversationViewController

-(id)init
{
    self = [self initWithNibName:@"NCConverstaionView" bundle:nil];
    
    if (self)
        [self initialize];
    
    return self;
}

-(void)initialize
{
    self.localStreams = [NSMutableDictionary dictionary];
    
    self.localStreamViewer = [[NCStreamBrowserController alloc] init];
    self.localStreamViewer.delegate = self;
    
    self.remoteStreamViewer = [[NCStreamBrowserController alloc] init];
    self.remoteStreamViewer.delegate = self;
}

-(void)dealloc
{
    self.localStreamViewer = nil;
    self.remoteStreamViewer = nil;
}

-(void)awakeFromNib
{
    [self.localStreamsScrollView addStackView:self.localStreamViewer.stackView
                              withOrientation:NSUserInterfaceLayoutOrientationHorizontal];
    [self.remoteStreamsScrollView addStackView:self.remoteStreamViewer.stackView
                               withOrientation:NSUserInterfaceLayoutOrientationVertical];
}

- (IBAction)endConversation:(id)sender
{
    NSLog(@"end converstaion");
}

-(void)startPublishingWithConfiguration:(NSDictionary *)streamsConfiguration
{
    for (NSDictionary *audioConfiguration in [streamsConfiguration valueForKey:kAudioStreamsKey])
        [self startAudioStreamWithConfiguration: audioConfiguration];
    
    for (NSDictionary *videoConfiguration in [streamsConfiguration valueForKey:kVideoStreamsKey])
        [self startVideoStreamWithConfiguration: videoConfiguration];
}


// NCStackEditorEntryDelegate
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    
}

// private
-(void)startAudioStreamWithConfiguration:(NSDictionary*)streamConfiguration
{
//    [self startLibraryStreamWithConfiguration: ]
    [self.localStreamViewer addStreamWithConfiguration:streamConfiguration
                                 andStreamPreviewClass:[NCAudioPreviewController class]];
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
            NCVideoPreviewController *videoPreviewVc = (NCVideoPreviewController*)[self.localStreamViewer
                                                                                   addStreamWithConfiguration:streamConfiguration
                                                                                   andStreamPreviewClass:[NCVideoPreviewController class]];
            
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
                                        kStreamPrefixKey: [NSString stringWithCString:streamPrefix.c_str() encoding:NSASCIIStringEncoding]
                                        };
            
//            [self.localStreams
//             setObject:cameraCapturer
//             forKey:[NSString stringWithCString:streamPrefix.c_str() encoding:NSASCIIStringEncoding]];
        }
    }
    else
    {
        NSLog(@"device with index %@ was not found", [streamConfiguration valueForKey:kInputDeviceKey]);
    }
}

// NCStreamBrowserControllerDelegate
-(void)streamBrowserController:(NCStreamBrowserController *)browserController
               streamWasClosed:(NCStreamPreviewController *)previewController
                       forUser:(NSString *)userName
{
    if (browserController == self.localStreamViewer)
    {
        NCCameraCapturer *cameraCapturer = (NCCameraCapturer*)[previewController.userData objectForKey:kCameraCapturerKey];
        [cameraCapturer stopCapturing];
    }

    [self removeStreamWithPrefix:(NSString*)[previewController.userData objectForKey:kStreamPrefixKey]];
}

// private
-(void)removeStreamWithPrefix:(NSString*)streamPrefix
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    lib->removeLocalStream([[NCNdnRtcLibraryController sharedInstance].sessionPrefix cStringUsingEncoding:NSASCIIStringEncoding],
                           [streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
}

@end


@implementation NSDictionary (NdnRtcParamsAdditions)

-(ndnrtc::new_api::MediaStreamParams)asVideoStreamParams
{
    MediaStreamParams params;
    params.type_ = MediaStreamParams::MediaStreamTypeVideo;

#warning maybe put these parameters inside stream configuration dictionary
    params.producerParams_.segmentSize_ = [NCPreferencesController sharedInstance].videoSegmentSize.intValue;
    params.producerParams_.freshnessMs_ = [NCPreferencesController sharedInstance].videoFreshness.intValue;
    
    if ([self valueForKey:kNameKey])
        params.streamName_ = std::string([(NSString*)[self valueForKey:kNameKey] cStringUsingEncoding:NSASCIIStringEncoding]);
    
    if ([self valueForKey:kInputDeviceKey])
    {
        params.captureDevice_ = new CaptureDeviceParams();
        params.captureDevice_->deviceId_ = [[self valueForKey:kInputDeviceKey] intValue];
    }
    
    if ([self valueForKey:kThreadsArrayKey])
    {
        NSArray *threads = (NSArray *)[self valueForKey:kThreadsArrayKey];

        for (NSDictionary *threadConfiguration in threads)
        {
            VideoThreadParams *threadParams = new VideoThreadParams();
            *threadParams = [threadConfiguration asVideoThreadParams];
            params.mediaThreads_.push_back(threadParams);
        }
    }
    
    return params;
}

-(ndnrtc::new_api::MediaStreamParams)asAudioStreamParams
{
    MediaStreamParams params;
    params.type_ = MediaStreamParams::MediaStreamTypeAudio;
    
#warning maybe put these parameters inside stream configuration dictionary
    params.producerParams_.segmentSize_ = [NCPreferencesController sharedInstance].audioSegmentSize.intValue;
    params.producerParams_.freshnessMs_ = [NCPreferencesController sharedInstance].audioFreshness.intValue;
    
    if ([self valueForKey:kNameKey])
        params.streamName_ = std::string([(NSString*)[self valueForKey:kNameKey] cStringUsingEncoding:NSASCIIStringEncoding]);
    
    if ([self valueForKey:kInputDeviceKey])
    {
        params.captureDevice_ = new CaptureDeviceParams();
        params.captureDevice_->deviceId_ = [[self valueForKey:kInputDeviceKey] intValue];
    }
    
    if ([self valueForKey:kThreadsArrayKey])
    {
        NSArray *threads = (NSArray *)[self valueForKey:kThreadsArrayKey];
        
        for (NSDictionary *threadConfiguration in threads)
        {
            AudioThreadParams *threadParams = new AudioThreadParams();
            *threadParams = [threadConfiguration asAudioThreadParams];
            params.mediaThreads_.push_back(threadParams);
        }
    }
    
    return params;
}

-(ndnrtc::new_api::VideoThreadParams)asVideoThreadParams
{
    VideoThreadParams params;
    
    if ([self valueForKey:kNameKey])
        params.threadName_ = std::string([(NSString*)[self valueForKey:kNameKey] cStringUsingEncoding:NSASCIIStringEncoding]);
    
    if ([self valueForKey:kFrameRateKey])
        params.coderParams_.codecFrameRate_ = [[self valueForKey:kFrameRateKey] intValue];
    
    if ([self valueForKey:kGopKey])
        params.coderParams_.gop_ = [[self valueForKey:kGopKey] intValue];
    
    if ([self valueForKey:kBitrateKey])
        params.coderParams_.startBitrate_ = [[self valueForKey:kBitrateKey] intValue];
    
    if ([self valueForKey:kMaxBitrateKey])
        params.coderParams_.maxBitrate_ = [[self valueForKey:kMaxBitrateKey] intValue];
    
    if ([self valueForKey:kEncodingHeightKey])
        params.coderParams_.encodeHeight_ = [[self valueForKey:kEncodingHeightKey] intValue];
    
    if ([self valueForKey:kEncodingWidthKey])
        params.coderParams_.encodeWidth_ = [[self valueForKey:kEncodingWidthKey] intValue];
    
    return params;
}

-(ndnrtc::new_api::AudioThreadParams)asAudioThreadParams
{
    AudioThreadParams params;
    
    if ([self valueForKey:kNameKey])
        params.threadName_ = std::string([(NSString*)[self valueForKey:kNameKey] cStringUsingEncoding:NSASCIIStringEncoding]);
    
    return params;
}

@end
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

using namespace ndnrtc;
using namespace ndnrtc::new_api;

NSString* const kCameraCapturerKey = @"cameraCapturer";
NSString* const kNCStreamsArrayKey = @"streamsArray";

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
    self.participants = [[NSMutableArray alloc] init];
    self.localStreams = [NSMutableDictionary dictionary];
    
    self.localStreamViewer = [[NCStreamBrowserController alloc] init];
    self.localStreamViewer.delegate = self;
    
    self.remoteStreamViewer = [[NCStreamBrowserController alloc] init];
    self.remoteStreamViewer.delegate = self;
    
    [self subscribeForNotificationsAndSelectors:
     NCSessionStatusUpdateNotification, @selector(onSessionStatusUpdate:),
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
    [self.localStreamsScrollView addStackView:self.localStreamViewer.stackView
                              withOrientation:NSUserInterfaceLayoutOrientationHorizontal];
    [self.remoteStreamsScrollView addStackView:self.remoteStreamViewer.stackView
                               withOrientation:NSUserInterfaceLayoutOrientationVertical];
}

- (IBAction)endConversation:(id)sender
{
    [self.localStreamViewer closeAllStreams];

    if (self.remoteStreamViewer)
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

-(void)setParticipants:(NSArray *)participants
{
    _participants = participants;
    _currentConversationStatus = [NCNdnRtcLibraryController sharedInstance].sessionStatus;
}

// NCStackEditorEntryDelegate
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    
}

// private
-(void)onSessionStatusUpdate:(NSNotification*)notification
{
    if ([[notification.userInfo valueForKey:kNCSessionPrefixKey] isEqualToString:[NCNdnRtcLibraryController sharedInstance].sessionPrefix])
    {
        _currentConversationStatus = (NCSessionStatus)[[notification.userInfo valueForKey:kNCSessionStatusKey] integerValue];
    }
}

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
                             userName:[NCPreferencesController sharedInstance].userName];
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
                                 userName:[NCPreferencesController sharedInstance].userName];
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
                     forPrefix:(NSString *)streamPrefix
{
    if (browserController == self.localStreamViewer)
    {
        NCCameraCapturer *cameraCapturer = (NCCameraCapturer*)[previewController.userData objectForKey:kCameraCapturerKey];
        if (cameraCapturer)
            [cameraCapturer stopCapturing];
        [self removeLocalStreamWithPrefix:(NSString*)[previewController.userData objectForKey:kStreamPrefixKey]];
    }
    
    [self checkConversationDidEnd];
}

-(void)streamBrowserController:(NCStreamBrowserController *)browserController willCloseStream:(NCStreamPreviewController *)previewController forUser:(NSString *)userName forPrefix:(NSString *)streamPrefix
{
    if (browserController == self.localStreamViewer)
    {
        NCCameraCapturer *cameraCapturer = (NCCameraCapturer*)[previewController.userData objectForKey:kCameraCapturerKey];
        if (cameraCapturer)
            [cameraCapturer stopCapturing];
        [self removeLocalStreamWithPrefix:(NSString*)[previewController.userData objectForKey:kStreamPrefixKey]];
    }
}

// private
-(void)removeLocalStreamWithPrefix:(NSString*)streamPrefix
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    lib->removeLocalStream([[NCNdnRtcLibraryController sharedInstance].sessionPrefix cStringUsingEncoding:NSASCIIStringEncoding],
                           [streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    
    [self removeStreamFromConversation:streamPrefix];
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
{
    if ([[self.participants valueForKeyPath:kNCSessionPrefixKey]
         containsObject:sessionPrefix])
    {
        NSArray *participantArray = [self.participants filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"prefix==%@", sessionPrefix]];
        NSAssert((participantArray.count == 1), @"should have 1 object");
        
        NSMutableDictionary *participantInfo = [participantArray firstObject];
        [[participantInfo valueForKey:kNCStreamsArrayKey] addObject:streamPrefix];
    }
    else
    {
        [self addUserToConversation:[@{
                                      kNCSessionPrefixKey:sessionPrefix,
                                      kNCSessionUsernameKey:userName,
                                      kNCStreamsArrayKey:[@[streamPrefix] deepMutableCopy]
                                      } deepMutableCopy]];
    }
}

-(void)removeStreamFromConversation:(NSString*)streamPrefix
{
    __block NSMutableDictionary *participantForRemoval = nil;
    
    [self.participants enumerateObjectsUsingBlock:^(NSMutableDictionary *obj, NSUInteger idx, BOOL *stop) {
        NSArray *streams = [obj valueForKey:kNCStreamsArrayKey];
        if ([streams containsObject:streamPrefix])
        {
            NSArray *newStreams = [streams arrayByRemovingObject:streamPrefix];

            if (newStreams.count == 0)
                participantForRemoval = obj;

            [obj setValue:newStreams forKey:kNCStreamsArrayKey];
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

@end

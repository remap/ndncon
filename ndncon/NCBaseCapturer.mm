//
//  NCBaseCapturer.m
//  NdnCon
//
//  Created by Peter Gusev on 7/26/15.
//  Copyright 2013-2015 Regents of the University of California
//

#import "NCBaseCapturer.h"
#include <ndnrtc/interfaces.h>

#import "NSObject+NCAdditions.h"
#import "NCPreferencesController.h"

#define USE_YUV

using namespace ndnrtc;

#define MUTE_BUF_W 1280
#define MUTE_BUF_H 720
#define MUTE_BUF_PS 4
// this buffer is 1280x720 4-byte pixels
static unsigned char* muteVideoBuffer = nullptr;

//******************************************************************************
@interface NCBaseCapturer()
{
    IExternalCapturer *_externalCapturer;
    BOOL _isMuted;
    dispatch_queue_t _captureQueue;
}

@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) NSArray *sessionObservers;
@property (nonatomic) AVCaptureVideoDataOutput *videoOutput;

@end

@implementation NCBaseCapturer : NSObject

-(instancetype)init
{
    self = [super init];
    
    if (self)
    {
        NSDictionary *muteOptions = [[NCPreferencesController sharedInstance] getMuteOptions];
        _isMuted = [muteOptions[kMuteOptionVideoKey] boolValue];
        _externalCapturer = NULL;
        self.session = [[AVCaptureSession alloc] init];
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        id runtimeErrorObserver = [notificationCenter addObserverForName:AVCaptureSessionRuntimeErrorNotification
                                                                  object:_session
                                                                   queue:[NSOperationQueue mainQueue]
                                                              usingBlock:^(NSNotification *note) {
                                                                  dispatch_async(dispatch_get_main_queue(), ^(void) {
                                                                      [self presentError: [[note userInfo] objectForKey:AVCaptureSessionErrorKey]];
                                                                  });
                                                              }];
        id didStartRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStartRunningNotification
                                                                     object:_session
                                                                      queue:[NSOperationQueue mainQueue]
                                                                 usingBlock:^(NSNotification *note) {
                                                                 }];
        id didStopRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStopRunningNotification
                                                                    object:_session
                                                                     queue:[NSOperationQueue mainQueue]
                                                                usingBlock:^(NSNotification *note) {
                                                                }];
        self.sessionObservers = [[NSArray alloc] initWithObjects:runtimeErrorObserver, didStartRunningObserver, didStopRunningObserver, nil];
        
        [self initVideoOutput];
        
        [self subscribeForNotificationsAndSelectors:
         kNCMuteOptionsChangedNotification, @selector(onMuteOptionChanged:),
         nil];
        
        if (!muteVideoBuffer)
            [self prepareMuteFrame];
    }
    
    return self;
}

-(void)initVideoOutput
{
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    _captureQueue = dispatch_queue_create("capture_queue", NULL);
    [self.videoOutput setSampleBufferDelegate:self queue:_captureQueue];
#ifndef USE_YUV
    self.videoOutput.videoSettings = [NSDictionary dictionaryWithObject:
                                      [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                                 forKey:(id)kCVPixelBufferPixelFormatTypeKey];
#else
    self.videoOutput.videoSettings = [NSDictionary dictionaryWithObject:
                                      [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8Planar]
                                                                 forKey:(id)kCVPixelBufferPixelFormatTypeKey];
#endif
    [self.session addOutput:self.videoOutput];
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
    
    [self.session stopRunning];
    [self stopCapturing];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    for (id observer in [self sessionObservers])
        [notificationCenter removeObserver:observer];
    
    self.sessionObservers = nil;
    self.session = nil;
    self.videoOutput = nil;
}

#pragma mark - public
-(void)startCapturing
{
    [self.session startRunning];
    
    if (_externalCapturer)
        _externalCapturer->capturingStarted();
}

-(void)stopCapturing
{
    if (_externalCapturer)
        _externalCapturer->capturingStopped();
    
    [self.session stopRunning];
}

-(void)setNdnRtcExternalCapturer:(void *)externalCapturer
{
    _externalCapturer = (IExternalCapturer*)externalCapturer;
}

#pragma mark - private
-(void)presentError:(NSError*)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(capturer:didObtainedError:)])
        [self.delegate capturer: self didObtainedError: error];
}

-(void)onMuteOptionChanged:(NSNotification*)notification
{
    NSDictionary *prevOptions = notification.userInfo[kPreviousMuteOptionsKey];
    NSDictionary *options = notification.userInfo[kMuteOptionsKey];
    
    if ([prevOptions[kMuteOptionVideoKey] boolValue] != [options[kMuteOptionVideoKey] boolValue])
        [self muteVideo:[options[kMuteOptionVideoKey] boolValue]];
}

-(void)prepareMuteFrame
{
    NSImage *muteFrameImage = [NSImage imageNamed:@"muteframe"];
    NSRect rect = NSMakeRect(0, 0, MUTE_BUF_W, MUTE_BUF_H);
    CGImageRef image = [muteFrameImage CGImageForProposedRect:&rect
                                                      context:[NSGraphicsContext currentContext]
                                                        hints:nil];
    NSUInteger width = CGImageGetWidth(image);
    NSUInteger height = CGImageGetHeight(image);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    muteVideoBuffer = (unsigned char*)malloc(MUTE_BUF_W * MUTE_BUF_H * MUTE_BUF_PS * sizeof(unsigned char));
    NSUInteger bytesPerPixel = MUTE_BUF_PS;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(muteVideoBuffer, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGContextRelease(context);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
  didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    const int kFlags = 0;
    
    if (CVPixelBufferLockBaseAddress(videoFrame, kFlags) == kCVReturnSuccess)
    {
        int frameWidth = (int)CVPixelBufferGetWidth(videoFrame);
        int frameHeight = (int)CVPixelBufferGetHeight(videoFrame);
        
#ifndef USE_YUV
        void *baseAddress = CVPixelBufferGetBaseAddress(videoFrame);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(videoFrame);
        int frameSize = (int)(bytesPerRow * frameHeight);
        
        NSData *frameData = [NSData dataWithBytes: baseAddress length: frameSize];
        
        if (_externalCapturer)
            _externalCapturer->incomingArgbFrame(frameWidth, frameHeight,
                                                                       (unsigned char*)frameData.bytes, frameSize);
#else
        if (!_isMuted)
        {
            int strideY = (int)CVPixelBufferGetBytesPerRowOfPlane(videoFrame, 0);
            unsigned char* yBuffer = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(videoFrame, 0);
            int strideU = (int)CVPixelBufferGetBytesPerRowOfPlane(videoFrame, 1);
            unsigned char* uBuffer = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(videoFrame, 1);
            int strideV = (int)CVPixelBufferGetBytesPerRowOfPlane(videoFrame, 2);
            unsigned char* vBuffer = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(videoFrame, 2);
            
            if (_externalCapturer)
                _externalCapturer->incomingI420Frame(frameWidth, frameHeight,
                                                     strideY, strideU, strideV,
                                                     yBuffer, uBuffer, vBuffer);
        }
        else
        {
            if (_externalCapturer)
                _externalCapturer->incomingArgbFrame(MUTE_BUF_W, MUTE_BUF_H,
                                                     muteVideoBuffer,
                                                     MUTE_BUF_H*MUTE_BUF_W*MUTE_BUF_PS*sizeof(unsigned char));
        }
#endif
        
        CVPixelBufferUnlockBaseAddress(videoFrame, kFlags);
    }
}

-(void)muteVideo:(BOOL)shouldMute
{
        dispatch_sync(_captureQueue, ^{
            _isMuted = shouldMute;
        });
}

@end

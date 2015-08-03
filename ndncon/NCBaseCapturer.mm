//
//  NCBaseCapturer.m
//  NdnCon
//
//  Created by Peter Gusev on 7/26/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import "NCBaseCapturer.h"
#include <ndnrtc/interfaces.h>

#define USE_YUV

using namespace ndnrtc;

//******************************************************************************
@interface NCBaseCapturer()
{
    IExternalCapturer *_externalCapturer;
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
    }
    
    return self;
}

-(void)initVideoOutput
{
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    dispatch_queue_t queue = dispatch_queue_create("capture_queue", NULL);
    [self.videoOutput setSampleBufferDelegate:self queue:queue];
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
#endif
        
        CVPixelBufferUnlockBaseAddress(videoFrame, kFlags);
    }
}

@end

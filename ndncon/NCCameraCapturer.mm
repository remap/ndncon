//
//  NCCameraCapturer.m
//  NdnCon
//
//  Created by Peter Gusev on 9/19/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCCameraCapturer.h"
#include <ndnrtc/interfaces.h>

using namespace ndnrtc;

@interface NCCameraCapturer ()
{
    IExternalCapturer *_externalCapturer;
}

@property (nonatomic) NSArray *sessionObservers;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDevice *device;
@property (nonatomic) AVCaptureDeviceFormat *deviceFormat;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureVideoDataOutput *videoOutput;

@end

@implementation NCCameraCapturer

-(id)initWithDevice:(AVCaptureDevice*)device andFormat:(AVCaptureDeviceFormat*)format
{
    self = [super init];
    
    if (self)
    {
        _externalCapturer = NULL;
        
        self.device = device;
        self.deviceFormat = format;
        
        NSError *error = nil;
        
        self.session = [[AVCaptureSession alloc] init];
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
        
        AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device
                                                                                          error:&error];
        
        if (newVideoDeviceInput == nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self presentError:error];
            });
            
            return nil;
        }
        else
        {
            if (![self.device supportsAVCaptureSessionPreset:[_session sessionPreset]])
                [[self session] setSessionPreset:AVCaptureSessionPresetHigh];
            
            [[self session] addInput:newVideoDeviceInput];
            self.videoDeviceInput = newVideoDeviceInput;
        }
        
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
        
        self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        dispatch_queue_t queue = dispatch_queue_create("capture_queue", NULL);
        [self.videoOutput setSampleBufferDelegate:self queue:queue];
        self.videoOutput.videoSettings = [NSDictionary dictionaryWithObject:
                                          [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                                     forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [self.session addOutput:self.videoOutput];
    }
    
    return self;
}

-(void)dealloc
{
    [self.session stopRunning];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    for (id observer in [self sessionObservers])
        [notificationCenter removeObserver:observer];
    
    self.sessionObservers = nil;
    self.session = nil;
    self.device = nil;
    self.deviceFormat = nil;
    self.videoDeviceInput = nil;
    self.videoOutput = nil;
}

-(void)startCapturing
{
    [self.session startRunning];
    
    NSError *error = nil;
    
    if ([self.device lockForConfiguration:&error])
    {
        [self.device setActiveFormat:self.deviceFormat];
        [self.device unlockForConfiguration];
    }
    else
    {
        [self presentError:error];
        NSLog(@"couldn't set format for device");
        return;
    }
    
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

// private
-(void)presentError:(NSError*)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraCapturer:didObtainedError:)])
        [self.delegate cameraCapturer: self didObtainedError: error];
}

// AVCaptureVideoDataOutputSampleBufferDelegate
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
        void *baseAddress = CVPixelBufferGetBaseAddress(videoFrame);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(videoFrame);
        int frameWidth = (int)CVPixelBufferGetWidth(videoFrame);
        int frameHeight = (int)CVPixelBufferGetHeight(videoFrame);
        int frameSize = (int)(bytesPerRow * frameHeight);
        
#if 0
        VideoCaptureCapability tempCaptureCapability;
        tempCaptureCapability.width = _frameWidth;
        tempCaptureCapability.height = _frameHeight;
        tempCaptureCapability.maxFPS = _frameRate;
        tempCaptureCapability.rawType = kVideoBGRA;
#endif
        
        NSData *frameData = [NSData dataWithBytes: baseAddress length: frameSize];
        
        if (_externalCapturer)
            _externalCapturer->incomingArgbFrame(frameWidth, frameHeight,
                                                 (unsigned char*)frameData.bytes, frameSize);
        
        CVPixelBufferUnlockBaseAddress(videoFrame, kFlags);
    }
}

@end


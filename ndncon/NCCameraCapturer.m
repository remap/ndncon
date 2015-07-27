//
//  NCCameraCapturer.m
//  NdnCon
//
//  Created by Peter Gusev on 9/19/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCCameraCapturer.h"

//******************************************************************************
@interface NCCameraCapturer ()

@property (nonatomic) AVCaptureDevice *device;
@property (nonatomic) AVCaptureDeviceFormat *deviceFormat;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;

@end

@implementation NCCameraCapturer

-(id)initWithDevice:(AVCaptureDevice*)device andFormat:(AVCaptureDeviceFormat*)format
{
    self = [super init];
    
    if (self)
    {
        self.device = device;
        self.deviceFormat = format;
        
        NSError *error = nil;
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
            if (![self.device supportsAVCaptureSessionPreset:[self.session sessionPreset]])
                [self.session setSessionPreset:AVCaptureSessionPresetHigh];
            
            [[self session] addInput:newVideoDeviceInput];
            self.videoDeviceInput = newVideoDeviceInput;
        }
        
//        [self initVideoOutput];
    }
    
    return self;
}

-(void)dealloc
{
    self.device = nil;
    self.deviceFormat = nil;
    self.videoDeviceInput = nil;
}

-(void)startCapturing
{
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
    
    [super startCapturing];
}

@end


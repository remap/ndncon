//
//  NCVideoStreamViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "NCVideoStreamViewController.h"
#import "AVCaptureDeviceFormat+NdnConAdditions.h"

NSString* const kDeviceConfigurationKey = @"Device configuration";
NSString* const kFrameRateKey = @"Frame rate";
NSString* const kGopKey = @"GOP";
NSString* const kMaxBitrateKey = @"Max bitrate";
NSString* const kEncodingWidthKey = @"Encoding width";
NSString* const kEncodingHeightKey = @"Encoding height";

@interface NCVideoStreamViewController ()

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (weak) IBOutlet NSView *previewArea;

@end

@implementation NCVideoStreamViewController

- (id)init
{
    self = [self initWithNibName:@"NCVideoStreamView" bundle:nil];
    
    if (self)
    {
        self.session = [[AVCaptureSession alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [self.session stopRunning];
    self.session = nil;
    self.previewLayer = nil;
    self.deviceInput = nil;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    CALayer *previewViewLayer = [self.previewArea layer];
    [previewViewLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
    AVCaptureVideoPreviewLayer *newPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [newPreviewLayer setFrame:[previewViewLayer bounds]];
    [previewViewLayer addSublayer:newPreviewLayer];
    self.previewLayer =newPreviewLayer;

    [self.session startRunning];
}

+(NSDictionary *)defaultVideoStreamConfiguration
{
    return @{
             kNameKey:@"camera",
             kInputDeviceKey:@(0),  // any first device in the list
             kDeviceConfigurationKey:@(-1), // index -1 means last element in array
             kSynchornizedToKey:@(-1),  // index -1 means no synchornization
             kThreadsArrayKey:@[
                     @{
                         kNameKey:@"low",
                         kFrameRateKey:@(30),
                         kGopKey:@(30),
                         kBitrateKey:@(200),
                         kMaxBitrateKey:@(0),
                         kEncodingWidthKey:@(320),
                         kEncodingHeightKey:@(240)
                         },
                     @{
                         kNameKey:@"mid",
                         kFrameRateKey:@(30),
                         kGopKey:@(30),
                         kBitrateKey:@(700),
                         kMaxBitrateKey:@(0),
                         kEncodingWidthKey:@(640),
                         kEncodingHeightKey:@(480)
                         },
                     @{
                         kNameKey:@"hi",
                         kFrameRateKey:@(30),
                         kGopKey:@(30),
                         kBitrateKey:@(1500),
                         kMaxBitrateKey:@(0),
                         kEncodingWidthKey:@(640),
                         kEncodingHeightKey:@(480)
                         },
                     ]
             };
}

-(AVCaptureDevice *)selectedDevice
{
    return [self.deviceInput device];
}

-(void)setSelectedDevice:(AVCaptureDevice *)selectedDevice
{
    [self.session beginConfiguration];
    
    if (self.deviceInput)
    {
        [self.session removeInput:self.deviceInput];
        self.deviceInput = nil;
    }
    
    if (selectedDevice)
    {
        NSError *error = nil;
        AVCaptureDeviceInput *newDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedDevice error:&error];
        
        if (newDeviceInput == nil)
        {
            NSLog(@"error while chosing device: %@", error);
        }
        else
        {
            if (![selectedDevice supportsAVCaptureSessionPreset:self.session.sessionPreset])
                [self.session setSessionPreset:AVCaptureSessionPresetHigh];
            
            [self.session addInput:newDeviceInput];
            self.deviceInput = newDeviceInput;
        }
    }
    
    [self.session commitConfiguration];
}

-(AVCaptureDeviceFormat*)deviceFormat
{
    return [self.selectedDevice activeFormat];
}

-(void)setDeviceFormat:(AVCaptureDeviceFormat *)deviceFormat
{
    NSError *error = nil;
    AVCaptureDevice *device = self.selectedDevice;
    
    if ([device lockForConfiguration:&error])
    {
        [device setActiveFormat:deviceFormat];
        [device unlockForConfiguration];
    }
    else
    {
        NSLog(@"error while configuring device: %@", error);
    }
}

@end

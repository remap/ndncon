//
//  NCVideoStreamViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <ApplicationServices/ApplicationServices.h>

#import "NCVideoStreamViewController.h"
#import "AVCaptureDeviceFormat+NdnConAdditions.h"
#import "NCVideoThreadViewController.h"
#import "NCStackEditorViewController.h"
#import "NSObject+NCAdditions.h"

NSString* const kDeviceConfigurationKey = @"Device configuration";

@interface NCVideoStreamViewController ()

@property (weak) IBOutlet NSView *previewArea;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

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
    [self stopObservingSelf];
    
    self.previewLayer = nil;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    {// setting device
        NSUInteger deviceIdx = [[self.configuration objectForKey:kInputDeviceKey] intValue];
        
        if (deviceIdx < self.preferences.videoDevices.count)
        {
            AVCaptureDevice *device = [self.preferences.videoDevices objectAtIndex:deviceIdx];
            
            if (device)
                [self setSelectedDevice:device];
        }
    }
    
    {// setting device configuration
        if (self.selectedDevice)
        {
            NSInteger configurationIdx = [[self.configuration objectForKey:kDeviceConfigurationKey] intValue];
            
            if (configurationIdx < 0)
                configurationIdx = self.selectedDevice.formats.count-1;
            
            if (configurationIdx < self.selectedDevice.formats.count)
            {
                AVCaptureDeviceFormat *format = [self.selectedDevice.formats objectAtIndex:configurationIdx];
                
                if (format)
                    [self setDeviceFormat:format];
            }
        }
    }
    
    { // set preview layer
        CALayer *previewViewLayer = [self.previewArea layer];
        [previewViewLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
        
        AVCaptureVideoPreviewLayer *newPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        [newPreviewLayer setFrame:[previewViewLayer bounds]];
        [previewViewLayer addSublayer:newPreviewLayer];
        
        self.previewLayer =newPreviewLayer;
        [self.session startRunning];
    }
    
    { // adding thread controllers
        for (NSDictionary *threadConfigruation in [self.configuration objectForKey:kThreadsArrayKey])
        {
            [self addThreadControllerForThread:threadConfigruation];
        }
    }
    
    [self startObservingSelf];
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

-(void)setSelectedDevice:(AVCaptureDevice *)selectedDevice
{
    [super setSelectedDevice:selectedDevice];
    
    NSUInteger deviceIdx = [self.preferences.videoDevices indexOfObject:selectedDevice];
    [self.configuration setValue:@(deviceIdx) forKeyPath:kInputDeviceKey];
}

-(void)setDeviceFormat:(AVCaptureDeviceFormat *)deviceFormat
{
    [super setDeviceFormat:deviceFormat];
    
    NSUInteger configurationIdx = [self.selectedDevice.formats indexOfObject:deviceFormat];
    [self.configuration setValue:@(configurationIdx) forKeyPath:kDeviceConfigurationKey];
}

- (IBAction)addThread:(id)sender
{
    [self addThreadControllerForThread:[self addNewThread]];
}

// override
-(Class)threadViewControllerClass
{
    return [NCVideoThreadViewController class];
}

-(void)startObservingSelf
{
    [super startObservingSelf];
    
    [self addObserver:self forKeyPaths:
     KEYPATH2(configuration, kDeviceConfigurationKey),
     nil];
}

-(void)stopObservingSelf
{
    [self removeObserver:self forKeyPaths:
     KEYPATH2(configuration, kDeviceConfigurationKey),
     nil];
    
    [super stopObservingSelf];
}

// private
-(NSMutableDictionary*)addNewThread
{
    NSMutableArray *threads = [NSMutableArray arrayWithArray:[self.configuration objectForKey:kThreadsArrayKey]];
    NSString *threadName = [NSString stringWithFormat:@"thread-%lu",
                            threads.count+1];
    NSMutableDictionary *threadConfguration = [NSMutableDictionary dictionaryWithDictionary:[NCVideoThreadViewController defaultVideoThreadConfiguration]];
    
    [threadConfguration setObject:threadName forKey:kNameKey];
    [threads addObject:threadConfguration];
    [self.configuration setObject:threads forKey:kThreadsArrayKey];
    
    return threadConfguration;
}

@end

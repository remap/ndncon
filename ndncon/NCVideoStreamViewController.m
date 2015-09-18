//
//  NCVideoStreamViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <AVFoundation/AVFoundation.h>
#import <ApplicationServices/ApplicationServices.h>

#import "NCVideoStreamViewController.h"
#import "AVCaptureDeviceFormat+NdnConAdditions.h"
#import "NCVideoThreadViewController.h"
#import "NCStackEditorViewController.h"
#import "NSObject+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"
#import "NSArray+NCAdditions.h"

NSString* const kDeviceConfigurationKey = @"Device configuration";

@interface NCVideoStreamViewController ()

@property (weak) IBOutlet NSView *previewArea;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, readonly) NSArray *captureDevices;

@end

@implementation NCVideoStreamViewController

- (id)init
{
    self = [self initWithNibName:@"NCVideoStreamView" bundle:nil];
    
    if (self)
    {
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
        NSInteger deviceIdx = [[self.configuration objectForKey:kInputDeviceKey] intValue];
        
        if (deviceIdx < 0)
        {
            NSScreen *mainScreen = [NSScreen mainScreen];
            [self setSelectedDevice:mainScreen];
        }
        else
            if (deviceIdx < self.preferences.videoDevices.count)
            {
                AVCaptureDevice *device = [self.preferences.videoDevices objectAtIndex:deviceIdx];
                
                if (device)
                    [self setSelectedDevice:device];
            }
    }
    
    {// setting device configuration
        if (self.selectedDevice && [self.selectedDevice isKindOfClass:[AVCaptureDevice class]])
        {
            NSInteger configurationIdx = [[self.configuration objectForKey:kDeviceConfigurationKey] intValue];
            
            if (configurationIdx < 0)
                configurationIdx = ((AVCaptureDevice*)self.selectedDevice).formats.count-1;
            
            if (configurationIdx < ((AVCaptureDevice*)self.selectedDevice).formats.count)
            {
                AVCaptureDeviceFormat *format = [((AVCaptureDevice*)self.selectedDevice).formats objectAtIndex:configurationIdx];
                
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
    
    [self startObservingSelf];
}

+(NSDictionary *)defaultConfguration
{
    return @{
             kNameKey:@"camera",
             kSegmentSizeKey: @(1000),
             kFreshnessPeriodKey: @(1000),
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

+(NSDictionary *)defaultScreenConfguration
{
    NSScreen *mainDisplay = [NCPreferencesController sharedInstance].activeDisplays[0];
    
    return @{
             kNameKey:@"desktop",
             kSegmentSizeKey: @(1000),
             kFreshnessPeriodKey: @(1000),
             kInputDeviceKey:@(-[[mainDisplay deviceDescription][@"NSScreenNumber"] intValue]),  // any first device in the list
             kDeviceConfigurationKey:@(-1), // index -1 means last element in array
             kSynchornizedToKey:@(-1),  // index -1 means no synchornization
             kThreadsArrayKey:@[
                     @{
                         kNameKey:@"low",
                         kFrameRateKey:@(30),
                         kGopKey:@(30),
                         kBitrateKey:@(500),
                         kMaxBitrateKey:@(0),
                         kEncodingWidthKey:@(800),
                         kEncodingHeightKey:@(500)
                         },
                     @{
                         kNameKey:@"mid",
                         kFrameRateKey:@(30),
                         kGopKey:@(30),
                         kBitrateKey:@(700),
                         kMaxBitrateKey:@(0),
                         kEncodingWidthKey:@(1024),
                         kEncodingHeightKey:@(640)
                         },
                     @{
                         kNameKey:@"hi",
                         kFrameRateKey:@(30),
                         kGopKey:@(30),
                         kBitrateKey:@(1100),
                         kMaxBitrateKey:@(0),
                         kEncodingWidthKey:@(1280),
                         kEncodingHeightKey:@(800)
                         },
                     ]
             };
}

-(NSArray *)captureDevices
{
    NSMutableArray *devices = [NSMutableArray array];
    [self.preferences.activeDisplays enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [devices addObject:@{@"device":obj, @"name":[NSString stringWithFormat:@"Screen %lu", idx]}];
    }];
    [self.preferences.videoDevices enumerateObjectsUsingBlock:^(AVCaptureDevice *device, NSUInteger idx, BOOL *stop) {
        [devices addObject:@{@"device":device, @"name":device.localizedName}];
    }];

    return [NSArray arrayWithArray:devices];
}

-(void)setSelectedDevice:(id)selectedDevice
{
    [super setSelectedDevice:selectedDevice];
    
    if ([selectedDevice isKindOfClass:[NSScreen class]])
    {
        NSScreen *screen = selectedDevice;
        NSInteger deviceIdx = [screen.deviceDescription[@"NSScreenNumber"] intValue];
        
        // screens are negative in stream configurations
        deviceIdx = -deviceIdx;
        [self.configuration setValue:@(deviceIdx) forKey:kInputDeviceKey];
    }
    else
    {
        NSInteger deviceIdx = ([self.preferences.videoDevices containsObject:selectedDevice])?[self.preferences.videoDevices indexOfObject:selectedDevice]:-1;
        
        if (deviceIdx < 0)
        {
            NSLog(@"video device was not found. falling back to deafult");
            deviceIdx = 0;
        }
        
        [self.configuration setValue:@(deviceIdx) forKeyPath:kInputDeviceKey];
    }
}

-(void)setDeviceFormat:(AVCaptureDeviceFormat *)deviceFormat
{
    [super setDeviceFormat:deviceFormat];
    
    NSInteger configurationIdx = ([((AVCaptureDevice*)self.selectedDevice).formats containsObject:deviceFormat])?[((AVCaptureDevice*)self.selectedDevice).formats indexOfObject:deviceFormat]:-1;
    
    if (configurationIdx < 0)
    {
        NSLog(@"video device format was not found. falling back to deafult");
        configurationIdx = ((AVCaptureDevice*)self.selectedDevice).formats.count-1;
    }
    
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
    NSMutableArray *threads = [(NSArray*)[self.configuration objectForKey:kThreadsArrayKey] deepMutableCopy];
    NSString *threadName = [NSString stringWithFormat:@"thread-%lu",
                            threads.count+1];
    NSMutableDictionary *threadConfguration = [[NCVideoThreadViewController defaultConfiguration] deepMutableCopy];
    
    [threadConfguration setObject:threadName forKey:kNameKey];
    [threads addObject:threadConfguration];
    [self.configuration setObject:threads forKey:kThreadsArrayKey];
    
    return threadConfguration;
}

@end

//
//  NCAudioStreamViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NCAudioStreamViewController.h"
#import "NCThreadViewController.h"
#import "NCAudioThreadViewController.h"
#import "NSDictionary+NCAdditions.h"
#import "NSArray+NCAdditions.h"

@interface NCAudioStreamViewController ()

@property (weak) IBOutlet NSLevelIndicator *audioLevelMeter;

@property (nonatomic, strong) AVCaptureAudioPreviewOutput *audioPreviewOutput;
@property (nonatomic, strong) NSTimer *audioLevelTimer;

@end

@implementation NCAudioStreamViewController

-(id)init
{
    self = [self initWithNibName:@"NCAudioStreamView" bundle:nil];
    
    if (self)
    {
    }
    
    return self;
}

-(void)dealloc
{
    [self stopObservingSelf];
    self.audioPreviewOutput = nil;
    [self.audioLevelTimer invalidate];
    self.audioLevelTimer = nil;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    { // setting device
        NSUInteger deviceIdx = [[self.configuration objectForKey:kInputDeviceKey] intValue];
        
        if (deviceIdx < self.preferences.audioDevices.count)
        {
            AVCaptureDevice *device = [self.preferences.audioDevices objectAtIndex:deviceIdx];
            
            if (device)
                [self setSelectedDevice:device];
        }
    }
    
    { // set session
        self.audioPreviewOutput = [[AVCaptureAudioPreviewOutput alloc] init];
        [self.audioPreviewOutput setVolume:0.f];
        [self.session addOutput:self.audioPreviewOutput];
        [self.session startRunning];
    }
    
    { // set audio level preview
        self.audioLevelTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateAudioLevels:) userInfo:nil repeats:YES];
    }
    
    [self startObservingSelf];
}

+(NSDictionary*)defaultConfguration
{
    return @{
             kNameKey:@"mic",
             kSegmentSizeKey: @(500),
             kFreshnessPeriodKey: @(1000),
             kInputDeviceKey:@(0),  // any first device in the list
             kSynchornizedToKey:@(-1),  // index -1 means no synchornization
             kThreadsArrayKey:@[
                     [NCAudioThreadViewController defaultConfiguration]
                     ]};
}

-(void)setSelectedDevice:(AVCaptureDevice *)selectedDevice
{
    [super setSelectedDevice:selectedDevice];
    
    NSInteger deviceIdx = ([self.preferences.audioDevices containsObject:selectedDevice])?
    [self.preferences.audioDevices indexOfObject:selectedDevice] : -1;
    
    if (deviceIdx < 0)
    {
        NSLog(@"audio device was not found. falling back to default");
        deviceIdx = 0;
    }
    
    [self.configuration setValue:@(deviceIdx) forKeyPath:kInputDeviceKey];
}

- (IBAction)addThread:(id)sender {
    [self addThreadControllerForThread:[self addNewThread]];
}

// override
-(Class)threadViewControllerClass
{
    return [NCAudioThreadViewController class];
}

// private
- (void)updateAudioLevels:(NSTimer *)timer
{
    NSInteger channelCount = 0;
    float decibels = 0.f;
    
    // Sum all of the average power levels and divide by the number of channels
    for (AVCaptureConnection *connection in [self.audioPreviewOutput connections]) {
        for (AVCaptureAudioChannel *audioChannel in [connection audioChannels]) {
            decibels += [audioChannel averagePowerLevel];
            channelCount += 1;
        }
    }
    
    decibels /= channelCount;
    
    [self.audioLevelMeter setFloatValue:(pow(10.f, 0.05f * decibels) * 20.0f)];
}

-(NSMutableDictionary*)addNewThread
{
    NSMutableArray *threads = [(NSArray*)[self.configuration objectForKey:kThreadsArrayKey] deepMutableCopy];
    NSString *threadName = [NSString stringWithFormat:@"mic-%lu", threads.count+1];
    NSMutableDictionary *threadConfiguration = [[NCAudioThreadViewController defaultConfiguration] deepMutableCopy];
    
    [threadConfiguration setObject:threadName forKey:kNameKey];
    [threads addObject:threadConfiguration];
    [self.configuration setObject:threads forKey:kThreadsArrayKey];
    
    return threadConfiguration;
}

@end

//
//  NCStreamViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamViewController.h"
#import "NCThreadViewController.h"
#import "NCVideoStreamViewController.h"
#import "NCAudioStreamViewController.h"
#import "NSDictionary+NCAdditions.h"
#import "NSObject+NCAdditions.h"
#import "NSScrollView+NCAdditions.h"

NSString* const kNameKey = @"Name";
NSString* const kSynchornizedToKey = @"Synchronized to";
NSString* const kInputDeviceKey = @"Input device";
NSString* const kThreadsArrayKey = @"Threads";

@interface NCStreamViewController ()
{
    NSString *_streamName;
    NCPreferencesController *_preferences;
}

@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;

@end

@implementation NCStreamViewController

+(NSDictionary*)defaultConfguration
{
    return nil;
}

-(id)initWithPreferences:(NCPreferencesController*)preferences andName:(NSString *)streamName
{
    self = [self init];
    
    if (self)
    {
        _streamName = streamName;
        _preferences = preferences;
        self.stackEditor = [[NCStackEditorViewController alloc] init];
        self.stackEditor.delegate = self;
        self.threadControllers = [NSMutableArray array];
        self.session = [[AVCaptureSession alloc] init];
    }
    
    return self;
}

-(void)dealloc
{
    self.threadControllers = nil;
    
    [self.session stopRunning];
    self.session = nil;
    self.deviceInput = nil;
}

-(void)awakeFromNib
{
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
    [self.scrollView addStackView:self.stackEditor.stackView
                  withOrientation:NSUserInterfaceLayoutOrientationHorizontal];
    
    { // adding thread controllers
        for (NSDictionary *threadConfiguration in [self.configuration objectForKey:kThreadsArrayKey])
            [self addThreadControllerForThread:threadConfiguration];
    }
}

-(NSMutableDictionary *)configuration
{
    return [self getConfigurationFromDelegate];
}

-(NSString *)streamName
{
    return _streamName;
}

-(void)setStreamName:(NSString *)streamName
{
    [self.configuration setObject:streamName forKey:kNameKey];
    _streamName = streamName;
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

-(Class)threadViewControllerClass
{
    @throw @"Unimplemented";
}

-(NCThreadViewController*)addThreadControllerForThread:(NSDictionary*)threadConfiguration
{
    NCThreadViewController *threadViewController = [[[self threadViewControllerClass] alloc]
                                                         initWithStream:self
                                                         andName:[threadConfiguration valueForKey:kNameKey]];
    threadViewController.delegate = self;
    [self.threadControllers addObject:threadViewController];
    
    NCStackEditorEntryViewController *entryViewController = [self.stackEditor addViewControllerEntry:threadViewController];
    [entryViewController setHeaderSmall:YES];
    [entryViewController.captionLabel bind:@"displayPatternValue1"
                                  toObject:threadViewController
                               withKeyPath:NSStringFromSelector(@selector(threadName))
                                   options:@{NSDisplayPatternBindingOption:@"Thread: %{value1}@"}];
    
    [self setStackEntry:entryViewController newCaption:threadViewController.threadName];
    
    return threadViewController;
}

-(NSArray *)pairedStreams
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamViewControllerQueriedPairedStreams:)])
        return [self.delegate streamViewControllerQueriedPairedStreams:self];
    
    return nil;
}

-(void)setSynchronizedStreamName:(NSString *)synchronizedStreamName
{
    [self.configuration setValue:synchronizedStreamName forKey:kSynchornizedToKey];
}

-(NSString *)synchronizedStreamName
{
    return [self.configuration valueForKeyPath:kSynchornizedToKey];
}

// delegate NCStackEditorEntryDelegate
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    // remove thread controller with view equals entry's contentView
    NCThreadViewController *threadControllerForDeletion = nil;
    
    for (NCThreadViewController *threadVc in self.threadControllers)
    {
        if (threadVc == vc.contentViewController)
        {
            threadControllerForDeletion = threadVc;
            break;
        }
    }
    
    if (threadControllerForDeletion)
    {
        NSIndexSet *index = [[self.configuration objectForKey:kThreadsArrayKey] indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [[(NSDictionary*)obj valueForKey:kNameKey] isEqualTo:threadControllerForDeletion.threadName];
        }];
        
        [[self.configuration objectForKey:kThreadsArrayKey] removeObjectsAtIndexes:index];
        [self.threadControllers removeObject:threadControllerForDeletion];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(configurationDidChangeForObject:atKeyPath:change:)])
            [self.delegate configurationDidChangeForObject:self atKeyPath:kThreadsArrayKey change:nil];
    }
}

// KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(configurationDidChangeForObject:atKeyPath:change:)])
            [self.delegate configurationDidChangeForObject:self atKeyPath:keyPath change:change];
    }
}

// NCConfigurationObserver
-(void)configurationDidChangeForObject:(id)object atKeyPath:(NSString *)keyPath change:(NSDictionary *)change
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(configurationDidChangeForObject:atKeyPath:change:)])
    {
        [self.delegate configurationDidChangeForObject:self
                                             atKeyPath:KEYPATH2(configuration, kThreadsArrayKey)
                                                change:nil];
    }
}

// override
-(void)startObservingSelf
{
    [self addObserver:self
          forKeyPaths:
     KEYPATH2(configuration, kNameKey),
     KEYPATH2(configuration, kSynchornizedToKey),
     KEYPATH2(configuration, kInputDeviceKey),
     KEYPATH2(configuration, kThreadsArrayKey),
     nil];
}

-(void)stopObservingSelf
{
    [self removeObserver:self
             forKeyPaths:
     KEYPATH2(configuration, kNameKey),
     KEYPATH2(configuration, kSynchornizedToKey),
     KEYPATH2(configuration, kInputDeviceKey),
     KEYPATH2(configuration, kThreadsArrayKey),
     nil];
}

// private
-(void)setStackEntry:(NCStackEditorEntryViewController*)stackEntryVc newCaption:(NSString*)caption
{
    stackEntryVc.caption = [NSString stringWithFormat:@"Thread: %@", caption];
}

-(NSMutableDictionary*)getConfigurationFromDelegate
{
    __block NSMutableDictionary *streamConfiguration = nil;
    NSArray *streamArray = [self.delegate streamViewControllerQueriedForStreamArray:self];

    [streamArray enumerateObjectsUsingBlock:^(NSMutableDictionary *configuration, NSUInteger idx, BOOL *stop) {
        if ([[configuration objectForKey:kNameKey] isEqualTo:_streamName])
        {
            streamConfiguration = configuration;
            *stop = YES;
        }
    }];
    
    return streamConfiguration;
}

@end

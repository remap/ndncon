//
//  NCStreamEditorViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamEditorViewController.h"
#import "NCStreamViewController.h"
#import "NCThreadViewController.h"
#import "NCVideoStreamViewController.h"
#import "NCAudioStreamViewController.h"
#import "NCPreferencesController.h"
#import "NSDictionary+NCAdditions.h"
#import "NSArray+NCAdditions.h"
#include "NSObject+NCAdditions.h"

@interface NCStreamEditorViewController ()

@property (nonatomic) NSMutableArray *streamsControllers;
@property (nonatomic, strong) NCPreferencesController *preferences;
@property (nonatomic) NSMutableArray *audioStreams;
@property (nonatomic) NSMutableArray *videoStreams;

@end

@implementation NCStreamEditorViewController

- (id)initWithPreferncesController:(NCPreferencesController *)preferences
{
    if ((self = [super init]))
    {
        self.preferences = preferences;
        self.audioStreams = [preferences.audioStreams deepMutableCopy];
        self.videoStreams = [preferences.videoStreams deepMutableCopy];
        self.streamsControllers = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)dealloc
{
    self.streamsControllers = nil;
    self.preferences = nil;
}

-(void)awakeFromNib
{
    for (NSDictionary *audioStream in self.preferences.audioStreams)
        [self addNewAudioStreamControllerForStream:audioStream];
    
    for (NSDictionary *videoStream in self.preferences.videoStreams)
        [self addNewVideoStreamControllerForStream:videoStream];
}

-(void)addVideoStream:(NSDictionary *)defaultConfiguration
{
    NSMutableDictionary *streamConfiguration = [defaultConfiguration deepMutableCopy];
    
    if ([self checkStreamNameExists:[streamConfiguration valueForKeyPath:kNameKey]])
    {
        [streamConfiguration setValue:[NSString stringWithFormat:@"%@-%lu",
                                       [streamConfiguration valueForKeyPath:kNameKey],
                                       (unsigned long)[self getNumberOfStreamsForType:[NCVideoStreamViewController class]]]
                               forKey:kNameKey];
    }
    
    [self addNewVideoStream:streamConfiguration];
    [self addNewVideoStreamControllerForStream:streamConfiguration];
}

-(void)addAudioStream:(NSDictionary *)defaultConfiguration
{
    NSMutableDictionary *streamConfiguration = [defaultConfiguration deepMutableCopy];
    
    if ([self checkStreamNameExists:[streamConfiguration valueForKeyPath:kNameKey]])
    {
        [streamConfiguration setValue:[NSString stringWithFormat:@"%@-%lu",
                                       [streamConfiguration valueForKeyPath:kNameKey],
                                       (unsigned long)[self getNumberOfStreamsForType:[NCAudioStreamViewController class]]]
                               forKey:kNameKey];
    }
    
    [self addNewAudioStream:streamConfiguration];
    [self addNewAudioStreamControllerForStream:streamConfiguration];
}

-(void)setStackEntry:(NCStackEditorEntryViewController*)stackEntryVc newCaption:(NSString*)caption
{
    stackEntryVc.caption = [NSString stringWithFormat:@"Stream: %@", caption];
}

-(BOOL)checkStreamNameExists:(NSString*)streamName
{
    for (NCStreamViewController *streamViewController in self.streamsControllers)
        if ([streamName isEqualTo:[streamViewController valueForKeyPath:KEYPATH2(configuration, kNameKey)]])
            return YES;
    
    return NO;
}

-(NSUInteger)getNumberOfStreamsForType:(Class)streamControllerType
{
    NSUInteger nStreams = 0;
    
    for (NCStreamViewController *controller in self.streamsControllers)
        if ([controller isKindOfClass:streamControllerType])
            nStreams++;
    
    return nStreams;
}

// NCConfigurationObserverDelegate
-(void)configurationDidChangeForObject:(id)object atKeyPath:(NSString *)keyPath change:(NSDictionary *)change
{
    NSLog(@"saving change %@ for %@", keyPath, object);
    
    if ([object isKindOfClass:[NCVideoStreamViewController class]])
        self.preferences.videoStreams = self.videoStreams;
    
    if ([object isKindOfClass:[NCAudioStreamViewController class]])
        self.preferences.audioStreams = self.audioStreams;
}

// NCStreamViewControllerDelegate
-(NSArray*)streamViewControllerQueriedForStreamArray:(NCStreamViewController *)streamVc
{
    if ([streamVc isKindOfClass:[NCVideoStreamViewController class]])
        return self.videoStreams;
    
    if ([streamVc isKindOfClass:[NCAudioStreamViewController class]])
        return self.audioStreams;
    
    return nil;
}

// stack editor delegate
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    [super stackEditorEntryViewControllerDidClosed:vc];
    
    NCStreamViewController *controllerForDeletion = nil;
    // remove stream corresponding stream controller
    for (NCStreamViewController *streamController in self.streamsControllers)
    {
        if (streamController.view == vc.contentView)
        {
            controllerForDeletion = streamController;
            break;
        }
    }
    
    if (controllerForDeletion)
    {
        [self.streamsControllers removeObject:controllerForDeletion];
        
        if ([controllerForDeletion isKindOfClass:[NCVideoStreamViewController class]])
            [self removeVideoStreamWithName:controllerForDeletion.streamName];
        else
            [self removeAudioStreamWithName:controllerForDeletion.streamName];
        
    }
}

// private
-(void)addNewVideoStreamControllerForStream:(NSDictionary*)streamConfiguration
{
    [self addNewStreamControllerWithClass:[NCVideoStreamViewController class]
                                forStream:streamConfiguration];
}

-(void)addNewAudioStreamControllerForStream:(NSDictionary*)streamConfiguration
{
    [self addNewStreamControllerWithClass:[NCAudioStreamViewController class]
                                forStream:streamConfiguration];
}

-(void)addNewStreamControllerWithClass:(Class)StreamControllerClass
                             forStream:(NSDictionary*)streamConfiguration
{
    NCStreamViewController *streamViewController = [[StreamControllerClass alloc]
                                                              initWithPreferences:self.preferences
                                                              andName:[streamConfiguration valueForKeyPath:kNameKey]];
    streamViewController.delegate = self;
    
    [self.streamsControllers addObject:streamViewController];
    
    NCStackEditorEntryViewController *stackEntryVc = [self addViewEntry:streamViewController.view];
    [self setStackEntry:stackEntryVc newCaption:[streamViewController valueForKeyPath:KEYPATH2(configuration, kNameKey)]];
    [stackEntryVc.captionLabel bind:@"displayPatternValue1"
                           toObject:streamViewController
                        withKeyPath:NSStringFromSelector(@selector(streamName))
                            options:@{NSDisplayPatternBindingOption:@"Stream: %{value1}@"}];
}

-(void)addNewVideoStream:(NSDictionary*)configuration
{
    [self.videoStreams addObject:configuration];
    self.preferences.videoStreams = self.videoStreams;
}

-(void)addNewAudioStream:(NSDictionary*)configuration
{
    [self.audioStreams addObject:configuration];
    self.preferences.audioStreams = self.audioStreams;
}

-(void)removeVideoStreamWithName:(NSString*)streamName
{
    NSDictionary *streamForDeletion = nil;
    
    for (NSDictionary *stream in self.videoStreams)
        if ([[stream valueForKey:kNameKey] isEqualTo: streamName])
            streamForDeletion = stream;
    
    [self.videoStreams removeObject:streamForDeletion];
    self.preferences.videoStreams = self.videoStreams;
}

-(void)removeAudioStreamWithName:(NSString*)streamName
{
    NSDictionary *streamForDeletion = nil;
    
    for (NSDictionary *stream in self.audioStreams)
        if ([[stream valueForKey:kNameKey] isEqualTo: streamName])
            streamForDeletion = stream;
    
    [self.audioStreams removeObject:streamForDeletion];
    self.preferences.audioStreams = self.audioStreams;
}

@end

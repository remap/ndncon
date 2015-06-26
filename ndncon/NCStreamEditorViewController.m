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

@end

@implementation NCStreamEditorViewController

- (id)initWithPreferencesController:(NCPreferencesController *)preferences
{
    if ((self = [super init]))
    {
        self.audioStreamViewControllerClass = [NCAudioStreamViewController class];
        self.videoStreamViewControllerClass = [NCVideoStreamViewController class];
        
        self.preferences = preferences;
        _audioStreams = [preferences.audioStreams deepMutableCopy];
        _videoStreams = [preferences.videoStreams deepMutableCopy];
        self.streamsControllers = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)dealloc
{
    self.streamsControllers = nil;
    self.preferences = nil;
}

-(void)setAudioStreams:(NSArray *)audioStreams andVideoStreams:(NSArray*)videoStreams
{
    [self removeAllEntries];
    
    _audioStreams = [audioStreams deepMutableCopy];
    _videoStreams = [videoStreams deepMutableCopy];
    
    [self loadViewsForAudioStreams:_audioStreams andVideoStreams:_videoStreams];
}

-(void)addVideoStream:(NSDictionary *)defaultConfiguration
{
    NSMutableDictionary *streamConfiguration = [defaultConfiguration deepMutableCopy];
    
    if ([self checkStreamNameExists:[streamConfiguration valueForKeyPath:kNameKey]])
    {
        [streamConfiguration setValue:[NSString stringWithFormat:@"%@-%lu",
                                       [streamConfiguration valueForKeyPath:kNameKey],
                                       (unsigned long)[self getNumberOfStreamsForType:self.videoStreamViewControllerClass]]
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
                                       (unsigned long)[self getNumberOfStreamsForType:self.audioStreamViewControllerClass]]
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
    
    if ([object isKindOfClass:self.videoStreamViewControllerClass])
        self.preferences.videoStreams = self.videoStreams;
    
    if ([object isKindOfClass:self.audioStreamViewControllerClass])
        self.preferences.audioStreams = self.audioStreams;
}

// NCStreamViewControllerDelegate
-(NSArray*)streamViewControllerQueriedForStreamArray:(NCStreamViewController *)streamVc
{
    if ([streamVc isKindOfClass:self.videoStreamViewControllerClass])
        return self.videoStreams;
    
    if ([streamVc isKindOfClass:self.audioStreamViewControllerClass])
        return self.audioStreams;
    
    return nil;
}

-(NSArray *)streamViewControllerQueriedPairedStreams:(NCStreamViewController *)streamVc
{
    NSMutableArray *streamViewControllers = [NSMutableArray arrayWithObject:@{@"streamName":@"-"}];
    
    for (NCStreamViewController *vc in self.streamsControllers)
        if (![vc isKindOfClass:[streamVc class]])
            [streamViewControllers addObject:vc];
    
    return streamViewControllers;
}

// stack editor delegate
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    [super stackEditorEntryViewControllerDidClosed:vc];
    
    NCStreamViewController *controllerForDeletion = nil;
    // remove stream corresponding stream controller
    for (NCStreamViewController *streamController in self.streamsControllers)
    {
        if (streamController == vc.contentViewController)
        {
            controllerForDeletion = streamController;
            break;
        }
    }
    
    if (controllerForDeletion)
    {
        [self.streamsControllers removeObject:controllerForDeletion];
        
        if ([controllerForDeletion isKindOfClass:self.videoStreamViewControllerClass])
            [self removeVideoStreamWithName:controllerForDeletion.streamName];
        else
            [self removeAudioStreamWithName:controllerForDeletion.streamName];
        
    }
}

// private
-(void)loadViewsForAudioStreams:(NSArray*)audioStreams andVideoStreams:(NSArray*)videoStreams
{
    for (NSDictionary *audioStream in audioStreams)
        [self addNewAudioStreamControllerForStream:audioStream];
    
    for (NSDictionary *videoStream in videoStreams)
        [self addNewVideoStreamControllerForStream:videoStream];
}

-(void)addNewVideoStreamControllerForStream:(NSDictionary*)streamConfiguration
{
    [self addNewStreamControllerWithClass:self.videoStreamViewControllerClass
                                forStream:streamConfiguration];
}

-(void)addNewAudioStreamControllerForStream:(NSDictionary*)streamConfiguration
{
    [self addNewStreamControllerWithClass:self.audioStreamViewControllerClass
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
    
    NCStackEditorEntryViewController *stackEntryVc = [self addViewControllerEntry:streamViewController];
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

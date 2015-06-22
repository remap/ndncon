//
//  NCStreamViewerController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/7/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamViewerController.h"
#import "NCUserStreamViewController.h"
#import "NSArray+NCAdditions.h"

@interface NCStreamViewerController ()

@property (nonatomic) NSMutableArray *streamsControllers;

@end

@implementation NCStreamViewerController

- (id)init
{
    if ((self = [super init]))
    {
        _audioStreams = [NSMutableArray array];
        _videoStreams = [NSMutableArray array];
        self.streamsControllers = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)dealloc
{
    self.streamsControllers = nil;
}

-(void)setAudioStreams:(NSArray *)audioStreams andVideoStreams:(NSArray *)videoStreams
{
    [self removeAllEntries];
    
    _audioStreams = [audioStreams deepMutableCopy];
    _videoStreams = [videoStreams deepMutableCopy];
    
    [self loadViewsForAudioStreams:_audioStreams andVideoStreams:_videoStreams];
 
}

// NCStreamViewControllerDelegate
-(NSArray*)streamViewControllerQueriedForStreamArray:(NCStreamViewController *)streamVc
{
    if ([streamVc isKindOfClass:[NCVideoUserStreamViewController class]])
        return self.videoStreams;
    
    if ([streamVc isKindOfClass:[NCAudioUserStreamViewController class]])
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
    [self addNewStreamControllerWithClass:[NCVideoUserStreamViewController class]
                                forStream:streamConfiguration];
}

-(void)addNewAudioStreamControllerForStream:(NSDictionary*)streamConfiguration
{
    [self addNewStreamControllerWithClass:[NCAudioUserStreamViewController class]
                                forStream:streamConfiguration];
}

-(void)addNewStreamControllerWithClass:(Class)StreamControllerClass
                             forStream:(NSDictionary*)streamConfiguration
{
    NCUserStreamViewController *streamViewController = [[StreamControllerClass alloc]
                                                        initWithPreferences:nil
                                                        andName:[streamConfiguration valueForKeyPath:kNameKey]];
    streamViewController.userName = self.userName;
    streamViewController.userPrefix = self.userPrefix;
    streamViewController.delegate = self;
    
    [self.streamsControllers addObject:streamViewController];
    
    NCStackEditorEntryViewController *stackEntryVc = [self addViewControllerEntry:streamViewController];
    stackEntryVc.caption = [NSString stringWithFormat:@"Stream: %@", [streamViewController valueForKeyPath:KEYPATH2(configuration, kNameKey)]];
    [stackEntryVc.captionLabel bind:@"displayPatternValue1"
                           toObject:streamViewController
                        withKeyPath:NSStringFromSelector(@selector(streamName))
                            options:@{NSDisplayPatternBindingOption:@"Stream: %{value1}@"}];
}

@end

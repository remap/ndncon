//
//  NCStreamEditorViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamEditorViewController.h"
#import "NCStreamViewController.h"
#import "NCVideoStreamViewController.h"
#import "NCPreferencesController.h"

@interface NCStreamEditorViewController ()

@property (nonatomic) NSMutableArray *streamsControllers;

@end

@implementation NCStreamEditorViewController

- (id)init
{
    if ((self = [super init]))
    {
        self.streamsControllers = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)addVideoStream:(NSDictionary *)defaultConfiguration
{
    NCVideoStreamViewController *videoStreamViewController = [[NCVideoStreamViewController alloc] init];
    videoStreamViewController.preferences = [NCPreferencesController sharedInstance];
    videoStreamViewController.configuration = [NSMutableDictionary dictionaryWithDictionary:defaultConfiguration];
    
    if ([self checkStreamNameExists:videoStreamViewController.streamName])
    {
        videoStreamViewController.streamName = [NSString stringWithFormat:@"%@-%lu",
                                                videoStreamViewController.streamName,
                                                (unsigned long)[self getNumberOfStreamsForType:[NCVideoStreamViewController class]]];
    }
    
    [self.streamsControllers addObject:videoStreamViewController];

    NCStackEditorEntryViewController *stackEntryVc = [self addViewEntry:videoStreamViewController.view];
    [self setStackEntry:stackEntryVc newCaption:[videoStreamViewController valueForKeyPath:@"configuration.Name"]];
    
    [videoStreamViewController addObserver:self
                   forKeyPath:@"configuration.Name"
                                   options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                   context:(__bridge void *)(stackEntryVc)];
}

-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    [super stackEditorEntryViewControllerDidClosed:vc];
    
    NSViewController *controllerForDeletion = nil;
    // remove stream corresponding stream controller
    for (NSViewController *streamController in self.streamsControllers)
    {
        if (streamController.view == vc.contentView)
        {
            controllerForDeletion = streamController;
            break;
        }
    }
    
    if (controllerForDeletion)
    {
        [controllerForDeletion removeObserver:self forKeyPath:@"configuration.Name"];
        [self.streamsControllers removeObject:controllerForDeletion];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualTo:@"configuration.Name"])
    {
        NSArray *streamNames = [self.streamsControllers valueForKeyPath:@"streamName"];
        NSIndexSet *equals = [streamNames indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [obj isEqual:[change objectForKey:NSKeyValueChangeNewKey]];
        }];
        
        if (equals.count > 1)
        {
            [(NSSound*)[NSSound soundNamed:@"Basso"] play];
        }
        else
        {
            NCStackEditorEntryViewController *stackEntryViewController = (__bridge NCStackEditorEntryViewController *)(context);
            [self setStackEntry:stackEntryViewController newCaption:[change objectForKey:NSKeyValueChangeNewKey]];
        }
    }
}

-(void)setStackEntry:(NCStackEditorEntryViewController*)stackEntryVc newCaption:(NSString*)caption
{
    stackEntryVc.caption = [NSString stringWithFormat:@"Stream: %@", caption];
}

-(BOOL)checkStreamNameExists:(NSString*)streamName
{
    for (NCStreamViewController *streamViewController in self.streamsControllers)
        if ([streamName isEqualTo:[streamViewController valueForKeyPath:@"configuration.Name"]])
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


@end

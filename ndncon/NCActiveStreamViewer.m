//
//  NCActiveStreamViewer.m
//  NdnCon
//
//  Created by Peter Gusev on 9/26/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCActiveStreamViewer.h"
#import "NCBlockDrawableView.h"
#import "NSString+NCAdditions.h"
#import "NCUserListViewController.h"
#import "NCStreamViewController.h"
#import "NCVideoThreadViewController.h"
#import "NCNdnRtcLibraryController.h"
#import "NCErrorController.h"
#import "NSTimer+NCAdditions.h"

//******************************************************************************
@interface NCActiveStreamViewer ()
{
    NSDictionary* _currentThread;
}

@property (weak) IBOutlet NCBlockDrawableView *infoView;
@property (strong) IBOutlet NSView *renderView;
@property (weak) IBOutlet NSTextField *userNameLabel;
@property (weak) IBOutlet NSPopUpButton *mediaThreadsPopup;
@property (nonatomic) BOOL viewUpdated;
@property (unsafe_unretained) IBOutlet NSTextView *streamEventsTextView;
@property (weak) IBOutlet NSScrollView *streamEventsScrollView;
@property (nonatomic) NSTimer *fadeAnimationTimer;
@property (nonatomic) BOOL isStreamEventsViewVisible;

@end

//******************************************************************************
@implementation NCActiveStreamViewer

-(id)init
{
    self = [super initWithNibName:@"NCActiveStreamView"
                           bundle:nil];
    
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

-(void)initialize
{
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor blackColor].CGColor;
    
    [((NCBlockDrawableView*)self.view) addDrawBlock:^(NSView *view, NSRect dirtyRect) {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:view.bounds];
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor orangeColor] endingColor:[NSColor clearColor]];
        [gradient drawInBezierPath:path relativeCenterPosition:NSMakePoint(0., 0.)];
    }];
    
    [self.infoView addDrawBlock:^(NSView *view, NSRect dirtyRect) {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:view.bounds];
        NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
                    [NSColor colorWithWhite:0. alpha:0.], 0.,
                    [NSColor colorWithWhite:0. alpha:1.], 1.,
                    nil];
        [gradient drawInBezierPath:path angle:90.];
    }];
    
    self.viewUpdated = NO;
    self.isStreamEventsViewVisible = YES;
}

-(void)awakeFromNib
{
    [self.streamEventsTextView setDrawsBackground:NO];
    [self.streamEventsScrollView setDrawsBackground:NO];
}

-(void)dealloc
{
}

-(void)setRenderer:(NCVideoStreamRenderer *)renderer
{
    _renderer = renderer;
    
    if (self.viewUpdated)
        [self.renderer setRenderingView:self.renderView];
}

-(NSArray *)mediaThreads
{
    NSArray *streams = [self.userInfo valueForKeyPath:
                       [NSString keyPathByComponents:
                        kNCSessionInfoKey,
                        NSStringFromSelector(@selector(videoStreamsConfigurations)),
                        nil]];
    
    __block NSArray *threads = nil;
    [streams enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
        if ([[obj valueForKey:kNameKey] isEqualToString:[self.streamPrefix getNdnRtcStreamName]])
        {
            threads = [obj valueForKey:kThreadsArrayKey];
            *stop = YES;
        }
    }];
    
    return threads;
}

+(NSSet *)keyPathsForValuesAffectingCurrentThread
{
    return [NSSet setWithObjects:
            NSStringFromSelector(@selector(currentThreadIdx)),
            NSStringFromSelector(@selector(mediaThreads)),
            nil];
}

+(NSSet*)keyPathsForValuesAffectingMediaThreads
{
    return [NSSet setWithObjects:
            NSStringFromSelector(@selector(userInfo)),
            NSStringFromSelector(@selector(streamPrefix)),
            nil];
}

-(void)setCurrentThreadIdx:(NSNumber *)currentThreadIdx
{
    NSNumber *oldValue = _currentThreadIdx;
    
    if (![_currentThreadIdx isEqual:currentThreadIdx])
    {
        _currentThreadIdx = currentThreadIdx;
        _currentThread = [self.mediaThreads objectAtIndex:_currentThreadIdx.intValue];
        
        if (oldValue && 
            self.delegate &&
            [self.delegate respondsToSelector:@selector(activeStreamViewer:didSelectThreadWithConfiguration:)])
        {
            [self.delegate activeStreamViewer:self didSelectThreadWithConfiguration:_currentThread];
        }
    }
}

-(void)clearStreamEventView
{
    [self.streamEventsTextView setString:@""];
}

-(void)renderStreamEvent:(NSString*)eventDescription
{
    if (!self.isStreamEventsViewVisible)
        return;
    
    static NSDictionary *stringAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *pStyle;
        pStyle = [[NSMutableParagraphStyle alloc] init];
        [pStyle setAlignment:NSRightTextAlignment];
        
        stringAttributes = @{
                             NSParagraphStyleAttributeName: pStyle,
                             NSBackgroundColorAttributeName: [NSColor clearColor],
                             NSFontAttributeName: [NSFont systemFontOfSize:10],
                             NSForegroundColorAttributeName: [NSColor whiteColor]
                             };
    });
    
    NSString *textEntry = [NSString stringWithFormat:@"%@\n", eventDescription];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc]
                                    initWithString:textEntry
                                    attributes:stringAttributes];
        
        [[_streamEventsTextView textStorage] appendAttributedString:attr];
        [_streamEventsTextView scrollRangeToVisible:NSMakeRange([[_streamEventsTextView string] length], 0)];
    });
    
    self.streamEventsTextView.alphaValue = 1.;
    
    __weak NCActiveStreamViewer *this = self;
    if (self.fadeAnimationTimer)
        [self.fadeAnimationTimer invalidate];
    
    self.fadeAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:2.
                                                     repeats:NO
                                                   fireBlock:^(NSTimer *timer) {
                                                       [[this streamEventsTextView] setAlphaValue:0.];
                                                       this.fadeAnimationTimer = nil;
                                                   }];
}

-(void)setIsStreamEventsViewVisible:(BOOL)isStreamEventsViewVisible
{
    if (_isStreamEventsViewVisible != isStreamEventsViewVisible)
    {
        _isStreamEventsViewVisible = isStreamEventsViewVisible;
        [self.streamEventsScrollView setHidden:!isStreamEventsViewVisible];
        
        if (isStreamEventsViewVisible)
            [self renderStreamEvent:@"stream events enabled"];
    }
}

// NCVideoPreviewViewDelegate
-(void)videoPreviewViewDidUpdatedFrame:(NCVideoPreviewView *)videoPreviewView
{
    if (!self.viewUpdated
        && !CGRectEqualToRect(CGRectZero, self.renderView.bounds))
    {
        self.viewUpdated = YES;
        [self.renderer setRenderingView:self.renderView];
    }
}

@end

//******************************************************************************
@interface NCThreadInfoValueTransformer : NSValueTransformer

@end

@implementation NCThreadInfoValueTransformer

+(BOOL)allowsReverseTransformation
{
    return NO;
}

+(Class)transformedValueClass
{
    return [NSArray class];
}

-(id)transformedArrayValue:(NSArray*)value
{
    __block NSMutableArray *result = [NSMutableArray array];
    
    [value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [result addObject:[NSString stringWithFormat:@"%@ (%@X%@ %@kbit/s)",
                           [obj valueForKey:kNameKey],
                           [obj valueForKey:kEncodingWidthKey],
                           [obj valueForKey:kEncodingHeightKey],
                           [obj valueForKey:kBitrateKey]]];
    }];
    
    return result;
}

-(id)transformedValue:(id)value
{
    if ([value isKindOfClass:[NSArray class]])
        return [self transformedArrayValue:value];
    
    return nil;
}


@end

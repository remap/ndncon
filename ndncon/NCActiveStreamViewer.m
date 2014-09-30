//
//  NCActiveStreamViewer.m
//  NdnCon
//
//  Created by Peter Gusev on 9/26/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCActiveStreamViewer.h"
#import "NCBlockDrawableView.h"

@interface NCActiveStreamViewer ()

@property (weak) IBOutlet NCBlockDrawableView *infoView;

@property (strong) IBOutlet NSView *renderView;
@property (weak) IBOutlet NSTextField *userNameLabel;
@property (weak) IBOutlet NSPopUpButton *mediaThreadsPopup;
@property (nonatomic) BOOL viewUpdated;

@end

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

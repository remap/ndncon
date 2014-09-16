//
//  NCEditorEntryView.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCEditorEntryView.h"

@implementation NCEditorEntryView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.headerHeight = 39;
        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor clearColor].CGColor;
        self.layer.shadowColor = [NSColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(1., -1.);
        self.layer.shadowRadius = 2.;
        self.layer.shadowOpacity = 0.8;
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGRect frame = NSInsetRect(self.bounds, 6.0, 6.0);
    
    [NSBezierPath setDefaultLineWidth:1.0];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frame
                                                         xRadius:10.0 yRadius:10.0];
    
    [[NSColor colorWithWhite:0.95 alpha:1.] set];
    [path fill];

    { // draw header
        CGFloat width = CGRectGetWidth(self.bounds);
        CGFloat height = CGRectGetHeight(self.bounds);
        
        NSBezierPath *headerPath = [[NSBezierPath alloc] init];
        [headerPath moveToPoint:NSMakePoint(16, height-6)];
        [headerPath appendBezierPathWithArcFromPoint:NSMakePoint(6, height-6)
                                             toPoint:NSMakePoint(6, height-16)
                                              radius:10.];
        [headerPath lineToPoint:NSMakePoint(6, height-self.headerHeight)];
        [headerPath lineToPoint:NSMakePoint(width-6, height-self.headerHeight)];
        [headerPath appendBezierPathWithArcFromPoint:NSMakePoint(width-6, height-6)
                                             toPoint:NSMakePoint(width-16, height-6)
                                              radius:10.];
        [headerPath closePath];
        
        [[NSColor colorWithWhite:0.7 alpha:1.] set];
        [headerPath fill];
        
        NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
                                [NSColor colorWithWhite:0.8 alpha:1.], 0.,
                                [NSColor colorWithWhite:0.8 alpha:1.], 0.5,
                                [NSColor colorWithWhite:0.9 alpha:1.], 0.51,
                                [NSColor colorWithWhite:0.85 alpha:1.], 0.9,
                                nil];
        [gradient drawInBezierPath:headerPath angle:90.];
    }
    
    [[NSColor colorWithWhite:0.5 alpha:1.] set];
    [path stroke];
}

@end

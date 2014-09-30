//
//  NCEditorEntryView.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCEditorEntryView.h"
#import "NCBlockDrawableView.h"

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
    self.layer.shadowColor = self.shadowColor.CGColor;
    
    CGFloat inset = self.shadowInset;
    CGFloat cornerRadius =(self.roundCorners)?self.cornerRadius:0.;
    
    CGRect frame = NSInsetRect(self.bounds, inset, inset);
    
    [NSBezierPath setDefaultLineWidth:1.0];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frame
                                                         xRadius:cornerRadius yRadius:cornerRadius];
    
    [[NSColor colorWithWhite:0.95 alpha:1.] set];
    [path fill];
    
    { // draw header
        CGFloat width = CGRectGetWidth(self.bounds);
        CGFloat height = CGRectGetHeight(self.bounds);
        
        NSBezierPath *headerPath = nil;
        
        if (self.roundCorners)
        {
            headerPath = [[NSBezierPath alloc] init];
            [headerPath moveToPoint:NSMakePoint(cornerRadius+inset, height-inset)];
            [headerPath appendBezierPathWithArcFromPoint:NSMakePoint(inset, height-inset)
                                                 toPoint:NSMakePoint(inset, height-(cornerRadius+inset))
                                                  radius:cornerRadius];
            [headerPath lineToPoint:NSMakePoint(inset, height-self.headerHeight)];
            [headerPath lineToPoint:NSMakePoint(width-inset, height-self.headerHeight)];
            [headerPath appendBezierPathWithArcFromPoint:NSMakePoint(width-inset, height-inset)
                                                 toPoint:NSMakePoint(width-(cornerRadius+inset), height-inset)
                                                  radius:cornerRadius];
            [headerPath closePath];
        }
        else
        {
            headerPath = [NSBezierPath bezierPathWithRect:CGRectMake(inset, frame.size.height-inset-self.headerHeight,
                                                                     frame.size.width,
                                                                     self.headerHeight)];
        }
        
        if (self.headerStyle != EditorEntryViewHeaderStyleNone)
        {
            NSGradient *gradient = nil;
            
            if (self.headerStyle == EditorEntryViewHeaderStyleGloss)
            {
                [[NSColor colorWithWhite:0.7 alpha:1.] set];
                [headerPath fill];
                
                gradient = [[NSGradient alloc] initWithColorsAndLocations:
                            [NSColor colorWithWhite:0.8 alpha:1.], 0.,
                            [NSColor colorWithWhite:0.8 alpha:1.], 0.5,
                            [NSColor colorWithWhite:0.9 alpha:1.], 0.51,
                            [NSColor colorWithWhite:0.85 alpha:1.], 0.9,
                            nil];
            }
            else if (self.headerStyle == EditorEntryViewHeaderStyleDark)
            {
                gradient = [[NSGradient alloc] initWithColorsAndLocations:
                            [NSColor colorWithWhite:0. alpha:0.], 0.,
                            [NSColor colorWithWhite:0. alpha:1.], 1.,
                            nil];
            }
            
            [gradient drawInBezierPath:headerPath angle:90.];
        }
    }
    
    [[NSColor colorWithWhite:0.5 alpha:1.] set];
    [path stroke];
}

@end

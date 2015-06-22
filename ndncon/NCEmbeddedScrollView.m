//
//  NCEmbeddedScrollView.m
//  NdnCon
//
//  Created by Peter Gusev on 9/16/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCEmbeddedScrollView.h"

const double kNCScrollingThreshold = 5;

@implementation NCEmbeddedScrollView

-(void)scrollWheel:(NSEvent *)theEvent
{
    CGEventRef cg_verticalScrollEvent = ((NSEvent*)[theEvent copy]).CGEvent;
    CGEventRef cg_horizontalScrollEvent = CGEventCreateCopy(cg_verticalScrollEvent);
    
    CGEventSetDoubleValueField(cg_verticalScrollEvent, kCGScrollWheelEventDeltaAxis2, 0.);
    CGEventSetDoubleValueField(cg_horizontalScrollEvent, kCGScrollWheelEventDeltaAxis1, 0.);
    
    NSEvent *verticalScrollEvent = [NSEvent eventWithCGEvent:cg_verticalScrollEvent];
    NSEvent *horizontalScrollEvent = [NSEvent eventWithCGEvent:cg_horizontalScrollEvent];
    
    if (self.ignoreHorizontalScroll.boolValue || self.ignoreVerticalScroll.boolValue)
    {
        if (self.ignoreHorizontalScroll.boolValue && self.ignoreVerticalScroll.boolValue)
            [self.superview scrollWheel:theEvent];
        else
        {
            if (self.ignoreVerticalScroll.boolValue)
            {
                if (abs(verticalScrollEvent.scrollingDeltaY) > kNCScrollingThreshold)
                    [self.superview scrollWheel:verticalScrollEvent];
                [super scrollWheel:horizontalScrollEvent];
            }
            else
            {
                if (abs(horizontalScrollEvent.scrollingDeltaX) > kNCScrollingThreshold)
                    [self.superview scrollWheel:horizontalScrollEvent];
                [super scrollWheel:verticalScrollEvent];
            }
        }
    }
    else
    {
        [super scrollWheel:theEvent];
    }
}

@end

//
//  NCClickableView.m
//  NdnCon
//
//  Created by Peter Gusev on 9/29/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCClickableView.h"

@implementation NCClickableView

-(void)mouseDown:(NSEvent *)theEvent
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewWasClicked:)])
        [self.delegate viewWasClicked:self];
}


@end


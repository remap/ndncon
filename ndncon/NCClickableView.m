//
//  NCClickableView.m
//  NdnCon
//
//  Created by Peter Gusev on 9/29/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NCClickableView.h"

@implementation NCClickableView

-(void)mouseDown:(NSEvent *)theEvent
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewWasClicked:)])
        [self.delegate viewWasClicked:self];
}


@end


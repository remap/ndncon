//
//  NCCustomTextField.m
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCCustomTextField.h"

@implementation NCCustomTextField

-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

-(void)mouseDown:(NSEvent *)theEvent
{
    [self setEditable:YES];
}

-(BOOL)resignFirstResponder
{
    [self setEditable:NO];
    return [super resignFirstResponder];
}

@end

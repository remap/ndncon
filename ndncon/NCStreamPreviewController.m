//
//  NCStreamPreviewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamPreviewController.h"

@interface NCStreamPreviewController ()

@end

@implementation NCStreamPreviewController

-(id)init
{
    self = [super init];
    
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

- (void)dealloc
{
    self.streamName = nil;
    self.userData = nil;
}

-(void)initialize
{
    self.view = [[NCClickableView alloc] init];
    ((NCClickableView*)self.view).delegate = self;
    
    [self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
}

-(void)viewWasClicked:(NCClickableView *)view
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamPreviewControllerWasSelected:)])
        [self.delegate streamPreviewControllerWasSelected:self];
}

@end

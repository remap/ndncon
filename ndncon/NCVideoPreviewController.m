//
//  NCVideoPreviewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCVideoPreviewController.h"

@interface NCVideoPreviewController ()

@end

@implementation NCVideoPreviewController

-(void)initialize
{
    [super initialize];

    NSView *streamPreview = self.view;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[streamPreview(177.7)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(streamPreview)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[streamPreview(100)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(streamPreview)]];
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
}

@end

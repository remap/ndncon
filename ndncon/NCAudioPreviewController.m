//
//  NCAudioPreviewControllerViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCAudioPreviewController.h"

@interface NCAudioPreviewController ()

@end

@implementation NCAudioPreviewController

-(void)initialize
{
    [super initialize];

    NSView *preview = self.view;
    [self.view setContentCompressionResistancePriority:NSLayoutPriorityRequired
                                        forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[preview(==90)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(preview)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[preview(==60)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(preview)]];
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    NSImageView *imageView = [[NSImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.image = [NSImage imageNamed:@"sound_icon"];
    
    self.streamPreview = imageView;
    [self.view addSubview:imageView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(imageView)]];
     [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:NSDictionaryOfVariableBindings(imageView)]];
}

@end

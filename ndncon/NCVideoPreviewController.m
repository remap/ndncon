//
//  NCVideoPreviewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCVideoPreviewController.h"

#define PREVIEW_WIDTH 177.7
#define PREVIEW_HEIGHT 100.

@interface NCVideoPreviewController ()

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, weak) NCCameraCapturer *cameraCapturer;

@end

@implementation NCVideoPreviewController

-(void)initialize
{
    [super initialize];
    
    NSView *streamPreview = self.view;
    NSString *widthConstraint = [NSString stringWithFormat:@"H:[streamPreview(==%f)]", PREVIEW_WIDTH];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:widthConstraint
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(streamPreview)]];
    NSString *heightConstraint = [NSString stringWithFormat:@"V:[streamPreview(==%f)]",
                                  PREVIEW_HEIGHT];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:heightConstraint
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(streamPreview)]];
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.streamPreview = self.view;
}

-(void)setPreviewForCameraCapturer:(NCCameraCapturer *)cameraCapturer
{
    self.cameraCapturer = cameraCapturer;
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.cameraCapturer.session];
    [self.previewLayer setFrame: CGRectMake(0, 0, PREVIEW_WIDTH, PREVIEW_HEIGHT)];
    [self.streamPreview.layer addSublayer:self.previewLayer];
    [self.streamPreview.layer setBackgroundColor:[NSColor blackColor].CGColor];
}

@end

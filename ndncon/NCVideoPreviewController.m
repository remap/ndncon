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

@implementation NCVideoPreviewView

-(id)init
{
    self = [super init];
    
    if (self)
    {
        self.frameWasUpdated = NO;
        self.viewWasDisplayed = NO;
    }
    
    return self;
}

-(void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];

    if (!self.frameWasUpdated &&
        !CGRectEqualToRect(CGRectZero, self.frame))
    {
        self.frameWasUpdated = YES;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoPreviewViewDidUpdatedFrame:)])
            [self.delegate videoPreviewViewDidUpdatedFrame:self];
    }
}

-(void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    if (!self.viewWasDisplayed)
    {
        self.viewWasDisplayed = YES;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoPreviewViewDidDisplayed:)])
            [self.delegate videoPreviewViewDidDisplayed:self];
    }
}

@end

@interface NCVideoPreviewController ()

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, weak) NCCameraCapturer *cameraCapturer;
@property (nonatomic, weak) NCVideoStreamRenderer *renderer;

@end

@implementation NCVideoPreviewController

-(void)initialize
{
//    [super initialize];
    self.view = [[NCVideoPreviewView alloc] init];
    [self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    ((NCVideoPreviewView*)self.view).delegate = self;
    
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

    if ([self isViewReady])
        [self updatePreviewLayer];
}

-(void)setPreviewForVideoRenderer:(NCVideoStreamRenderer*)renderer
{
    if (renderer != self.renderer)
    {
        self.renderer = renderer;

        if ([self isViewReady])
            [self updatePreviewLayer];
    }
}

// NCVideoPreviewViewDelegate
-(void)videoPreviewViewDidUpdatedFrame:(NCVideoPreviewView *)videoPreviewView
{
    if (self.cameraCapturer)
        [self updatePreviewLayer];
}

-(void)videoPreviewViewDidDisplayed:(NCVideoPreviewView *)videoPreviewView
{
    if (self.renderer)
        [self updatePreviewLayer];
}

// private
-(BOOL)isViewReady
{
    return !CGRectEqualToRect(CGRectZero, self.streamPreview.frame);
}
-(void)updatePreviewLayer
{
    if (self.cameraCapturer)
    {
        [self.previewLayer setFrame:self.streamPreview.bounds];
        [self.streamPreview.layer addSublayer:self.previewLayer];
        [self.streamPreview.layer setBackgroundColor:[NSColor blackColor].CGColor];
    }
    else if (self.renderer)
    {
        self.renderer.renderingView = self.streamPreview;
    }
}

@end

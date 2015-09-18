//
//  NCVideoPreviewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NCVideoPreviewController.h"
#import "NSView+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"

#define PREVIEW_WIDTH 177.7
#define PREVIEW_HEIGHT 100.

//******************************************************************************
@interface NCVideoPreviewView ()

@property (nonatomic) NSString *hint;

@end

//******************************************************************************
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

-(void)setIsSelected:(BOOL)isSelected
{
    _isSelected = isSelected;
    [self setNeedsDisplay:YES];
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
    
    if (self.isSelected)
    {
        NSRect bounds = self.bounds;
        NSShadow *shadow = [[NSShadow alloc] init];
        
        [shadow setShadowBlurRadius:5.];
        [shadow setShadowOffset:NSMakeSize(0, 0)];
        [shadow setShadowColor:[NSColor orangeColor]];
        [shadow set];
        
        [[NSColor orangeColor] set];
        [NSBezierPath strokeRect:bounds];
        
        NSFont* font = [NSFont systemFontOfSize:12];
        NSColor* textColor = [NSColor orangeColor];
        NSDictionary* stringAttrs = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : textColor };
        NSString *hintString = [NSString stringWithFormat:@"stream %@\nis active", self.hint];
        NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:hintString attributes:stringAttrs];

        [attrStr drawAtPoint:CGPointMake(bounds.size.width/2.-attrStr.size.width/2, bounds.size.height/2.-attrStr.size.height/2)];
    }
}

@end

//******************************************************************************
@interface NCVideoPreviewController ()

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, weak) NCBaseCapturer *capturer;
@property (nonatomic, strong) NCVideoStreamRenderer *renderer;

@property (nonatomic) NSTrackingArea *trackingArea;
@property (weak) IBOutlet NCBlockDrawableView *streamInfoView;
@property (weak) IBOutlet NSTextField *streamNameLabel;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@end

@implementation NCVideoPreviewController

-(instancetype)init
{
    self = [self initWithNibName:@"NCVideoPreview" bundle:nil];
    
    if (self)
    {
    }
    
    return self;
}

-(void)dealloc
{
    if (self.capturer)
        [self.capturer stopCapturing];

    self.capturer = nil;
    self.renderer = nil;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    NSView *streamPreview = self.streamPreview;
    NSString *widthConstraint = [NSString stringWithFormat:@"H:[streamPreview(>=%f)]", PREVIEW_WIDTH];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:widthConstraint
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(streamPreview)]];
    NSString *heightConstraint = [NSString stringWithFormat:@"V:[streamPreview(>=%f)]",
                                  PREVIEW_HEIGHT];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:heightConstraint
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(streamPreview)]];
//    streamPreview.wantsLayer = YES;
//    streamPreview.layer.backgroundColor = [NSColor purpleColor].CGColor;
    
    self.streamInfoView.alphaValue = 0.;
    self.streamInfoView.wantsLayer = YES;
    [self.streamInfoView addDrawBlock:^(NSView *view, NSRect dirtyRect) {
        [[NSColor colorWithWhite:1. alpha:0.3] set];
        NSRectFill(view.bounds);
    }];
    
    [self updateTrackingAreas];
    [self.progressIndicator startAnimation:nil];
}

#pragma mark - public
- (IBAction)onClose:(id)sender
{
    [self close];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamPreviewControllerWasClosed:)])
        [self.delegate streamPreviewControllerWasClosed:self];
}

-(void)setPreviewForCapturer:(NCBaseCapturer*)capturer
{
    self.capturer = capturer;
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.capturer.session];

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

-(void)setStreamConfiguration:(NSDictionary *)streamConfiguration
{
    _streamConfiguration = streamConfiguration;
    self.streamName = streamConfiguration[kNameKey];
    [self.streamNameLabel setStringValue:_streamConfiguration[kNameKey]];
    [(NCVideoPreviewView*)self.streamPreview setHint:self.streamName];
}

-(void)close
{
    if (self.capturer)
    {
        [self.capturer stopCapturing];
        [self.capturer setNdnRtcExternalCapturer:NULL];
    }
}

#pragma mark - NCVideoPreviewViewDelegate
-(void)videoPreviewViewDidUpdatedFrame:(NCVideoPreviewView *)videoPreviewView
{
    [self updateTrackingAreas];
    
    if (self.capturer)
        [self updatePreviewLayer];
}

-(void)videoPreviewViewDidDisplayed:(NCVideoPreviewView *)videoPreviewView
{
    if (self.renderer)
        [self updatePreviewLayer];
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3;
        self.streamInfoView.alphaValue = 1.;
    } completionHandler:^{
        self.streamInfoView.alphaValue = 1.;
    }];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3;
        self.streamInfoView.alphaValue = 0.;
    }
                        completionHandler:^{
                            self.streamInfoView.alphaValue = 0.;
                        }];
}

#pragma mark - private
-(void)updateTrackingAreas
{
    [self.streamPreview removeTrackingArea:self.trackingArea];
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.streamPreview.bounds
                                                     options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                       owner:self
                                                    userInfo:nil];
    [self.streamPreview addTrackingArea:self.trackingArea];
}

-(BOOL)isViewReady
{
    return !CGRectEqualToRect(CGRectZero, self.streamPreview.frame);
}

-(void)updatePreviewLayer
{
    if (self.capturer)
    {
        [self.previewLayer setFrame:self.streamPreview.bounds];
        [self.streamPreview.layer addSublayer:self.previewLayer];
//        [self.streamPreview.layer setBackgroundColor:[NSColor purpleColor].CGColor];
        
    }
    else if (self.renderer)
    {
        self.renderer.renderingView = self.streamPreview;
    }
}

@end

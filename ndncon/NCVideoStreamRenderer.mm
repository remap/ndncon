//
//  NCVideoStreamRenderer.m
//  NdnCon
//
//  Created by Peter Gusev on 9/25/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndnrtc/interfaces.h>

#import "NCVideoStreamRenderer.h"
#import "NCGlView.h"

class RendererInternal;

@interface NCVideoStreamRenderer ()
{
    CVDisplayLinkRef _displayLink;
    RendererInternal* _renderer;
}

@property (nonatomic) NCGlView *openGlView;

-(uint8_t*)getRenderingBufferForWidth:(int)width andHeight:(int)height;
-(void)renderFrame:(const uint8_t*)frameData withWidth:(NSInteger)width andHeight:(NSInteger)height andTimestamp:(int64_t)timestamp;
-(void)screenRefresh:(CVTimeStamp)timestamp;

@end

//******************************************************************************
class RendererInternal : public ndnrtc::IExternalRenderer
{
public:
    RendererInternal(NCVideoStreamRenderer* videoStreamRenderer)
    { videoStreamRenderer_ = videoStreamRenderer; };
    ~RendererInternal(){};
    
    uint8_t* getFrameBuffer(int width, int height)
    {
        return [videoStreamRenderer_ getRenderingBufferForWidth:width andHeight:height];
    }
    
    void renderBGRAFrame(int64_t timestamp, int width, int height,
                         const uint8_t* buffer)
    {
        if (videoStreamRenderer_)
            [videoStreamRenderer_ renderFrame:buffer
                                    withWidth:width
                                    andHeight:height
                                 andTimestamp:timestamp];
        
        return;
    }
    
private:
    NCVideoStreamRenderer *videoStreamRenderer_;
};

//******************************************************************************

CVReturn displayCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext)
{
    NCVideoStreamRenderer *controller = (__bridge NCVideoStreamRenderer *)displayLinkContext;
    
    [controller screenRefresh:*inOutputTime];
    
    return kCVReturnSuccess;
}

@implementation NCVideoStreamRenderer

-(id)init
{
    self = [super init];
    
    if (self)
        [self initialize];
    
    return self;
}

-(void)initialize
{
    _displayLink = 0;
    _renderer = new RendererInternal(self);
}

-(void)dealloc
{
    delete _renderer;
    self.openGlView = nil;
    [self releaseDisplayLink];
}

-(void *)ndnRtcRenderer
{
    return _renderer;
}

-(void)setRenderingView:(NSView *)renderingView
{
    if (renderingView && _renderingView != renderingView)
    {
        _renderingView = renderingView;
        [self createOpenGlView];
        [self createDisplayLink];
    }
}

-(uint8_t *)getRenderingBufferForWidth:(int)width andHeight:(int)height
{
    return [self.openGlView bufferForWidth:width andHeight:height];
}

-(void)renderFrame:(const uint8_t*)frameData
         withWidth:(NSInteger)width
         andHeight:(NSInteger)height
      andTimestamp:(int64_t)timestamp
{
    [self.openGlView updateBuffer];
}

// private
- (void)createOpenGlView
{
    NSOpenGLPixelFormatAttribute pixelFormatAttributes[] =
    {
        NSOpenGLPFAColorSize    , 24                           ,
        NSOpenGLPFAAlphaSize    , 8                            ,
        NSOpenGLPFADoubleBuffer ,
        NSOpenGLPFAAccelerated  ,
        NSOpenGLPFANoRecovery   ,
        0
    };
    
    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes];
    self.openGlView = [[NCGlView alloc] initWithFrame:self.renderingView.bounds
                                          pixelFormat:pixelFormat];
    [self.openGlView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.renderingView addSubview: self.openGlView];
    
    NSView *openGlView = self.openGlView;
    [self.renderingView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[openGlView]|"
                                                                              options:0
                                                                              metrics:nil
                                                                                 views:NSDictionaryOfVariableBindings(openGlView)]];
    [self.renderingView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[openGlView]|"
                                                                               options:0
                                                                               metrics:nil
                                                                                 views:NSDictionaryOfVariableBindings(openGlView)]];
}

- (void)createDisplayLink
{
    [self releaseDisplayLink];

    CVReturn error = CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
    
    if (kCVReturnSuccess == error)
    {
        CVDisplayLinkSetOutputCallback(_displayLink, displayCallback, (__bridge void*)self);
        CVDisplayLinkStart(_displayLink);
    }
    else
    {
        NSLog(@"Display Link created with error: %d", error);
        _displayLink = NULL;
    }
}

- (void)releaseDisplayLink
{
    if (_displayLink)
    {
        CVDisplayLinkStop(_displayLink);
        CVDisplayLinkRelease(_displayLink);
    }
}

- (void)screenRefresh:(CVTimeStamp)timestamp
{
    if (!self.openGlView.openGLContext)
    {
        NSLog(@"context is not ready yet");
        return;
    }
    
    if (self.openGlView.bufferUpdated)
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.openGlView setNeedsDisplay:YES];
        });
    }
}

@end


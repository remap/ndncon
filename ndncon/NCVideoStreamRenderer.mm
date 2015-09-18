//
//  NCVideoStreamRenderer.m
//  NdnCon
//
//  Created by Peter Gusev on 9/25/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#include <ndnrtc/interfaces.h>

#import "NCVideoStreamRenderer.h"
#import "NCGlView.h"

class RendererInternal;

//******************************************************************************
@interface NCVideoStreamRenderer ()
{
    CVDisplayLinkRef _displayLink;
    RendererInternal* _renderer;
    NSLock *_renderingViewLock;
}

@property (nonatomic, strong) NCGlView *openGlView;

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
    ~RendererInternal(){ videoStreamRenderer_ = NULL; };
    
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
    __weak NCVideoStreamRenderer *videoStreamRenderer_;
};

//******************************************************************************

CVReturn displayCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext)
{
    NCVideoStreamRenderer *controller = (__bridge NCVideoStreamRenderer *)displayLinkContext;
    
    [controller screenRefresh:*inOutputTime];
    
    return kCVReturnSuccess;
}

//******************************************************************************
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
    _renderingViewLock = [[NSLock alloc] init];
    _displayLink = 0;
    _renderer = new RendererInternal(self);
}

-(void)dealloc
{
    [self releaseDisplayLink];
    self.renderingView = nil;
    [self.openGlView removeFromSuperview];
    delete _renderer;
    self.openGlView = nil;
}

-(void *)ndnRtcRenderer
{
    return _renderer;
}

-(void)setRenderingView:(NSView *)renderingView
{
    [_renderingViewLock lock];

    if (renderingView && _renderingView != renderingView)
    {
        [self releaseDisplayLink];
        _renderingView = renderingView;
        [self createOpenGlView];
        [self createDisplayLink];
    }

    [_renderingViewLock unlock];
}

-(uint8_t *)getRenderingBufferForWidth:(int)width andHeight:(int)height
{
    [_renderingViewLock lock]; // will be unlocked in renderFrame:withWidth:andHeight:andTimestamp:
    uint8_t *buf = [self.openGlView bufferForWidth:width andHeight:height];
    
    if (!buf)
        [_renderingViewLock unlock];
    
    return buf;
}

-(void)renderFrame:(const uint8_t*)frameData
         withWidth:(NSInteger)width
         andHeight:(NSInteger)height
      andTimestamp:(int64_t)timestamp
{
    [self.openGlView updateBuffer];
    [_renderingViewLock unlock]; // release lock set in getRenderingBufferForWidth:andHeight: call
}

// private
- (void)createOpenGlView
{
    if (self.openGlView)
    {
        [self.openGlView removeFromSuperview];
        self.openGlView = nil;
    }
    
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
        _displayLink = 0;
    }
}

- (void)screenRefresh:(CVTimeStamp)timestamp
{
    if (!self.openGlView.openGLContext)
        return;
    
    if (self.openGlView.bufferUpdated)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_renderingViewLock lock];
            [self.openGlView setNeedsDisplay:YES];
            [_renderingViewLock unlock];
        });
    }
}

@end


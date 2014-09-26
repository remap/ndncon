//
//  NCVideoStreamRenderer.m
//  NdnCon
//
//  Created by Peter Gusev on 9/25/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndnrtc/interfaces.h>

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

#import "NCVideoStreamRenderer.h"


#define GetError( )\
{\
for ( GLenum Error = glGetError( ); ( GL_NO_ERROR != Error ); Error = glGetError( ) )\
{\
switch ( Error )\
{\
case GL_INVALID_ENUM:      printf( "\n%s\n\n", "GL_INVALID_ENUM"      ); assert( 0 ); break;\
case GL_INVALID_VALUE:     printf( "\n%s\n\n", "GL_INVALID_VALUE"     ); assert( 0 ); break;\
case GL_INVALID_OPERATION: printf( "\n%s\n\n", "GL_INVALID_OPERATION" ); assert( 0 ); break;\
case GL_OUT_OF_MEMORY:     printf( "\n%s\n\n", "GL_OUT_OF_MEMORY"     ); assert( 0 ); break;\
default:                                                                              break;\
}\
}\
}

@interface MyGlView : NSOpenGLView
{
    uint _bufferSize, _width, _height;
    uint8_t *_renderingBuffer;
    GLuint _texture;
    NSLock *_renderingLock;
}

@property (nonatomic) BOOL bufferUpdated;

@end

@implementation MyGlView

-(id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
    self = [super initWithFrame:frameRect pixelFormat:format];
    
    if (self)
    {
        _renderingLock = [[NSLock alloc] init];
    }
    
    return self;
}

-(uint8_t*)bufferForWidth:(int)width andHeight:(int)height
{
    _width = width;
    _height = height;
    
    int requiredSize = width*height*4;
    
    if (!_renderingBuffer || _bufferSize < requiredSize)
    {
        _renderingBuffer = (uint8_t*)realloc((void*)_renderingBuffer, requiredSize);
        memset(_renderingBuffer, 0, requiredSize);
        _bufferSize = requiredSize;
        [self createTexture];
    }
    
    return _renderingBuffer;
}

-(void)updateBuffer
{
    [_renderingLock lock];
    
    [self.openGLContext makeCurrentContext];
    
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _texture);
    GetError();
    
    glTexSubImage2D(GL_TEXTURE_RECTANGLE_ARB,
                    0,
                    0, 0,
                    _width, _height,
                    GL_BGRA, GL_UNSIGNED_INT_8_8_8_8,
                    _renderingBuffer);
    GetError();
    
    self.bufferUpdated = YES;
    
    [_renderingLock unlock];
}

-(void)createTexture
{
    [_renderingLock lock];
    
    [self.openGLContext makeCurrentContext];
    
    if (glIsTexture(_texture))
    {
        glDeleteTextures(1, (const GLuint*) &_texture);
        GetError();
        _texture = 0;
    }
    
    glGenTextures(1, (GLuint*) &_texture);
    GetError();
    
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _texture);
    GetError();
    
    glPixelStorei(GL_UNPACK_ROW_LENGTH, (GLint)_width);
    GetError();
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    GetError();
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    GetError();
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    GetError();
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    GetError();
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    GetError();
    
    glTexImage2D(GL_TEXTURE_RECTANGLE_ARB,
                 0,
                 GL_RGBA8,
                 _width,
                 _height,
                 0,
                 GL_BGRA,
                 GL_UNSIGNED_INT_8_8_8_8,
                 _renderingBuffer);
    GetError();
    
    [_renderingLock unlock];
}

-(void)prepareOpenGL
{
    [_renderingLock lock];
    // Disable not needed functionality to increase performance
    glDisable(GL_DITHER);
    glDisable(GL_ALPHA_TEST);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_FOG);
    glDisable(GL_TEXTURE_2D);
    glPixelZoom(1.0, 1.0);
    glDisable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    glDisable(GL_CULL_FACE);

    // Set texture parameters
    glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_PRIORITY, 1.0);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE);
    
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB,
                    GL_TEXTURE_STORAGE_HINT_APPLE,
                    GL_STORAGE_CACHED_APPLE);
    glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
    
    glViewport(0, 0,
               CGRectGetWidth(self.bounds),
               CGRectGetHeight(self.bounds));
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [self.openGLContext setValues:&swapInt
                     forParameter:NSOpenGLCPSwapInterval];
    
    [_renderingLock unlock];
}

-(void)drawRect:(NSRect)dirtyRect
{
    [_renderingLock lock];
    
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (self.bufferUpdated)
    {
        self.bufferUpdated = NO;
        
//        GLfloat _startWidth = 0.f, _startHeight = 0.f, _stopWidth = 1.f, _stopHeight = 1.f;
//        
//        GLfloat xStart = 2.0f * _startWidth - 1.0f;
//        GLfloat xStop = 2.0f * _stopWidth - 1.0f;
//        GLfloat yStart = 1.0f - 2.0f * _stopHeight;
//        GLfloat yStop = 1.0f - 2.0f * _startHeight;
        
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _texture);
        glLoadIdentity();

        glBegin(GL_POLYGON);
        {
            glTexCoord2f(0.0, 0.0); glVertex2f(-1, 1);
            glTexCoord2f(_width, 0.0); glVertex2f(1, 1);
            glTexCoord2f(_width, _height); glVertex2f(1, -1);
            glTexCoord2f(0.0, _height); glVertex2f(-1, -1);
        }
        glEnd();
        glFinish();
        
        [self.openGLContext flushBuffer];
    }
    
    [_renderingLock unlock];
}

@end

class RendererInternal;

@interface NCVideoStreamRenderer ()
{
    CVDisplayLinkRef _displayLink;
    RendererInternal* _renderer;
}

@property (nonatomic) MyGlView *openGlView;

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
    self.openGlView = [[MyGlView alloc] initWithFrame:self.renderingView.bounds
                                          pixelFormat:pixelFormat];
    [self.renderingView addSubview: self.openGlView];
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


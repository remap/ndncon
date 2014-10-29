//
//  NCGlView.h
//  NdnCon
//
//  Created by Peter Gusev on 9/29/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NCGlView : NSOpenGLView
{
    uint _bufferSize, _width, _height;
    uint8_t *_renderingBuffer;
    GLuint _texture;
}

@property (nonatomic) BOOL bufferUpdated;

-(unsigned char*)bufferForWidth:(int)width andHeight:(int)height;
-(void)updateBuffer;

@end
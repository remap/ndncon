//
//  NCBlockDrawableView.h
//  NdnCon
//
//  Created by Peter Gusev on 9/29/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef void(^NCDrawBlock)(NSView *view, NSRect dirtyRect);

@interface NCBlockDrawableView : NSView

-(void)addDrawBlock:(NCDrawBlock)drawBlock;
-(void)removeDrawBlock:(NCDrawBlock)drawBlock;

@end

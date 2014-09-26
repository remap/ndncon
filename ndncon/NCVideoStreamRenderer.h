//
//  NCVideoStreamRenderer.h
//  NdnCon
//
//  Created by Peter Gusev on 9/25/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCVideoStreamRenderer : NSObject

@property (nonatomic, readonly) void* ndnRtcRenderer;
@property (nonatomic) NSView* renderingView;

@end

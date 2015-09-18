//
//  NCVideoStreamRenderer.h
//  NdnCon
//
//  Created by Peter Gusev on 9/25/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Foundation/Foundation.h>

@interface NCVideoStreamRenderer : NSObject

@property (nonatomic, readonly) void* ndnRtcRenderer;
@property (nonatomic) NSView* renderingView;

@end

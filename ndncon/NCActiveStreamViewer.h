//
//  NCActiveStreamViewer.h
//  NdnCon
//
//  Created by Peter Gusev on 9/26/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCVideoPreviewController.h"
#import "NCVideoStreamRenderer.h"

@interface NCActiveStreamViewer : NSViewController
<NCVideoPreviewViewDelegate>

@property (nonatomic, readonly) NSView *renderView;
@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *streamName;
@property (nonatomic) NSArray *mediaThreads;
@property (nonatomic) NSString *currentThread;
@property (nonatomic, weak) NCVideoStreamRenderer *renderer;

@end

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

@protocol NCActiveStreamViewerDelegate;

@interface NCActiveStreamViewer : NSViewController
<NCVideoPreviewViewDelegate>

@property (nonatomic, weak) IBOutlet id<NCActiveStreamViewerDelegate> delegate;

@property (nonatomic, readonly) NSView *renderView;
@property (nonatomic) NSString *streamPrefix;
@property (nonatomic, readonly) NSArray *mediaThreads;
@property (nonatomic, readonly) NSDictionary *currentThread;
@property (nonatomic) NSNumber *currentThreadIdx;
@property (nonatomic) NSDictionary *userInfo;
@property (nonatomic, weak) NCVideoStreamRenderer *renderer;

@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSImageView *statusImageView;

@end


@protocol NCActiveStreamViewerDelegate  <NSObject>

@optional
-(void)activeStreamViewer:(NCActiveStreamViewer*)activeStreamViewer didSelectThreadWithConfiguration:(NSDictionary*)threadConfiguration;

@end
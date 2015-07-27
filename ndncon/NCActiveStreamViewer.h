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
#import "NCDiscoveryLibraryController.h"

@protocol NCActiveStreamViewerDelegate;

@interface NCActiveStreamViewer : NSViewController
<NCVideoPreviewViewDelegate>

@property (nonatomic, weak) IBOutlet id<NCActiveStreamViewerDelegate> delegate;

@property (nonatomic, readonly) NSView *renderView;
@property (nonatomic, strong) NCVideoStreamRenderer *renderer;

@property (nonatomic, readonly) NCActiveUserInfo *userInfo;
@property (nonatomic, readonly) NSString *streamPrefix;
@property (nonatomic) NSDictionary *activeStreamConfiguration;

-(void)setActiveStream:(NSDictionary*)streamConfiguration
                  user:(NSString*)username
             andPrefix:(NSString*)hubPrefix;

-(void)clearStreamEventView;
-(void)renderStreamEvent:(NSString*)eventDescription;
-(void)clear;

@end


@protocol NCActiveStreamViewerDelegate  <NSObject>

@optional
-(void)activeStreamViewer:(NCActiveStreamViewer*)activeStreamViewer didSelectThreadWithConfiguration:(NSDictionary*)threadConfiguration;

@end
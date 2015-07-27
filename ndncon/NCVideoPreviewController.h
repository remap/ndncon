//
//  NCVideoPreviewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamPreviewController.h"
#import "NCBaseCapturer.h"
#import "NCVideoStreamRenderer.h"
#import "NCClickableView.h"

@protocol NCVideoPreviewViewDelegate;
@class NCVideoPreviewView;

//******************************************************************************
@interface NCVideoPreviewController : NCStreamPreviewController
<NCVideoPreviewViewDelegate>

@property (nonatomic) NSDictionary *streamConfiguration;
@property (nonatomic, readonly) NCVideoStreamRenderer *renderer;

-(void)close;
-(void)setPreviewForCapturer:(NCBaseCapturer*)capturer;
-(void)setPreviewForVideoRenderer:(NCVideoStreamRenderer*)renderer;

@end

//******************************************************************************
@protocol NCVideoPreviewViewDelegate <NSObject>

@optional
-(void)videoPreviewViewDidUpdatedFrame:(NCVideoPreviewView*)videoPreviewView;
-(void)videoPreviewViewDidDisplayed:(NCVideoPreviewView*)videoPreviewView;

@end

//******************************************************************************
@interface NCVideoPreviewView : NCClickableView

@property (nonatomic) BOOL frameWasUpdated, viewWasDisplayed;
@property (nonatomic, weak) IBOutlet id<NCClickableViewDelegate,NCVideoPreviewViewDelegate> delegate;
@property (nonatomic) BOOL isSelected;

@end
//
//  NCVideoPreviewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamPreviewController.h"
#import "NCCameraCapturer.h"
#import "NCVideoStreamRenderer.h"
#import "NCClickableView.h"

//******************************************************************************
@protocol NCVideoPreviewViewDelegate;

@interface NCVideoPreviewController : NCStreamPreviewController
<NCVideoPreviewViewDelegate>

-(void)setPreviewForCameraCapturer:(NCCameraCapturer*)cameraCapturer;
-(void)setPreviewForVideoRenderer:(NCVideoStreamRenderer*)renderer;
@end

//******************************************************************************
@class NCVideoPreviewView;

@protocol NCVideoPreviewViewDelegate <NSObject>

@optional
-(void)videoPreviewViewDidUpdatedFrame:(NCVideoPreviewView*)videoPreviewView;
-(void)videoPreviewViewDidDisplayed:(NCVideoPreviewView*)videoPreviewView;

@end

//******************************************************************************
@interface NCVideoPreviewView : NCClickableView

@property (nonatomic) BOOL frameWasUpdated, viewWasDisplayed;
@property (nonatomic) IBOutlet id<NCClickableViewDelegate,NCVideoPreviewViewDelegate> delegate;

@end
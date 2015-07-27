//
//  NCUserPreviewController.h
//  NdnCon
//
//  Created by Peter Gusev on 7/9/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import "NCStackEditorEntryViewController.h"
#import "NCVideoPreviewController.h"

extern NSString* const kNCStreamPreviewSelectedNotification;
extern NSString* const kNCStreamPreviewControllerKey;

@protocol NCUserPreviewControllerDelegate;

//******************************************************************************
@interface NCUserPreviewController : NSViewController
<NCStreamPreviewControllerDelegate>

@property (weak) id<NCUserPreviewControllerDelegate> delegate;

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *prefix;

@property (nonatomic) BOOL isAudioEnabled;
@property (nonatomic) BOOL isVideoEnabled;

-(NSArray*)getAllStreams;
-(NSArray*)getAudioStreams;
-(NSArray*)getVideoStreams;

-(NCVideoPreviewController*)addPreviewForStream:(NSDictionary*)streamConfiguration;
-(void)removePreviewForStream:(NSDictionary*)streamConfiguration;
-(void)close;

@end

//******************************************************************************
@protocol NCUserPreviewControllerDelegate <NSObject>

@optional
-(void)userPreviewControllerWillClose:(NCUserPreviewController*)userPreviewController
                          withStreams:(NSArray*)streamConfigurations;
-(void)userPreviewController:(NCUserPreviewController*)userPreviewController
  streamFilterChangedIsAudio:(BOOL)isAudioChanged;
-(void)userPreviewController:(NCUserPreviewController*)userPreviewController
             onStreamDropped:(NSDictionary*)streamConfiguration;
-(void)userPreviewController:(NCUserPreviewController*)userPreviewController
      onVideoPreviewSelected:(NCVideoPreviewController*)videoPreviewController;

@end
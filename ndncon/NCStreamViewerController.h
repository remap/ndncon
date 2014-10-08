//
//  NCStreamViewerController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/7/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStackEditorViewController.h"
#import "NCPreferencesController.h"
#import "NCStreamViewController.h"

@interface NCStreamViewerController : NCStackEditorViewController
<NCStreamViewControllerDelegate>

@property (nonatomic, readonly) NSMutableArray *audioStreams;
@property (nonatomic, readonly) NSMutableArray *videoStreams;

@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *userPrefix;

-(void)setAudioStreams:(NSArray*)audioStreams
       andVideoStreams:(NSArray*)videoStreams;

@end

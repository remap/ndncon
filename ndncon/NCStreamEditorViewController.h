//
//  NCStreamEditorViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStackEditorViewController.h"
#import "NCPreferencesController.h"
#import "NCStreamViewController.h"

@interface NCStreamEditorViewController : NCStackEditorViewController
<NCConfigurationObserverDelegate, NCStreamViewControllerDelegate>

-(id)initWithPreferncesController:(NCPreferencesController*)preferences;

-(void)addVideoStream:(NSDictionary*)defaultConfiguration;
-(void)addAudioStream:(NSDictionary*)defaultConfiguration;

@property (nonatomic, readonly) NSMutableArray *audioStreams;
@property (nonatomic, readonly) NSMutableArray *videoStreams;

//@property (nonatomic, readonly) NSDictionary *configuration;

@end

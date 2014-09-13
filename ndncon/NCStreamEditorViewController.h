//
//  NCStreamEditorViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStackEditorViewController.h"

@interface NCStreamEditorViewController : NCStackEditorViewController

-(void)addVideoStream:(NSDictionary*)defaultConfiguration;
-(void)addAudioStream:(NSDictionary*)defaultConfiguration;

@property (nonatomic, readonly) NSDictionary *configuration;

@end

//
//  NCStreamEditorViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NCStackEditorViewController.h"
#import "NCPreferencesController.h"
#import "NCStreamViewController.h"

@interface NCStreamEditorViewController : NCStackEditorViewController
<NCConfigurationObserverDelegate, NCStreamViewControllerDelegate>

@property (nonatomic, readonly) NSMutableArray *audioStreams;
@property (nonatomic, readonly) NSMutableArray *videoStreams;

-(id)initWithPreferencesController:(NCPreferencesController*)preferences;

-(void)addVideoStream:(NSDictionary*)defaultConfiguration;
-(void)addAudioStream:(NSDictionary*)defaultConfiguration;

-(void)setAudioStreams:(NSArray*)audioStreams andVideoStreams:(NSArray*)videoStreams;

// types of stream view controllers
// by default are NCAudioStreamViewController and NCVideoStreamViewController
@property (nonatomic) Class audioStreamViewControllerClass;
@property (nonatomic) Class videoStreamViewControllerClass;

@end

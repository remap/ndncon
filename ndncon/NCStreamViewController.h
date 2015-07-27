//
//  NCStreamViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

#import "NCConfigurationObserver.h"
#import "NCPreferencesController.h"
#import "NCStackEditorViewController.h"
#import "NCStackEditorEntryViewController.h"

@protocol NCStreamViewControllerDelegate;

/**
 * Base class for stream view controller
 */
@interface NCStreamViewController : NSViewController
<NCStackEditorEntryDelegate, NCConfigurationObserverDelegate>

+(NSDictionary*)defaultConfguration;

@property (nonatomic, weak) id<NCConfigurationObserverDelegate, NCStreamViewControllerDelegate> delegate;

@property (nonatomic, readonly) NCPreferencesController *preferences;
@property (nonatomic, readonly) NSMutableDictionary* configuration;
@property (nonatomic, readonly) NSArray *pairedStreams;
@property (nonatomic) NSString *synchronizedStreamName;

@property (nonatomic) NSString *streamName;
@property (nonatomic, assign) id selectedDevice;
@property (assign) AVCaptureDeviceFormat *deviceFormat;
@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic) NSMutableArray *threadControllers;

@property (weak) IBOutlet NSScrollView *scrollView;
@property (nonatomic, strong) NCStackEditorViewController *stackEditor;

-(id)initWithPreferences:(NCPreferencesController*)preferences andName:(NSString *)streamName;

-(Class)threadViewControllerClass;
-(NSViewController*)addThreadControllerForThread:(NSDictionary*)threadConfiguration;

-(void)startObservingSelf;
-(void)stopObservingSelf;

@end

@protocol NCStreamViewControllerDelegate <NSObject>

@required
-(NSArray*)streamViewControllerQueriedForStreamArray:(NCStreamViewController*)streamVc;
-(NSArray*)streamViewControllerQueriedPairedStreams:(NCStreamViewController*)streamVc;

@end

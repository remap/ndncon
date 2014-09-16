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

NSString* const kNameKey;
NSString* const kSynchornizedToKey;
NSString* const kInputDeviceKey;
NSString* const kThreadsArrayKey;

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

@property (nonatomic) NSString *streamName;
@property (assign) AVCaptureDevice *selectedDevice;
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

@end

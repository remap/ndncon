//
//  NCStreamViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

#import "NCPreferencesController.h"

NSString* const kNameKey;
NSString* const kSynchornizedToKey;
NSString* const kInputDeviceKey;
NSString* const kThreadsArrayKey;
NSString* const kBitrateKey;

/**
 * Base class for stream view controller
 */
@interface NCStreamViewController : NSViewController

@property (nonatomic, strong) NCPreferencesController *preferences;
@property (nonatomic, strong) NSMutableDictionary* configuration;

@property (nonatomic) NSString *streamName;
@property (assign) AVCaptureDevice *selectedDevice;
@property (assign) AVCaptureDeviceFormat *deviceFormat;

@end

//
//  NCPreferencesController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "PTNStorage.h"

@interface NCPreferencesController : PTNStorage

+(NCPreferencesController*)sharedInstance;

@property (nonatomic, getter=isFirstLaunch, setter=firstLaunch:) BOOL firstLaunch;

/**
 * General settings
 */
//@property (nonatomic) int logLevel;
@property (nonatomic) NSNumber* logLevel;

@property (nonatomic) NSString *prefix;
@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *daemonHost;
//@property (nonatomic) NSUInteger daemonPort;
@property (nonatomic) NSNumber *daemonPort;

@property (nonatomic) NSNumber *tlvEnabled;
@property (nonatomic) NSNumber *rtxEnabled;
@property (nonatomic) NSNumber *fecEnabled;
@property (nonatomic) NSNumber *cachingEnabled;
@property (nonatomic) NSNumber *avSyncEnabled;

@property (nonatomic) NSNumber *interestLifetimeMs;
@property (nonatomic) NSNumber *jitterSizeMs;
@property (nonatomic) NSNumber *bufferSize;
@property (nonatomic) NSNumber *slotSize;

@property (nonatomic) NSNumber *audioSegmentSize;
@property (nonatomic) NSNumber *audioFreshness;
@property (nonatomic) NSNumber *videoSegmentSize;
@property (nonatomic) NSNumber *videoFreshness;

@property (retain) NSArray *videoDevices;
@property (retain) NSArray *audioDevices;

@end

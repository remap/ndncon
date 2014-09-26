//
//  NCPreferencesController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "PTNStorage.h"

extern NSString* const kAudioStreamsKey;
extern NSString* const kVideoStreamsKey;
extern NSString* const kFreshnessPeriodKey;
extern NSString* const kSegmentSizeKey;

@interface NCPreferencesController : PTNStorage

+(NCPreferencesController*)sharedInstance;

@property (nonatomic, getter=isFirstLaunch, setter=firstLaunch:) BOOL firstLaunch;

/**
 * General settings
 */
@property (nonatomic) NSNumber* logLevel;

@property (nonatomic) NSString *prefix;
@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *daemonHost;
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

@property (nonatomic) NSArray *audioStreams;
@property (nonatomic) NSArray *videoStreams;

-(NSDictionary*)producerConfigurationCopy;

// NdnRtc library-specific
-(void)getNdnRtcGeneralParameters:(void*)generalParameters;
-(void)getNdnRtcGeneralProducerParameters:(void*)generalProducerParameters;
-(void)getNdnRtcGeneralConsumerParameters:(void*)generalConsumerParameters;

@end

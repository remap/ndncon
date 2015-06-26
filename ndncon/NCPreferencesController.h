//
//  NCPreferencesController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "PTNStorage.h"

#define CHATS_ENABLED
#define CONFERENCES_ENABLED

#define KEYPATH(s1, s2) ([NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(s1)), NSStringFromSelector(s2)])

#define KEYPATH2(s1, k2) ([NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(s1)), k2])
#define KEYPATH3(s1, k2, k3) ([NSString stringWithFormat:@"%@.%@.%@", NSStringFromSelector(@selector(s1)), k2, k3])

extern NSString* const kAudioStreamsKey;
extern NSString* const kVideoStreamsKey;
extern NSString* const kFreshnessPeriodKey;
extern NSString* const kSegmentSizeKey;

extern NSString* const kPrefixKey;
extern NSString* const kUserKey;

extern NSString* const kNdnHostKey;
extern NSString* const kNdnPortKey;


@interface NCPreferencesController : PTNStorage

+(NCPreferencesController*)sharedInstance;

@property (nonatomic, getter=isFirstLaunch, setter=firstLaunch:) BOOL firstLaunch;

@property (nonatomic, readonly) NSString *appName;
@property (nonatomic, readonly) NSString *versionString;

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

@property (nonatomic) NSString *chatBroadcastPrefix;
@property (nonatomic) NSString *conferenceBroadcastPrefix;
@property (nonatomic) NSString *userBroadcastPrefix;

@property (nonatomic) BOOL isReportingAsked;
@property (nonatomic) BOOL isReportingAllowed;

-(NSDictionary*)producerConfigurationCopy;
-(void)checkVersionParameters;

// NdnRtc library-specific
-(void)getNdnRtcGeneralParameters:(void*)generalParameters;
-(void)getNdnRtcGeneralProducerParameters:(void*)generalProducerParameters;
-(void)getNdnRtcGeneralConsumerParameters:(void*)generalConsumerParameters;

@end

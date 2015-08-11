//
//  NCPreferencesController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CoreFoundation.h>

#include <ndnrtc/params.h>
#include <ndnrtc/simple-log.h>

#import "NCPreferencesController.h"
#import "NSObject+NCAdditions.h"

NSString* const kFirstLaunchKey = @"First launch";
NSString* const kLastLaunchedVersionKey = @"Last launched version";
NSString* const kVersionUpdatesKey = @"Version updates";
NSString* const kGeneralSectionKey = @"General";
NSString* const kLogLevelKey = @"Log level";
NSString* const kLogLevelAll = @"all";
NSString* const kLogLevelDebug = @"debug";
NSString* const kLogLevelDefault = @"default";
NSString* const kLogLevelNone = @"none";

NSString* const kUseTlvKey = @"Use TLV";
NSString* const kRtxEnabledKey = @"Retransmissions enabled";
NSString* const kFecEnabledKey = @"FEC enabled";
NSString* const kAppCachingEnabledKey = @"App caching enabled";
NSString* const kAvSyncEnabledKey = @"AV sync enabled";
NSString* const kAudioEnabledKey = @"Audio enabled";
NSString* const kVideoEnabledKey = @"Video enabled";
NSString* const kSkipIncompleteKey = @"Skip incomplete frames";

NSString* const kPrefixKey = @"Default prefix";
NSString* const kUserKey = @"Default username";

NSString* const kNdnDaemonSectionKey = @"NDN daemon";
NSString* const kNdnHostKey = @"Host";
NSString* const kNdnPortKey = @"Port";

NSString* const kConsumerSectionKey = @"Consumer";
NSString* const kInterestLifetimeKey = @"Interest lifetime";
NSString* const kJitterSizeKey = @"Jitter size";
NSString* const kBufferSizeKey = @"Buffer size";
NSString* const kSlotSizeKey = @"Slot size";

NSString* const kProducerSectionKey = @"Producer";
NSString* const kAudioSectionKey = @"Audio";
NSString* const kVideoSectionKey = @"Video";
NSString* const kFreshnessPeriodKey = @"Freshness period";
NSString* const kSegmentSizeKey = @"Segment size";

NSString* const kAudioStreamsKey = @"Audio streams";
NSString* const kVideoStreamsKey = @"Video streams";

NSString* const kChatSectionKey = @"Chat";
NSString* const kChatBroadcastPrefixKey = @"Chat broadcast prefix";
NSString* const kChatroomBroadcastPrefixKey = @"Chatroom broadcast prefix";

NSString* const kConferenceSectionKey = @"Conference";
NSString* const kConferenceBroadcastPrefixKey = @"Conference broadcast prefix";

NSString* const kUserDiscoveryPrefix = @"User discovery prefix";

NSString* const kReportingAskedKey = @"Reporting was asked";
NSString* const kReportingAllowedKey = @"Reporting is allowed";

NSString* const kUserFetchOptionsArrayKey = @"User fetch options";
NSString* const kGlobalFetchOptionsArrayKey = @"Global fetch options";

NSString* const kUserFetchOptionFetchAudioKey = @"userFetchAudio";
NSString* const kUserFetchOptionFetchVideoKey = @"userFetchVideo";
NSString* const kUserFetchOptionDefaultAudioThreadsKey = @"userDefaultAudioThread";
NSString* const kUserFetchOptionDefaultVideoThreadsKey = @"userDefaultVideoThread";

NSString* const kNCGlobalFetchingFilterChangedNotification = @"GlobalFetchingFilterChangedNotification";
NSString* const kGlobalFetchingOptionsKey = @"filter";
NSString* const kPreviousGlobalFetchingOptionsKey = @"previousFilter";

NSDictionary* const DefaultUserFetchOptions = @{
                                                kUserFetchOptionFetchAudioKey:@YES,
                                                kUserFetchOptionFetchVideoKey:@YES
                                                };

NSDictionary* const LogLevels = @{kLogLevelAll: @(ndnlog::NdnLoggerDetailLevelAll),
                                  kLogLevelDebug: @(ndnlog::NdnLoggerDetailLevelDebug),
                                  kLogLevelDefault: @(ndnlog::NdnLoggerDetailLevelDefault),
                                  kLogLevelNone: @(ndnlog::NdnLoggerDetailLevelNone)};
NSDictionary* const LogLevelsStrings = @{@(ndnlog::NdnLoggerDetailLevelAll):kLogLevelAll,
                                         @(ndnlog::NdnLoggerDetailLevelDebug):kLogLevelDebug,
                                         @(ndnlog::NdnLoggerDetailLevelDefault):kLogLevelDefault,
                                         @(ndnlog::NdnLoggerDetailLevelNone):kLogLevelNone};

NSString* const kAutoFetchPrefixCmdArg = @"auto-fetch-prefix";
NSString* const kAutoFetchUserCmdArg = @"auto-fetch-user";
NSString* const kAutoFetchAudioCmdArg = @"auto-fetch-audio";
NSString* const kAutoFetchVideoCmdArg = @"auto-fetch-video";
NSString* const kAutoFetchStreamCmdArg = @"auto-fetch-stream";

using namespace ndnrtc;
using namespace ndnrtc::new_api;

@interface NCPreferencesController()

@property (nonatomic) NSArray *observers;

@end

@implementation NCPreferencesController

-(id)init
{
    if ((self = [super init]))
    {
        __weak NCPreferencesController *weakSelf = self;
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        id deviceWasConnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification
                                                                        object:nil
                                                                         queue:[NSOperationQueue mainQueue]
                                                                    usingBlock:^(NSNotification *note) {
                                                                        [weakSelf refreshDevices];
                                                                    }];
        id deviceWasDisconnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification
                                                                           object:nil
                                                                            queue:[NSOperationQueue mainQueue]
                                                                       usingBlock:^(NSNotification *note) {
                                                                           [weakSelf refreshDevices];
                                                                       }];
        id screenParametersChangedObserver = [notificationCenter addObserverForName:NSApplicationDidChangeScreenParametersNotification
                                                                     object:nil
                                                                      queue:[NSOperationQueue mainQueue]
                                                                 usingBlock:^(NSNotification *note) {
                                                                     [weakSelf refreshActiveDisplays];
                                                                 }];
        self.observers = [[NSArray alloc] initWithObjects: deviceWasConnectedObserver, deviceWasDisconnectedObserver, screenParametersChangedObserver, nil];
        
        [self refreshDevices];
        [self refreshActiveDisplays];
    }
    
    return self;
}

-(void)dealloc
{
    self.videoDevices = nil;
    self.audioDevices = nil;
    
    for (id observer in self.observers)
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    self.observers = nil;
}

- (void)refreshDevices
{
    [self setVideoDevices:[[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] arrayByAddingObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]]];
    [self setAudioDevices:[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio]];
}

-(void)refreshActiveDisplays
{
    self.activeDisplays = [NSScreen screens];
}

+(NCPreferencesController*)sharedInstance
{
    return (NCPreferencesController*)[super sharedInstance];
}

+(PTNStorage*)createInstance
{
    return [[NCPreferencesController alloc] init];
}

-(NSString *)appName
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
}

-(NSString *)versionString
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

-(BOOL)isFirstLaunch
{
    return [self getBoolWithName:kFirstLaunchKey];
}

-(void)firstLaunch:(BOOL)firstLaunch
{
    [self saveBool:firstLaunch forKey:kFirstLaunchKey];
}

-(void)setLogLevel:(NSNumber *)logLevelNum
{
    if (logLevelNum && [LogLevelsStrings objectForKey:logLevelNum])
    {
        [self saveParam:[LogLevelsStrings objectForKey:logLevelNum] atPathByComponents:kGeneralSectionKey, kLogLevelKey, nil];
    }
}

-(NSNumber*)logLevel
{
    return [LogLevels objectForKey:[self getParamAtPathByComponents:kGeneralSectionKey, kLogLevelKey, nil]];
}

-(NSString*)prefix
{
    return [self getParamAtPathByComponents:kGeneralSectionKey, kPrefixKey, nil];
}

-(void)setPrefix:(NSString *)prefix
{
    [self saveParam:prefix atPathByComponents:kGeneralSectionKey, kPrefixKey, nil];
}

-(NSString*)userName
{
    return [self getParamAtPathByComponents:kGeneralSectionKey, kUserKey, nil];
}

-(void)setUserName:(NSString *)userName
{
    [self saveParam:userName atPathByComponents:kGeneralSectionKey, kUserKey, nil];
}

-(NSString*)daemonHost
{
    return [self getParamAtPathByComponents:kGeneralSectionKey,
            kNdnDaemonSectionKey,
            kNdnHostKey, nil];
}

-(void)setDaemonHost:(NSString *)daemonHost
{
    [self saveParam:daemonHost atPathByComponents:kGeneralSectionKey,
     kNdnDaemonSectionKey,
     kNdnHostKey, nil];
}

-(NSNumber*)daemonPort
{
    return [self getParamAtPathByComponents:kGeneralSectionKey,
             kNdnDaemonSectionKey,
             kNdnPortKey, nil];
    
}

-(void)setDaemonPort:(NSNumber*)daemonPort
{
    [self saveParam:daemonPort atPathByComponents:kGeneralSectionKey,
     kNdnDaemonSectionKey,
     kNdnPortKey, nil];
    
}

-(void)setTlvEnabled:(NSNumber *)tlvEnabled
{
    [self saveParam:tlvEnabled atPathByComponents:kGeneralSectionKey, kUseTlvKey, nil];
}

-(NSNumber*)tlvEnabled
{
    return [self getParamAtPathByComponents:kGeneralSectionKey, kUseTlvKey, nil];
}

-(void)setRtxEnabled:(NSNumber*)rtxEnabled
{
    [self saveParam:rtxEnabled atPathByComponents:kGeneralSectionKey, kRtxEnabledKey, nil];
}

-(NSNumber*)rtxEnabled
{
    return [self getParamAtPathByComponents:kGeneralSectionKey, kRtxEnabledKey, nil];
}

-(void)setFecEnabled:(NSNumber*)fecEnabled
{
    [self saveParam:fecEnabled atPathByComponents:kGeneralSectionKey, kFecEnabledKey, nil];
}

-(NSNumber*)fecEnabled
{
    return [self getParamAtPathByComponents:kGeneralSectionKey, kFecEnabledKey, nil];
}

-(void)setCachingEnabled:(NSNumber*)cachingEnabled
{
    [self saveParam:cachingEnabled atPathByComponents:kGeneralSectionKey, kAppCachingEnabledKey, nil];
}

-(NSNumber*)cachingEnabled
{
    return [self getParamAtPathByComponents:kGeneralSectionKey, kAppCachingEnabledKey, nil];
}

-(void)setAvSyncEnabled:(NSNumber*)avSyncEnabled
{
    [self saveParam:avSyncEnabled atPathByComponents:kGeneralSectionKey, kAvSyncEnabledKey, nil];
}

-(NSNumber*)avSyncEnabled
{
    return [self getParamAtPathByComponents:kGeneralSectionKey, kAvSyncEnabledKey, nil];
}

-(void)setInterestLifetimeMs:(NSNumber *)interestLifetimeMs
{
    [self saveParam:interestLifetimeMs atPathByComponents:kConsumerSectionKey, kInterestLifetimeKey, nil];
}

-(NSNumber *)interestLifetimeMs
{
    return [self getParamAtPathByComponents:kConsumerSectionKey, kInterestLifetimeKey, nil];
}

-(void)setJitterSizeMs:(NSNumber *)jitterSizeMs
{
    [self saveParam:jitterSizeMs atPathByComponents:kConsumerSectionKey, kJitterSizeKey, nil];
}

-(NSNumber *)jitterSizeMs
{
    return [self getParamAtPathByComponents:kConsumerSectionKey, kJitterSizeKey, nil];
}

-(void)setBufferSize:(NSNumber *)bufferSize
{
    [self saveParam:bufferSize atPathByComponents:kConsumerSectionKey, kBufferSizeKey, nil];
}

-(NSNumber *)bufferSize
{
    return [self getParamAtPathByComponents:kConsumerSectionKey, kBufferSizeKey, nil];
}

-(void)setSlotSize:(NSNumber *)slotSize
{
    [self saveParam:slotSize atPathByComponents:kConsumerSectionKey, kSlotSizeKey, nil];
}

-(NSNumber *)slotSize
{
    return [self getParamAtPathByComponents:kConsumerSectionKey, kSlotSizeKey, nil];
}

-(NSNumber *)audioFreshness
{
    return [self getParamAtPathByComponents:kProducerSectionKey, kAudioSectionKey, kFreshnessPeriodKey, nil];
}

-(void)setAudioFreshness:(NSNumber *)audioFreshness
{
    [self saveParam:audioFreshness atPathByComponents:kProducerSectionKey, kAudioSectionKey, kFreshnessPeriodKey, nil];
}

-(NSNumber *)audioSegmentSize
{
    return [self getParamAtPathByComponents:kProducerSectionKey, kAudioSectionKey, kSegmentSizeKey, nil];
}

-(void)setAudioSegmentSize:(NSNumber *)audioSegmentSize
{
    [self saveParam:audioSegmentSize atPathByComponents:kProducerSectionKey, kAudioSectionKey, kSegmentSizeKey, nil];
}

-(NSNumber *)videoFreshness
{
    return [self getParamAtPathByComponents:kProducerSectionKey, kVideoSectionKey, kFreshnessPeriodKey, nil];
}

-(void)setVideoFreshness:(NSNumber *)videoFreshness
{
    [self saveParam:videoFreshness atPathByComponents:kProducerSectionKey, kVideoSectionKey, kFreshnessPeriodKey, nil];
}

-(NSNumber *)videoSegmentSize
{
    return [self getParamAtPathByComponents:kProducerSectionKey, kVideoSectionKey, kSegmentSizeKey, nil];
}

-(void)setVideoSegmentSize:(NSNumber *)videoSegmentSize
{
    [self saveParam:videoSegmentSize atPathByComponents:kProducerSectionKey, kVideoSectionKey, kSegmentSizeKey, nil];
}

-(NSArray *)audioStreams
{
    return [self getParamAtPathByComponents:kProducerSectionKey, kAudioStreamsKey, nil];
}

-(void)setAudioStreams:(NSArray *)audioStreams
{
    [self saveParam:audioStreams atPathByComponents:kProducerSectionKey, kAudioStreamsKey, nil];
}

-(NSArray *)videoStreams
{
    return [self getParamAtPathByComponents:kProducerSectionKey, kVideoStreamsKey, nil];
}

-(void)setVideoStreams:(NSArray *)videoStreams
{
    [self saveParam:videoStreams atPathByComponents:kProducerSectionKey, kVideoStreamsKey, nil];
}

-(NSString *)chatBroadcastPrefix
{
    return [self getParamAtPathByComponents:kChatSectionKey,kChatBroadcastPrefixKey, nil];
}

-(void)setChatBroadcastPrefix:(NSString *)chatBroadcastPrefix
{
    [self saveParam:chatBroadcastPrefix atPathByComponents:
     kChatSectionKey, kChatBroadcastPrefixKey, nil];
}

-(NSString *)chatroomBroadcastPrefix
{
    return [self getParamAtPathByComponents:kChatSectionKey,kChatroomBroadcastPrefixKey, nil];
}

-(void)setChatroomBroadcastPrefix:(NSString *)chatroomBroadcastPrefix
{
    [self saveParam:chatroomBroadcastPrefix atPathByComponents:kChatSectionKey, kChatroomBroadcastPrefixKey, nil];
}

-(NSString *)conferenceBroadcastPrefix
{
    return [self getParamAtPathByComponents:kConferenceSectionKey, kConferenceBroadcastPrefixKey, nil];
}

-(void)setConferenceBroadcastPrefix:(NSString *)conferenceBroadcastPrefix
{
    [self saveParam:conferenceBroadcastPrefix atPathByComponents:
     kConferenceSectionKey, kConferenceBroadcastPrefixKey, nil];
}

-(NSString *)userBroadcastPrefix
{
    return [self getParamAtPathByComponents:kUserDiscoveryPrefix, nil];
}

-(void)setUserBroadcastPrefix:(NSString *)userBroadcastPrefix
{
    [self saveParam:userBroadcastPrefix atPathByComponents:kUserDiscoveryPrefix, nil];
}

-(BOOL)isReportingAsked
{
    return [self getBoolWithName:kReportingAskedKey];
}

-(void)setIsReportingAsked:(BOOL)isReportingAsked
{
    [self saveBool:isReportingAsked forKey:kReportingAskedKey];
}

-(BOOL)isReportingAllowed
{
    return [self getBoolWithName:kReportingAllowedKey];
}

-(void)setIsReportingAllowed:(BOOL)isReportingAllowed
{
    [self saveBool:isReportingAllowed forKey:kReportingAllowedKey];
}

#pragma mark methods

-(NSDictionary *)producerConfigurationCopy
{
    return @{
             kAudioStreamsKey: self.audioStreams,
             kVideoStreamsKey: self.videoStreams
             };
}

-(void)checkVersionParameters
{
    NSString *currentVersion = self.versionString;
    NSString *lastVersion = [self getStringWithName:kLastLaunchedVersionKey];
    
    if (![currentVersion isEqualTo:lastVersion])
    {
        NSLog(@"New app version launched (previous was %@)" ,lastVersion);
        
        NSDictionary *versionUpdates = [[self.defaults valueForKey:kVersionUpdatesKey] valueForKey:currentVersion];;
        
        if (versionUpdates)
        {
            NSArray *updatePaths = [versionUpdates allKeys];
            
            for (NSString *updatePath in updatePaths)
            {
                id currentValue = [self getParamWithPath:updatePath];
                id updateValue = [versionUpdates valueForKey:updatePath];
                
                if (![currentValue isEqualTo:updateValue])
                {
                    NSLog(@"Updating '%@' for value '%@'", updatePath, updateValue);
                    [self saveParam:updateValue
                         forKeyPath:updatePath];
                }
            }
        }
    }
    
    [self saveParam:currentVersion atPathByComponents:kLastLaunchedVersionKey, nil];
}

-(void)getNdnRtcGeneralParameters:(void *)generalParameters
{
    GeneralParams* params = (GeneralParams*)generalParameters;
    
    params->logFile_ = "ndnrtc.log";
    params->logPath_ = "/tmp";
    params->loggingLevel_ = (ndnlog::NdnLoggerDetailLevel)self.logLevel.intValue;
    params->useTlv_ = self.tlvEnabled.boolValue;
    params->useRtx_ = self.rtxEnabled.boolValue;
    params->useFec_ = self.fecEnabled.boolValue;
    params->useCache_ = self.cachingEnabled.boolValue;
    params->useAudio_ = true;
    params->useVideo_ = true;
    params->useAvSync_ = true;
    params->skipIncomplete_ = true;
    params->prefix_ = std::string([self.prefix cStringUsingEncoding:NSUTF8StringEncoding]);
    params->host_ = std::string([self.daemonHost cStringUsingEncoding:NSUTF8StringEncoding]);
    params->portNum_ = self.daemonPort.intValue;
}

-(void)getNdnRtcGeneralProducerParameters:(void *)generalProducerParameters
{
    GeneralProducerParams* params = (GeneralProducerParams*)generalProducerParameters;
    
    params->segmentSize_ = self.videoSegmentSize.intValue;
    params->freshnessMs_ = self.videoFreshness.intValue;
}

-(void)getNdnRtcGeneralConsumerParameters:(void*)generalConsumerParameters
{
    GeneralConsumerParams* params = (GeneralConsumerParams*)generalConsumerParameters;
    
    params->bufferSlotsNum_ = self.bufferSize.intValue;
    params->jitterSizeMs_ = self.jitterSizeMs.intValue;
    params->interestLifetime_ = self.interestLifetimeMs.intValue;
    params->slotSize_ = self.slotSize.intValue;
}

// private
-(id)getParamAtPathByComponents:(id)comp1, ...
{
    NSMutableString *fullPath = [NSMutableString string];
    va_list args;
    va_start(args, comp1);
    for (NSString *arg = comp1; arg != nil; arg = va_arg(args, NSString*))
    {
        if ([fullPath length] > 0)
            [fullPath appendString:@"."];
        
        [fullPath appendString:arg];
    }
    va_end(args);
    
    return [self getParamWithPath:fullPath];
}

-(void)saveParam:(id)param atPathByComponents:(id)comp1, ...
{
    NSMutableString *fullPath = [NSMutableString string];
    va_list args;
    va_start(args, comp1);
    for (NSString *arg = comp1; arg != nil; arg = va_arg(args, NSString*))
    {
        if ([fullPath length] > 0)
            [fullPath appendString:@"."];
        
        [fullPath appendString:arg];
    }
    va_end(args);
    
    [self saveParam:param forKeyPath:fullPath];
}

-(void)setGlobalFetchOptions:(NSDictionary *)options
{
    NSDictionary *previousOptions = [self getGlobalFetchOptions];
    
    [self saveParam:options forKey:kGlobalFetchOptionsArrayKey];
    [self notifyNowWithNotificationName:kNCGlobalFetchingFilterChangedNotification
                            andUserInfo:@{kGlobalFetchingOptionsKey:options,
                                          kPreviousGlobalFetchingOptionsKey:previousOptions}];
}

-(NSDictionary*)getGlobalFetchOptions
{
    NSDictionary *globalFetchOptions = [self getParamWithName:kGlobalFetchOptionsArrayKey];
    
    if (!globalFetchOptions)
    {
        [self saveParam:globalFetchOptions forKey:kGlobalFetchOptionsArrayKey];
        return DefaultUserFetchOptions;
    }
    
    return globalFetchOptions;
}

-(void)setFetchOptions:(NSDictionary *)options forUser:(NSString *)username withPrefix:(NSString *)prefix
{
    NSMutableDictionary *userFetchOptions = nil;
    
    if (![self getParamWithName:kUserFetchOptionsArrayKey])
        userFetchOptions = [NSMutableDictionary dictionary];
    else
        userFetchOptions = [NSMutableDictionary dictionaryWithDictionary:[self getParamWithName:kUserFetchOptionsArrayKey]];

    NSString *userKey = [NSString stringWithFormat:@"%@:%@", username, prefix];
    
    userFetchOptions[userKey] = options;
    [self saveParam:userFetchOptions forKey:kUserFetchOptionsArrayKey];
}

-(void)addFetchOptions:(NSDictionary *)options forUser:(NSString *)username withPrefix:(NSString *)prefix
{
    NSMutableDictionary *userFetchOptions = nil;
    
    if (![self getParamWithName:kUserFetchOptionsArrayKey])
        userFetchOptions = [NSMutableDictionary dictionary];
    else
        userFetchOptions = [NSMutableDictionary dictionaryWithDictionary:[self getParamWithName:kUserFetchOptionsArrayKey]];
    
    NSString *userKey = [NSString stringWithFormat:@"%@:%@", username, prefix];
    
    if (userFetchOptions[userKey])
    {
        NSMutableDictionary *userOptions = [NSMutableDictionary dictionaryWithDictionary:userFetchOptions[userKey]];
        
        for (id key in options.keyEnumerator)
        {
            userOptions[key] = options[key];
        }
        
        userFetchOptions[userKey] = userOptions;
    }
    else
        userFetchOptions[userKey] = options;
    
    [self saveParam:userFetchOptions forKey:kUserFetchOptionsArrayKey];
}

-(NSDictionary *)getFetchOptionsForUser:(NSString *)username withPrefix:(NSString *)prefix
{
    NSMutableDictionary *userFetchOptions = [self getParamWithName:kUserFetchOptionsArrayKey];
    NSString *userKey = [NSString stringWithFormat:@"%@:%@", username, prefix];
    
    if (!userFetchOptions)
    {
        userFetchOptions = [NSMutableDictionary dictionaryWithObject:DefaultUserFetchOptions forKey:userKey];
        [self saveParam:userFetchOptions forKey:kUserFetchOptionsArrayKey];
        
        return DefaultUserFetchOptions;
    }
    
    return userFetchOptions[userKey];
}

@end

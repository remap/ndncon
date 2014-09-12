//
//  NCPreferencesController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCPreferencesController.h"
#include <ndnrtc/simple-log.h>

NSString* const kFirstLaunchKey = @"First launch";
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
NSString* const kUserNameKey = @"Default username";

NSString* const kNdnDaemonSectionKey = @"NDN daemon";
NSString* const kNdnHostKey = @"Host";
NSString* const kNdnPortKey = @"Port";

NSString* const kConsumerSectionKey = @"Consumer";
NSString* const kInterestLifetimeKey = @"Interest lifetime";
NSString* const kJitterSizeKey = @"Jitter size";
NSString* const kBufferSizeKey = @"Buffer size";
NSString* const kSlotSizeKey = @"Slot size";

NSDictionary* const LogLevels = @{kLogLevelAll: @(ndnlog::NdnLoggerDetailLevelAll),
                                  kLogLevelDebug: @(ndnlog::NdnLoggerDetailLevelDebug),
                                  kLogLevelDefault: @(ndnlog::NdnLoggerDetailLevelDefault),
                                  kLogLevelNone: @(ndnlog::NdnLoggerDetailLevelNone)};
NSDictionary* const LogLevelsStrings = @{@(ndnlog::NdnLoggerDetailLevelAll):kLogLevelAll,
                                         @(ndnlog::NdnLoggerDetailLevelDebug):kLogLevelDebug,
                                         @(ndnlog::NdnLoggerDetailLevelDefault):kLogLevelDefault,
                                         @(ndnlog::NdnLoggerDetailLevelNone):kLogLevelNone};



@implementation NCPreferencesController

+(NCPreferencesController*)sharedInstance
{
    return (NCPreferencesController*)[super sharedInstance];
}

+(PTNStorage*)createInstance
{
    return [[NCPreferencesController alloc] init];
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
    return [self getParamAtPathByComponents:kGeneralSectionKey, kUserNameKey, nil];
}

-(void)setUserName:(NSString *)userName
{
    [self saveParam:userName atPathByComponents:kGeneralSectionKey, kUserNameKey, nil];
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

@end

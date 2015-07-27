//
//  NSDictionary+NCAdditions.m
//  NdnCon
//
//  Created by Peter Gusev on 9/15/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NSDictionary+NCAdditions.h"
#import "NSArray+NCAdditions.h"

NSString* const kNameKey = @"Name";
NSString* const kSynchornizedToKey = @"Synchronized to";
NSString* const kInputDeviceKey = @"Input device";
NSString* const kThreadsArrayKey = @"Threads";
NSString* const kBitrateKey = @"Start bitrate";
NSString* const kFrameRateKey = @"Frame rate";
NSString* const kGopKey = @"GOP";
NSString* const kMaxBitrateKey = @"Max bitrate";
NSString* const kEncodingWidthKey = @"Encoding width";
NSString* const kEncodingHeightKey = @"Encoding height";
NSString* const kDeltaAverageSegNumKey = @"Average seg num delta";
NSString* const kDeltaAverageParSegNumKey = @"Average segpar num delta";
NSString* const kKeyAverageSegNumKey = @"Average seg num key";
NSString* const kKeyAverageParSegNumKey = @"Average segpar num key";

@implementation NSDictionary (NCAdditions)

-(BOOL)isVideoStream
{
    // dump check whether self contains info for a video stream
    // just checks whether first thread ocnfiguration has specific keys
    if (self[kThreadsArrayKey] && [self[kThreadsArrayKey] count] > 0)
    {
        NSDictionary *threadConf = self[kThreadsArrayKey][0];
        return threadConf[kEncodingHeightKey] && threadConf[kEncodingWidthKey] &&
        threadConf[kFrameRateKey] && threadConf[kGopKey];
    }
    
    return NO;
}

-(NSMutableDictionary *)deepMutableCopy
{
    NSMutableDictionary *deepMutableCopy = [self mutableCopy];
    
    for (id key in deepMutableCopy.allKeys)
    {
        id value = [deepMutableCopy objectForKey:key];
        
        if ([value isKindOfClass:[NSArray class]])
            [deepMutableCopy setValue:[(NSArray*)value deepMutableCopy]
                           forKeyPath:key];
        else if ([value isKindOfClass:[NSDictionary class]])
            [deepMutableCopy setValue:[(NSDictionary*)value deepMutableCopy]
                           forKeyPath:key];
        else if ([value conformsToProtocol:@protocol(NSMutableCopying)])
            [deepMutableCopy setValue:[value mutableCopy] forKeyPath:key];
        else
            [deepMutableCopy setValue:value forKey:key];
        
    }
    
    return deepMutableCopy;
}

-(NSArray *)threadIds
{
    if (self[kNameKey] &&
        self[kThreadsArrayKey])
    {
        __block NSMutableArray *threadIds = [NSMutableArray array];
        
        [self[kThreadsArrayKey] enumerateObjectsUsingBlock:^(NSDictionary *threadConf, NSUInteger idx, BOOL *stop) {
            [threadIds addObject:[NSString stringWithFormat:@"%@:%@", self[kNameKey], threadConf[kNameKey]]];
        }];
        
        return [NSArray arrayWithArray:threadIds];
    }
    
    return @[];
}

-(NSString *)mediaThreadFullHint
{
    if (self[kNameKey] &&
        self[kEncodingWidthKey] &&
        self[kEncodingHeightKey] &&
        self[kBitrateKey])
    {
        return [NSString stringWithFormat:@"%@ (%@x%@ %@ kBit/s)",
                self[kNameKey],
                self[kEncodingWidthKey],
                self[kEncodingHeightKey],
                self[kBitrateKey]];
    }
    else if (self[kNameKey] &&
             self[kBitrateKey])
    {
        return [NSString stringWithFormat:@"%@ (%@ kBit/s)",
                self[kNameKey],
                self[kBitrateKey]];
    }
    
    return @"";
}

-(NSString *)mediaThreadShortHint
{
    if (
        self[kEncodingWidthKey] &&
        self[kEncodingHeightKey] &&
        self[kBitrateKey])
    {
        return [NSString stringWithFormat:@"%@x%@ (%@ kBit/s)",
                self[kEncodingWidthKey],
                self[kEncodingHeightKey],
                self[kBitrateKey]];
    }
    else if (self[kBitrateKey])
    {
        return [NSString stringWithFormat:@"%@ kBit/s",
                self[kBitrateKey]];
    }
    
    return @"";
}

@end

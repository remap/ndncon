//
//  NSDictionary+NCAdditions.h
//  NdnCon
//
//  Created by Peter Gusev on 9/15/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const kNameKey;
extern NSString* const kSynchornizedToKey;
extern NSString* const kInputDeviceKey;
extern NSString* const kThreadsArrayKey;
extern NSString* const kBitrateKey;
extern NSString* const kFrameRateKey;
extern NSString* const kGopKey;
extern NSString* const kMaxBitrateKey;
extern NSString* const kEncodingWidthKey;
extern NSString* const kEncodingHeightKey;
extern NSString* const kDeltaAverageSegNumKey;
extern NSString* const kDeltaAverageParSegNumKey;
extern NSString* const kKeyAverageSegNumKey;
extern NSString* const kKeyAverageParSegNumKey;

@interface NSDictionary (NCAdditions)

-(BOOL)isVideoStream;

-(NSMutableDictionary*)deepMutableCopy;

-(NSArray*)threadIds;
-(NSString*)mediaThreadFullHint;
-(NSString*)mediaThreadShortHint;

@end

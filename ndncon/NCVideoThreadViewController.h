//
//  NCVideoThread.h
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCThreadViewController.h"

extern NSString* const kFrameRateKey;
extern NSString* const kGopKey;
extern NSString* const kMaxBitrateKey;
extern NSString* const kEncodingWidthKey;
extern NSString* const kEncodingHeightKey;
extern NSString* const kDeltaAverageSegNumKey;
extern NSString* const kDeltaAverageParSegNumKey;
extern NSString* const kKeyAverageSegNumKey;
extern NSString* const kKeyAverageParSegNumKey;

@interface NCVideoThreadViewController : NCThreadViewController

@end

//
//  NCVideoThread.h
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCThreadViewController.h"

NSString* const kFrameRateKey;
NSString* const kGopKey;
NSString* const kMaxBitrateKey;
NSString* const kEncodingWidthKey;
NSString* const kEncodingHeightKey;

@interface NCVideoThreadViewController : NCThreadViewController

+(NSDictionary*)defaultVideoThreadConfiguration;

@end

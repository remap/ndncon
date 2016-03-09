//
//  NCStatisticCollector.h
//  NdnCon
//
//  Created by Peter Gusev on 3/8/16.
//  Copyright © 2016 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTNSingleton.h"

@interface NCStatisticCollector : PTNSingleton

+(NCStatisticCollector*)sharedInstance;

@property (nonatomic, readonly) BOOL isRunning;

-(void)start;
-(void)stop;

@end

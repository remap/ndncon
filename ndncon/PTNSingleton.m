//
//  PTNSingleton.m
//  PTNAdditions
//
//  Created by Peter Gusev on 3/28/14.
//  Copyright (c) 2014 peetonn inc. All rights reserved.
//

#import "PTNSingleton.h"

@implementation PTNSingleton

+(PTNSingleton*)sharedInstance
{
    static PTNSingleton *singleton = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [[self class] createInstance];
    });
    
    return singleton;
}

+(PTNSingleton*)createInstance
{
    return [[PTNSingleton alloc] init];
}

@end

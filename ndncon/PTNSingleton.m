//
//  PTNSingleton.m
//  PTNAdditions
//
//  Created by Peter Gusev on 3/28/14.
//  Copyright 2013-2015 Regents of the University of California
//

#import "PTNSingleton.h"

@implementation PTNSingleton

static PTNSingleton *singleton = nil;

static NSMutableDictionary *ClassToSingletonMap;

+(PTNSingleton*)sharedInstance
{
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            ClassToSingletonMap = [[NSMutableDictionary alloc] init];
        });
    }
    
    __block PTNSingleton *singleton = ClassToSingletonMap[NSStringFromClass([self class])];
    
    if (!singleton)
    {
        dispatch_once_t* onceToken = [[self class] token];
        dispatch_once(onceToken, ^{
            singleton = [[[self class] alloc] init];
            ClassToSingletonMap[NSStringFromClass([self class])] = singleton;
        });
    }
    
    return singleton;
}

+(PTNSingleton*)createInstance
{
    return [[PTNSingleton alloc] init];
}

+(dispatch_once_t*)token
{
    static dispatch_once_t token;
    return &token;
}

@end

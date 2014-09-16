//
//  NSArray+NCAdditions.m
//  NdnCon
//
//  Created by Peter Gusev on 9/15/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NSArray+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"

@implementation NSArray (NCAdditions)

-(NSMutableArray *)deepMutableCopy
{
    NSMutableArray *deepMutableCopy = [NSMutableArray array];
    
    for (id object in self)
    {
        if ([object isKindOfClass:[NSDictionary class]])
            [deepMutableCopy addObject:[(NSDictionary*)object deepMutableCopy]];
        else if ([object isKindOfClass:[NSArray class]])
            [deepMutableCopy addObject:[(NSArray*)object deepMutableCopy]];
        else if ([object conformsToProtocol:@protocol(NSMutableCopying)])
            [deepMutableCopy addObject:[object mutableCopy]];
        else
            [deepMutableCopy addObject:object];
    }
    
    return deepMutableCopy;
}

@end

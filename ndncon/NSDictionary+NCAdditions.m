//
//  NSDictionary+NCAdditions.m
//  NdnCon
//
//  Created by Peter Gusev on 9/15/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NSDictionary+NCAdditions.h"
#import "NSArray+NCAdditions.h"

@implementation NSDictionary (NCAdditions)

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

@end

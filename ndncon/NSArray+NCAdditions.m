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

-(id)objectAtIndexOrNil:(NSUInteger)index
{
    if (index >= self.count)
        return nil;
    
    return [self objectAtIndex:index];
}

-(id)objectAtSignedIndexOrNil:(NSInteger)index
{
    if (index >= 0)
        return [self objectAtIndexOrNil:index];
    else
        return [self objectAtIndexOrNil:self.count+index];
}

-(NSArray *)arrayByRemovingObject:(id)object
{
    NSMutableArray *arrayCopy = [self mutableCopy];
    [arrayCopy removeObject:object];
    
    return [NSArray arrayWithArray:arrayCopy];
}

@end

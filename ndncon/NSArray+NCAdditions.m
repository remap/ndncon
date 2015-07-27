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

// returns stream configuration with given name
// if self is an array of stream configurations
-(NSDictionary *)streamWithName:(NSString *)streamName
{
    if ([[self valueForKey:kNameKey] indexOfObject:streamName] != NSNotFound)
    {
        __block NSDictionary *stream = nil;
        [self enumerateObjectsUsingBlock:^(NSDictionary *streamConf, NSUInteger idx, BOOL *stop) {
            if ([streamConf[kNameKey] isEqualToString:streamName])
            {
                stream = streamConf;
                *stop = YES;
            }
        }];
        
        return stream;
    }

    return nil;
}

// returns thread configuration with given name
// if self is an array of thread configurations
-(NSDictionary *)threadWithName:(NSString *)threadName
{
    if ([[self valueForKey:kNameKey] indexOfObject:threadName] != NSNotFound)
    {
        __block NSDictionary *thread = nil;
        [self enumerateObjectsUsingBlock:^(NSDictionary *threadConf, NSUInteger idx, BOOL *stop) {
            if ([threadConf[kNameKey] isEqualToString:threadName])
            {
                thread = threadConf;
                *stop = YES;
            }
        }];
        
        return thread;
    }
    
    return nil;
}

@end

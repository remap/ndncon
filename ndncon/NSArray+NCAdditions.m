//
//  NSArray+NCAdditions.m
//  NdnCon
//
//  Created by Peter Gusev on 9/15/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#define CATEGORY_PROPERTY_GET(type, property) - (type) property { return objc_getAssociatedObject(self, @selector(property)); }
#define CATEGORY_PROPERTY_SET(type, property, setter) - (void) setter (type) property { objc_setAssociatedObject(self, @selector(property), property, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
#define CATEGORY_PROPERTY_GET_SET(type, property, setter) CATEGORY_PROPERTY_GET(type, property) CATEGORY_PROPERTY_SET(type, property, setter)

#define CATEGORY_PROPERTY_GET_NSNUMBER_PRIMITIVE(type, property, valueSelector) - (type) property { return [objc_getAssociatedObject(self, @selector(property)) valueSelector]; }
#define CATEGORY_PROPERTY_SET_NSNUMBER_PRIMITIVE(type, property, setter, numberSelector) - (void) setter (type) property { objc_setAssociatedObject(self, @selector(property), [NSNumber numberSelector: property], OBJC_ASSOCIATION_RETAIN_NONATOMIC); }

#define CATEGORY_PROPERTY_GET_UINT(property) CATEGORY_PROPERTY_GET_NSNUMBER_PRIMITIVE(unsigned int, property, unsignedIntValue)
#define CATEGORY_PROPERTY_SET_UINT(property, setter) CATEGORY_PROPERTY_SET_NSNUMBER_PRIMITIVE(unsigned int, property, setter, numberWithUnsignedInt)
#define CATEGORY_PROPERTY_GET_SET_UINT(property, setter) CATEGORY_PROPERTY_GET_UINT(property) CATEGORY_PROPERTY_SET_UINT(property, setter)

#import <objc/runtime.h>
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

@implementation NSMutableArray (NCCircularArray)

CATEGORY_PROPERTY_GET_SET_UINT(circularBufferSize, setCircularBufferSize:)
CATEGORY_PROPERTY_GET_SET_UINT(currentIndex, setCurrentIndex:)

-(instancetype)initCircularArrayWithSize:(unsigned int)size
{
    self = [self init];
    self.circularBufferSize = size;
    self.currentIndex = 0;
    
    return self;
}

-(void)push:(id)object
{
    if (self.currentIndex == self.circularBufferSize)
        self.currentIndex = 0;
    
    [self insertObject:object atIndex:self.currentIndex++];
    
    if (self.count > self.circularBufferSize)
        [self removeObjectAtIndex:self.currentIndex];
}

-(float)average
{
    return [[self valueForKeyPath:@"@avg.floatValue"] floatValue];
}

@end

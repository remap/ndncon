//
//  NSString+NdnRtcNamespace.m
//  NdnCon
//
//  Created by Peter Gusev on 9/30/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndnrtc/name-components.h>

#import "NSString+NdnRtcNamespace.h"

using namespace ndnrtc;

@interface NSString (NdnRtcNamespace_Private)

-(BOOL)hasNdnRtcNameComponent:(const std::string&)component index:(NSUInteger&)index;

@end

@implementation NSString (NdnRtcNamespace)

-(BOOL)hasNdnRtcNameComponent:(std::string&)component index:(NSUInteger&)index;
{
    NSArray *components = [self pathComponents];
    
    if ([components containsObject:[NSString ncStringFromCString:component.c_str()]])
    {
        index = [components indexOfObject:[NSString ncStringFromCString:component.c_str()]];
        return YES;
    }
    
    return NO;
}

+(NSString*)ncStringFromCString:(const char*)cString
{
    return [NSString stringWithCString:(const char*)cString encoding:NSASCIIStringEncoding];
}

+(NSString *)keyPathByComponents:(NSString *)comp1, ...
{
    NSMutableString *fullPath = [NSMutableString string];
    va_list args;
    va_start(args, comp1);
    for (NSString *arg = comp1; arg != nil; arg = va_arg(args, NSString*))
    {
        if ([fullPath length] > 0)
            [fullPath appendString:@"."];
        
        [fullPath appendString:arg];
    }
    va_end(args);
    
    return fullPath;
}

-(NSString*)getNdnRtcHubPrefix
{
    NSUInteger idx = NSNotFound;
    
    if ([self hasNdnRtcNameComponent:NameComponents::NameComponentApp index:idx])
    {
        NSArray *components = [self pathComponents];
        NSArray *hubPrefix = [components subarrayWithRange:NSMakeRange(0, idx)];
        return [NSString pathWithComponents:hubPrefix];
    }

    return nil;
}

-(NSString*)getNdnRtcUserName
{
    NSArray *components = [self pathComponents];
    NSUInteger userNameIdx = NSNotFound;
    
    if ([self hasNdnRtcNameComponent:NameComponents::NameComponentUser index:userNameIdx]
        && components.count > userNameIdx+1)
    {
        return [components objectAtIndex:userNameIdx+1];
    }
    
    return nil;
}

-(NSString*)getNdnRtcStreamName
{
    NSArray *components = [self pathComponents];
    NSUInteger streamNameIdx = NSNotFound;
    
    if ([self hasNdnRtcNameComponent:NameComponents::NameComponentUserStreams index:streamNameIdx] &&
        components.count > streamNameIdx+1)
    {
        return [components objectAtIndex:streamNameIdx+1];
    }
    
    return nil;
}


-(NSString*)getNdnRtcThreadName
{
    NSArray *components = [self pathComponents];
    NSUInteger streamNameIdx = NSNotFound;
    
    if ([self hasNdnRtcNameComponent:NameComponents::NameComponentUserStreams index:streamNameIdx] &&
        components.count > streamNameIdx+2)
    {
        return [components objectAtIndex:streamNameIdx+2];
    }
    
    return nil;
}
@end

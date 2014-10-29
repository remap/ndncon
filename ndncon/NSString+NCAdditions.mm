//
//  NSString+NdnRtcNamespace.m
//  NdnCon
//
//  Created by Peter Gusev on 9/30/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndnrtc/name-components.h>

#import <CommonCrypto/CommonDigest.h>
#import "NSString+NCAdditions.h"

using namespace ndnrtc;

#define NRTC_PREFIX @"nrtc"
NSString* const kNrtcUrlRegExp = @"nrtc:([//[A-z0-9-+@]+]*):([A-z0-9-+@]+)";
NSString* const kNCNdnRtcUserUrlFormat = @"nrtc:%@:%@";

@interface NSString (NCAdditions_Private)

-(BOOL)hasNdnRtcNameComponent:(const std::string&)component index:(NSUInteger&)index;

@end

@implementation NSString (NCAdditions)

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

-(NSString *)md5Hash
{
    const char *cstr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

-(NSString*)prefixFromNrtcUrlString
{
    if ([self isValidNrtcUrl])
    {
        NSRegularExpression *urlRegex = [NSRegularExpression regularExpressionWithPattern:kNrtcUrlRegExp
                                                                                  options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [urlRegex matchesInString:self options:0 range:NSMakeRange(0, [self length])];
        return [self  substringWithRange:[matches[0] rangeAtIndex:1]];
    }
    
    return nil;
}

-(NSString*)userNameFromNrtcUrlString
{
    if ([self isValidNrtcUrl])
    {
        NSRegularExpression *urlRegex = [NSRegularExpression regularExpressionWithPattern:kNrtcUrlRegExp
                                                                                  options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [urlRegex matchesInString:self options:0 range:NSMakeRange(0, [self length])];
        return [self  substringWithRange:[matches[0] rangeAtIndex:2]];
    }
    
    return nil;
}

#pragma mark - private
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

-(BOOL)isValidNrtcUrl
{
    NSRegularExpression *urlRegex = [NSRegularExpression regularExpressionWithPattern:kNrtcUrlRegExp
                                                                              options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *matches = [urlRegex matchesInString:self options:0 range:NSMakeRange(0, [self length])];
    
    if (matches)
        for (NSTextCheckingResult *match in matches)
            if ([match numberOfRanges] == 3)
                return YES;
    
    return NO;
}

@end

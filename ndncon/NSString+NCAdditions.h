//
//  NSString+NdnRtcNamespace.h
//  NdnCon
//
//  Created by Peter Gusev on 9/30/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Foundation/Foundation.h>

extern NSString* const kNCNdnRtcUserUrlFormat;

@interface NSString (NCAdditions)

+(NSString*)ncStringFromCString:(const char*)cString;
+(NSString*)keyPathByComponents:(NSString*)comp1, ...;

+(NSString*)userSessionPrefixForUser:(NSString *)username
                        withHubPrefix:(NSString *)hubPrefix;
+(NSString*)streamPrefixForStream:(NSString*)streamName
                             user:(NSString*)username
                       withPrefix:(NSString*)prefix;
+(NSString*)threadPrefixForThread:(NSString*)threadName
                           stream:(NSString*)streamName
                             user:(NSString*)username
                       withPrefix:(NSString*)prefix;
+(NSString*)chatroomPrefixForChat:(NSString*)chatroomName
                             user:(NSString*)username
                       withPrefix:(NSString*)hubPrefix;

+(NSString*)ndnRtcAppNameComponent;
+(NSString*)ndnRtcSessionInfoComponent;

+(NSString*)userIdWithName:(NSString*)username andPrefix:(NSString*)prefix;
+(NSString*)userNameFromIdString:(NSString*)userIdString;
+(NSString*)userPrefixFromIdString:(NSString*)userIdString;

-(NSString*)getNdnRtcHubPrefix;
-(NSString*)getNdnRtcSessionPrefix;
-(NSString*)getNdnRtcUserName;
-(NSString*)getNdnRtcStreamName;
-(NSString*)getNdnRtcThreadName;

-(NSString*)md5Hash;

// returns a prefix if the receiver is a NRTC URL string
// @see kNCNdnRtcUserUrlFormat
-(NSString*)prefixFromNrtcUrlString;
// returns a username if the receiver is a NRTC URL string
// @see kNCNdnRtcUserUrlFormat
-(NSString*)userNameFromNrtcUrlString;

-(NSString*)stringByAppendingNdnComponent:(NSString*)ndnComponent;

@end

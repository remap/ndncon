//
//  NSString+NdnRtcNamespace.h
//  NdnCon
//
//  Created by Peter Gusev on 9/30/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const kNCNdnRtcUserUrlFormat;

@interface NSString (NCAdditions)

+(NSString*)ncStringFromCString:(const char*)cString;
+(NSString*)keyPathByComponents:(NSString*)comp1, ...;
+(NSString *)userSessionPrefixForUser:(NSString *)username
                        withHubPrefix:(NSString *)hubPrefix;
+(NSString*)ndnRtcAppNameComponent;

-(NSString*)getNdnRtcHubPrefix;
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

@end

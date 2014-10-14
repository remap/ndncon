//
//  NSString+NdnRtcNamespace.h
//  NdnCon
//
//  Created by Peter Gusev on 9/30/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NCAdditions)

+(NSString*)ncStringFromCString:(const char*)cString;
+(NSString*)keyPathByComponents:(NSString*)comp1, ...;

-(NSString*)getNdnRtcHubPrefix;
-(NSString*)getNdnRtcUserName;
-(NSString*)getNdnRtcStreamName;
-(NSString*)getNdnRtcThreadName;

-(NSString*)md5Hash;

@end

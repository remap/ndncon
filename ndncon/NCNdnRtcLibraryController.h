//
//  NCNdnRtcLibraryController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/18/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const NCSessionStatusUpdateNotification;
extern NSString* const NCSessionErrorNotification;

extern NSString* const kNCSessionUsernameKey;
extern NSString* const kNCSessionPrefixKey;
extern NSString* const kNCSessionStatusKey;
extern NSString* const kNCSessionErrorCodeKey;
extern NSString* const kNCSessionErrorMessageKey;

typedef enum : NSUInteger {
    SessionStatusOffline,
    SessionStatusOnlineNotPublishing,
    SessionStatusOnlinePublishing,
} NCSessionStatus;

@interface NCNdnRtcLibraryController : NSObject

@property (nonatomic, readonly) NCSessionStatus sessionStatus;
@property (nonatomic, readonly) NSString *sessionPrefix;

+(NCNdnRtcLibraryController*)sharedInstance;

-(void*)getLibraryObject;

-(BOOL)startSession;
-(BOOL)stopSession;

-(NSImage*)imageForSessionStatus:(NCSessionStatus)status;

@end

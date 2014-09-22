//
//  NCNdnRtcLibraryController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/18/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const NCSessionStatusUpdateNotificaiton;
extern NSString* const NCSessionErrorNotificaiton;

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

-(void)instantiateLibrary;
-(void*)getLibraryObject;
-(void)releaseLibrary;

-(BOOL)startSession;
-(BOOL)stopSession;



@end
//
//  NCNdnRtcLibraryController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/18/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Foundation/Foundation.h>

extern NSString* const NCLocalSessionStatusUpdateNotification;
extern NSString* const NCLocalSessionErrorNotification;
extern NSString* const NCRemoteSessionStatusUpdateNotification;
extern NSString* const NCRemoteSessionErrorNotification;

extern NSString* const kSessionUsernameKey;
extern NSString* const kSessionPrefixKey;
extern NSString* const kSessionStatusKey;
extern NSString* const kSessionOldStatusKey;
extern NSString* const kSessionErrorCodeKey;
extern NSString* const kSessionErrorMessageKey;

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
-(void)releaseLibrary;

-(BOOL)startSession;
-(BOOL)stopSession;

-(NSImage*)imageForSessionStatus:(NCSessionStatus)status;

@end

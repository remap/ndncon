//
//  NCDiscoveryLibraryController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "PTNSingleton.h"
#import "Conference.h"
#import "NCSessionInfoContainer.h"

extern NSString* const NCConferenceDiscoveredNotification;
extern NSString* const NCConferenceWithdrawedNotification;
extern NSString* const NCConferenceUpdatedNotificaiton;

extern NSString* const NCUserDiscoveredNotification;
extern NSString* const NCUserWithdrawedNotification;
extern NSString* const NCUserUpdatedNotificaiton;

//******************************************************************************
@interface NCEntityDiscoveryController : PTNSingleton
@end

//******************************************************************************
@interface NCConferenceDiscoveryController : NCEntityDiscoveryController

+(NCConferenceDiscoveryController*)sharedInstance;

@property (nonatomic, readonly) NSArray *discoveredConferences;

-(void)announceConference:(Conference*)conference;
-(void)withdrawConference:(Conference*)conference;

@end


//******************************************************************************
@interface NCActiveUserInfo : NSObject

@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *prefix;
@property (nonatomic, readonly) NCSessionInfoContainer *sessionInfo;

@end

//******************************************************************************
@interface NCUserDiscoveryController : NCEntityDiscoveryController

+(NCUserDiscoveryController*)sharedInstance;

@property (nonatomic, readonly) NSArray *discoveredUsers;

-(void)announceInfo:(NCSessionInfoContainer*)sessionInfo;
-(void)withdrawInfo;

@end
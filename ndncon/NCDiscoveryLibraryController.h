//
//  NCDiscoveryLibraryController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "PTNSingleton.h"
#import "Conference.h"

extern NSString* const NCConferenceDiscoveredNotification;
extern NSString* const NCConferenceWithdrawedNotification;

//******************************************************************************
@interface NCDiscoveryLibraryController : PTNSingleton

+(NCDiscoveryLibraryController*)sharedInstance;

@property (nonatomic) NSArray *discoveredConferences;

-(void)announceConference:(Conference*)conference;
-(void)withdrawConference:(Conference*)conference;

@end

//
//  NCDiscoveryLibraryController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright 2013-2015 Regents of the University of California.
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

extern NSString* const NCChatroomDiscoveredNotification;
extern NSString* const NCChatroomWithdrawedNotification;
extern NSString* const NCChatroomUpdatedNotificaiton;
extern NSString* const kChatroomKey;

//******************************************************************************
@interface NCEntityDiscoveryController : PTNSingleton
@end

//******************************************************************************
@interface NCActiveUserInfo : NSObject

@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *sessionPrefix;
@property (nonatomic, readonly) NSString *hubPrefix;
@property (nonatomic) NCSessionInfoContainer *sessionInfo;
@property (nonatomic, readonly) NSArray *streamConfigurations;

-(NSArray*)getDefaultFetchAudioThreads;
-(NSArray*)getDefaultFetchVideoThreads;

@end

//******************************************************************************
@interface NCUserDiscoveryController : NCEntityDiscoveryController

+(NCUserDiscoveryController*)sharedInstance;

@property (nonatomic, readonly) NSArray *discoveredUsers;

-(NCActiveUserInfo*)userWithName:(NSString*)username andHubPrefix:(NSString*)prefix;
-(void)announceInfo:(NCSessionInfoContainer*)sessionInfo;
-(void)withdrawInfo;

@end

//******************************************************************************
@interface NCChatRoom : NSObject

/**
 * Creates chatroom object
 * @param chatroomName The name of the chatroom
 * @param participantsArray Array of session prefixes (hubprefix + username) of 
 *  participants
 */
+(NCChatRoom*)chatRoomWithName:(NSString*)chatroomName
               andParticipants:(NSArray*)participantsArray;

@property (nonatomic, readonly) NSString *chatroomName;
@property (nonatomic, readonly) NSArray *participants;

@end

//******************************************************************************
@interface NCChatroomDiscoveryController : NCEntityDiscoveryController

+(NCChatroomDiscoveryController*)sharedInstance;

@property (nonatomic, readonly) NSArray *discoveredChatrooms;

-(NCChatRoom*)chatroomWithName:(NSString*)chatroomName;

-(void)announceChatroom:(NCChatRoom*)chatroom;
-(void)withdrawChatroom:(NCChatRoom*)chatroom;
-(void)withdrawAllChatrooms;

@end

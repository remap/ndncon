//
//  NCChatLibraryController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/13/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Foundation/Foundation.h>
#import "PTNSingleton.h"
#import "NCDiscoveryLibraryController.h"

extern NSString* const NCChatMessageNotification;
extern NSString* const NCChatMessageTypeKey;
extern NSString* const NCChatMessageUsernameKey;
extern NSString* const NCChatMessageTimestampKey;
extern NSString* const NCChatMessageBodyKey;
extern NSString* const NCChatRoomIdKey;
extern NSString* const NCChatMessageUserKey;

@interface NCChatLibraryController : PTNSingleton

+(NCChatLibraryController*)sharedInstance;
+(NSString*)privateChatRoomIdWithUser:(NSString*)userPrefix;

-(void)joinChatroom:(NCChatRoom*)chatroom;
-(void)sendMessage:(NSString*)message toChat:(NSString*)chatId;
-(void)leaveChat:(NSString*)chatId;
-(void)leaveAllChatRooms;

@end

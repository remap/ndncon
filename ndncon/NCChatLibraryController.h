//
//  NCChatLibraryController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/13/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTNSingleton.h"

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

-(NSString*)startChatWithUser:(NSString*)userPrefix;
-(void)sendMessage:(NSString*)message toChat:(NSString*)chatId;
-(void)leaveChat:(NSString*)chatId;
-(void)leaveAllChatRooms;

@end

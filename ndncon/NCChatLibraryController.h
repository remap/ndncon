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

extern NSString* const kChatMesageTypeJoin;
extern NSString* const kChatMesageTypeLeave;
extern NSString* const kChatMesageTypeText;

@interface NCChatLibraryController : PTNSingleton

+(NCChatLibraryController*)sharedInstance;

-(NSString*)startChatWithUser:(NSString*)userPrefix;
-(void)sendMessage:(NSString*)message toChat:(NSString*)chatId;
-(void)leaveChat:(NSString*)chatId;
-(void)initChatRooms;
-(void)leaveAllChatRooms;

@end

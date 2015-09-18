//
//  ChatMessage.h
//  NdnCon
//
//  Created by Peter Gusev on 10/14/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User, ChatRoom;

extern NSString* const kChatMesageTypeJoin;
extern NSString* const kChatMesageTypeLeave;
extern NSString* const kChatMesageTypeText;

@interface ChatMessage : NSManagedObject

+(ChatMessage*)newChatMessageFromUser:(User*)user
                            ofType:(NSString*)messageType
                   withMessageBody:(NSString*)body
                            inContext:(NSManagedObjectContext*)context;

+(NSArray*)unreadTextMessagesFromUser:(User*)user
                           inChatroom:(ChatRoom*)chatroom;

+(NSNumber*)typeFromString:(NSString*)typeStr;

@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSDate * read;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSManagedObject *chatRoom;
@property (nonatomic, retain) User *user;

@end

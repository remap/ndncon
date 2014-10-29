//
//  ChatMessage.h
//  NdnCon
//
//  Created by Peter Gusev on 10/14/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

extern NSString* const kChatMesageTypeJoin;
extern NSString* const kChatMesageTypeLeave;
extern NSString* const kChatMesageTypeText;

@interface ChatMessage : NSManagedObject

+(ChatMessage*)newChatMessageFromUser:(User*)user
                            ofType:(NSString*)messageType
                   withMessageBody:(NSString*)body
                            inContext:(NSManagedObjectContext*)context;
+(NSNumber*)typeFromString:(NSString*)typeStr;

@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSManagedObject *chatRoom;
@property (nonatomic, retain) User *user;

@end

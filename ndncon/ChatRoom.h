//
//  ChatRoom.h
//  NdnCon
//
//  Created by Peter Gusev on 10/14/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChatMessage;

@interface ChatRoom : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * roomId;
@property (nonatomic, retain) NSSet *messages;
@end

@interface ChatRoom (CoreDataGeneratedAccessors)

+(ChatRoom*)chatRoomWithId:(NSString*)roomId
               fromContext:(NSManagedObjectContext*)context;
+(ChatRoom*)newChatRoomWithId:(NSString*)roomId
                       inContext:(NSManagedObjectContext*)context;

- (void)addMessagesObject:(ChatMessage *)value;
- (void)removeMessagesObject:(ChatMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end

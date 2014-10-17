//
//  ChatMessage.m
//  NdnCon
//
//  Created by Peter Gusev on 10/14/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "ChatMessage.h"
#import "User.h"

NSString* const kChatMesageTypeJoin = @"Join";
NSString* const kChatMesageTypeLeave = @"Leave";
NSString* const kChatMesageTypeText = @"Text";

@implementation ChatMessage

@dynamic timestamp;
@dynamic body;
@dynamic type;
@dynamic chatRoom;
@dynamic user;

+(ChatMessage *)newChatMessageFromUser:(User *)user
                                ofType:(NSString *)messageType
                       withMessageBody:(NSString *)body
                             inContext:(NSManagedObjectContext *)context
{
    ChatMessage *message = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ChatMessage class])
                                                         inManagedObjectContext:context];
    message.user = user;
    message.type = [self typeFromString:messageType];
    message.body = body;
    message.timestamp = [NSDate date];
    
    NSError *error = nil;
    [context save:&error];
    
    return message;
}

+(NSNumber*)typeFromString:(NSString*)typeStr
{
    if ([typeStr isEqualTo:kChatMesageTypeJoin])
        return @(1);
    
    if ([typeStr isEqualTo:kChatMesageTypeJoin])
        return @(2);
    
    if ([typeStr isEqualTo:kChatMesageTypeText])
        return @(3);
    
    return nil;
}

@end

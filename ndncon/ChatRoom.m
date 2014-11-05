//
//  ChatRoom.m
//  NdnCon
//
//  Created by Peter Gusev on 10/14/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "ChatRoom.h"
#import "ChatMessage.h"
#import "NCErrorController.h"

@implementation ChatRoom

@dynamic created;
@dynamic roomId;
@dynamic messages;

+(ChatRoom *)chatRoomWithId:(NSString *)roomId
                fromContext:(NSManagedObjectContext *)context
{
    NSEntityDescription *entityDescription = [NSEntityDescription
                                             entityForName:NSStringFromClass([ChatRoom class])
                                              inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"roomId == %@", roomId];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *chatRoom = [context executeFetchRequest:request error:&error];
    
    if (chatRoom == nil)
        [[NCErrorController sharedInstance] postError:error];
    else if (chatRoom.count > 1)
        [[NCErrorController sharedInstance] postErrorWithMessage:@"Data inconsistency: several more than one chatroom with the same ID"];
    else
        return [chatRoom firstObject];
    
    return nil;
}

+(ChatRoom *)newChatRoomWithId:(NSString *)roomId
                        inContext:(NSManagedObjectContext *)context
{
    ChatRoom *newChatRoom = [self chatRoomWithId:roomId fromContext:context];
    
    if (newChatRoom != nil)
    {
        NSLog(@"chatroom with id %@ exists", roomId);
    }
    else
    {
        newChatRoom = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ChatRoom class])
                                                    inManagedObjectContext:context];
        newChatRoom.roomId = roomId;
        [context save:NULL];
    }
    
    return newChatRoom;
}

-(BOOL)hasParitcipant:(id)user
{
    for (ChatMessage *message in self.messages)
    {
        if (message.user == user)
            return YES;
    }
    
    return NO;
}

@end

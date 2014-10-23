//
//  Conference.m
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "Conference.h"
#import "ChatRoom.h"
#import "User.h"
#import "NCErrorController.h"

NSString* const kConferenceNameKey = @"name";
NSString* const kConferenceDescriptionKey = @"description";
NSString* const kConferenceParticipantsKey = @"participants";
NSString* const kConferenceParticipantNameKey = @"username";
NSString* const kConferenceParticipantPrefixKey = @"prefix";
NSString* const kConferenceStartDateKey = @"startDate";
NSString* const kConferenceDurationKey = @"duration";
NSString* const kConferenceChatKey = @"chat";

//******************************************************************************
@implementation Conference

@dynamic name;
@dynamic conferenceDescription;
@dynamic startDate;
@dynamic duration;
@dynamic participants;
@dynamic chatRoom;

+(NSArray*)allConferencesFromContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Conference class])];
    
    NSError *error;
    NSArray *conferences = [context executeFetchRequest:request error:&error];
    
    if (conferences == nil)
        [[NCErrorController sharedInstance] postError:error];
    
    return conferences;
}

+(Conference *)conferenceWithName:(NSString *)name
                      fromContext:(NSManagedObjectContext*)context
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([Conference class])
                                                         inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *conferences = [context executeFetchRequest:request error:&error];
    
    if (conferences == nil)
        [[NCErrorController sharedInstance] postError:error];
    else
        return [conferences firstObject];
    
    return nil;
}

+(Conference*)newConferenceWithName:(NSString *)name
                          inContext:(NSManagedObjectContext*)context
{
    Conference *conference = [self conferenceWithName:name fromContext:context];
    
    if (conference == nil)
    {
        conference = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Conference class])
                                                   inManagedObjectContext:context];
        conference.name = name;
        [context save:NULL];
    }
    
    return conference;
}

+(Conference *)newConferenceWithDictionaryRepresentation:(NSDictionary *)dictionary
                                               inContext:(NSManagedObjectContext *)context
{
    Conference *conference = [self newConferenceWithName:dictionary[kConferenceNameKey]
                                               inContext:context];

    conference.conferenceDescription = dictionary[kConferenceDescriptionKey];
    conference.startDate = dictionary[kConferenceStartDateKey];
    conference.duration = dictionary[kConferenceDurationKey];
    conference.chatRoom = [ChatRoom chatRoomWithId:dictionary[kConferenceChatKey]
                                       fromContext:context];
    
    for (NSDictionary *userDict in dictionary[kConferenceParticipantsKey])
    {
        User *user = [User newUserWithName:userDict[kConferenceParticipantNameKey]
                                 andPrefix:userDict[kConferenceParticipantPrefixKey]
                                 inContext:context];
        [conference addParticipantsObject: user];
    }
    
    [context save:NULL];
    
    return conference;
}

-(NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *conferenceDictionary = [NSMutableDictionary dictionary];
    
    conferenceDictionary[kConferenceNameKey] = self.name;
    conferenceDictionary[kConferenceDescriptionKey] = self.description;
    
    NSMutableArray *participants = [NSMutableArray array];
                                                  
    for (User *user in self.participants)
    {
        [participants addObject:@{kConferenceParticipantNameKey: user.name,
                                  kConferenceParticipantPrefixKey: user.prefix}];
    }
    
    conferenceDictionary[kConferenceParticipantsKey] = [NSArray arrayWithArray:participants];
    conferenceDictionary[kConferenceChatKey] = self.chatRoom.roomId;
    conferenceDictionary[kConferenceDurationKey] = self.duration;
    
    return conferenceDictionary;
}

@end

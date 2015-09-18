//
//  Conference.m
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "Conference.h"
#import "ChatRoom.h"
#import "User.h"
#import "NCErrorController.h"
#import "NCPreferencesController.h"

NSString* const kConferenceNameKey = @"name";
NSString* const kConferenceDescriptionKey = @"conferenceDescription";
NSString* const kConferenceParticipantsKey = @"participants";
NSString* const kConferenceParticipantNameKey = @"username";
NSString* const kConferenceParticipantPrefixKey = @"prefix";
NSString* const kConferenceStartDateKey = @"startDate";
NSString* const kConferenceDurationKey = @"duration";
NSString* const kConferenceChatKey = @"chat";
NSString* const kConferenceOrganizerNameKey = @"organizer";
NSString* const kConferenceOrganizerPrefixKey = @"orgprefix";


//******************************************************************************
@implementation Conference

@dynamic name;
@dynamic conferenceDescription;
@dynamic startDate;
@dynamic duration;
@dynamic participants;
@dynamic chatRoom;
@dynamic organizer;

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

+(Conference *)newConferenceFromRemoteCopy:(NCRemoteConference *)remoteConference
                                 inContext:(NSManagedObjectContext*)context
{
    Conference *conference = [self newConferenceWithName:remoteConference.name
                                               inContext:context];
    conference.conferenceDescription = remoteConference.conferenceDescription;
    conference.startDate = remoteConference.startDate;
    conference.duration = remoteConference.duration;
    conference.chatRoom = [ChatRoom newChatRoomWithId:remoteConference.name
                                            inContext:context];

    NSMutableArray *allParticipants = [NSMutableArray arrayWithArray:[remoteConference.participants allObjects]];
    [allParticipants addObject:remoteConference.organizer];
    
    for (UserStub *user in allParticipants)
    {
        if (!([user.name isEqualToString:[NCPreferencesController sharedInstance].userName] &&
            [user.prefix isEqualToString:[NCPreferencesController sharedInstance].prefix]))
        {
            User *userLocal = [User newUserWithName:user.name
                                          andPrefix:user.prefix
                                          inContext:context];
            [conference addParticipantsObject:userLocal];
        }
    }
    
    if (!([conference.organizer.name isEqualToString:[NCPreferencesController sharedInstance].userName] &&
        [conference.organizer.prefix isEqualToString:[NCPreferencesController sharedInstance].prefix]))
    {
        User *organizer = [User newUserWithName:remoteConference.organizer.name
                                      andPrefix:remoteConference.organizer.prefix
                                      inContext:context];
        conference.organizer = organizer;        
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

-(BOOL)isRemote
{
    return (self.organizer != nil);
}

-(BOOL)isActive
{
    return ([NSDate date].timeIntervalSince1970 < ([self.startDate timeIntervalSince1970] + self.duration.doubleValue));
}

-(BOOL)hasParticipant:(NSString*)username withPrefix:(NSString*)prefix
{
    __block BOOL found = NO;
    
    found = ([self.organizer.name isEqualToString:username] &&
             [self.organizer.prefix isEqualToString:prefix]);
    
    if (!found)
        [self.participants enumerateObjectsUsingBlock:^(User *user, BOOL *stop) {
            if ([user.name isEqualToString:username] &&
                [user.prefix isEqualToString:prefix])
            {
                *stop = YES;
                found = YES;
            }
        }];
    
    return found;
}

@end

//******************************************************************************
@interface NCRemoteConference ()

@property (nonatomic) NSDictionary *conferenceDictionary;

@end

//******************************************************************************
@implementation NCRemoteConference

-(id)initWithDictionary:(NSDictionary *)conferenceDictionary
{
    self = [super init];
    
    if (self)
    {
        self.conferenceDictionary = conferenceDictionary;
    }
    
    return self;
}

-(NSString *)name
{
    return self.conferenceDictionary[kConferenceNameKey];
}

-(NSString *)conferenceDescription
{
    return self.conferenceDictionary[kConferenceDescriptionKey];
}

-(NSDate *)startDate
{
    return [NSDate dateWithTimeIntervalSince1970:
            [self.conferenceDictionary[kConferenceStartDateKey] doubleValue]];
    //[NSDate dateWithNaturalLanguageString:self.conferenceDictionary[kConferenceStartDateKey]];
}

-(NSNumber *)duration
{
    return @([self.conferenceDictionary[kConferenceDurationKey] integerValue]);
}

-(NSSet *)participants
{
    __block NSMutableSet *set = [[NSMutableSet alloc] init];
    
    [self.conferenceDictionary[kConferenceParticipantsKey] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UserStub *user = [[UserStub alloc] init];
        user.name = [obj valueForKey:kConferenceParticipantNameKey];
        user.prefix = [obj valueForKey:kConferenceParticipantPrefixKey];
        [set addObject:user];
    }];
    
    [set addObject:self.organizer];
    
    return [NSSet setWithSet:set];
}

-(ChatRoom *)chatRoom
{
    ChatRoom *room = [[ChatRoom alloc] init];
    
    room.roomId = self.name;
    room.created = self.startDate;
    
    return room;
}

-(UserStub *)organizer
{
    UserStub *organizer = [[UserStub alloc] init];
    organizer.name = self.conferenceDictionary[kConferenceOrganizerNameKey];
    organizer.prefix = self.conferenceDictionary[kConferenceOrganizerPrefixKey];
    
    return organizer;
}

-(BOOL)isRemote
{
    return YES;
}

-(BOOL)isActive
{
    return ([NSDate date].timeIntervalSince1970 < ([self.startDate timeIntervalSince1970] + self.duration.doubleValue));
}

-(BOOL)hasParticipant:(NSString*)username withPrefix:(NSString*)prefix
{
    __block BOOL found = NO;
    
    found = ([self.organizer.name isEqualToString:username] &&
             [self.organizer.prefix isEqualToString:prefix]);
    
    if (!found)
        [self.participants enumerateObjectsUsingBlock:^(User *user, BOOL *stop) {
            if ([user.name isEqualToString:username] &&
                [user.prefix isEqualToString:prefix])
            {
                *stop = YES;
                found = YES;
            }
        }];
    
    return found;
}

-(NSDictionary *)dictionaryRepresentation
{
    return self.conferenceDictionary;
}

-(void)createLocalCopiesForMissingUsersInContext:(NSManagedObjectContext*)context
{
    NSMutableArray *allParticipants = [NSMutableArray arrayWithArray:[self.participants allObjects]];
    [allParticipants addObject:self.organizer];
    
    for (UserStub *user in allParticipants)
    {
        if (!([user.name isEqualToString:[NCPreferencesController sharedInstance].userName] &&
              [user.prefix isEqualToString:[NCPreferencesController sharedInstance].prefix]))
        {
            [User newUserWithName:user.name
                        andPrefix:user.prefix
                        inContext:context];
            [context save:NULL];
        }
    }
}

@end

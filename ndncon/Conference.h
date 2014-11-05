//
//  Conference.h
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChatRoom, User, UserStub, NCRemoteConference;

extern NSString* const kConferenceNameKey;
extern NSString* const kConferenceDescriptionKey;
extern NSString* const kConferenceParticipantsKey;
extern NSString* const kConferenceParticipantNameKey;
extern NSString* const kConferenceParticipantPrefixKey;
extern NSString* const kConferenceStartDateKey;
extern NSString* const kConferenceDurationKey;
extern NSString* const kConferenceChatKey;
extern NSString* const kConferenceOrganizerNameKey;
extern NSString* const kConferenceOrganizerPrefixKey;

//******************************************************************************
@protocol ConferenceEntityProtocol <NSObject>

@required
@property (nonatomic) NSString * name;
@property (nonatomic) NSString * conferenceDescription;
@property (nonatomic) NSDate * startDate;
@property (nonatomic) NSNumber * duration;
@property (nonatomic) NSSet *participants;
@property (nonatomic) ChatRoom *chatRoom;
@property (nonatomic) User *organizer;

-(BOOL)isRemote;
-(BOOL)isActive;

@end

//******************************************************************************
@interface Conference : NSManagedObject<ConferenceEntityProtocol>

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * conferenceDescription;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSSet *participants;
@property (nonatomic, retain) ChatRoom *chatRoom;
@property (nonatomic, retain) User *organizer;

-(BOOL)hasParticipant:(NSString*)username withPrefix:(NSString*)prefix;

@end

//******************************************************************************
@interface Conference (CoreDataGeneratedAccessors)

+(NSArray*)allConferencesFromContext:(NSManagedObjectContext*)context;
+(Conference*)conferenceWithName:(NSString*)name
                     fromContext:(NSManagedObjectContext*)context;
+(Conference*)newConferenceWithName:(NSString*)name
                          inContext:(NSManagedObjectContext*)context;
+(Conference*)newConferenceFromRemoteCopy:(NCRemoteConference*)remoteConference
                                inContext:(NSManagedObjectContext*)context;

- (void)addParticipantsObject:(User *)value;
- (void)removeParticipantsObject:(User *)value;
- (void)addParticipants:(NSSet *)values;
- (void)removeParticipants:(NSSet *)values;

-(NSDictionary*)dictionaryRepresentation;

@end

//******************************************************************************
@interface NCRemoteConference : NSObject<ConferenceEntityProtocol>

@property (nonatomic, retain, readonly) NSString * name;
@property (nonatomic, retain, readonly) NSString * conferenceDescription;
@property (nonatomic, retain, readonly) NSDate * startDate;
@property (nonatomic, retain, readonly) NSNumber * duration;
@property (nonatomic, retain, readonly) NSSet *participants;
@property (nonatomic, retain, readonly) ChatRoom *chatRoom;
@property (nonatomic, retain, readonly) UserStub *organizer;

-(id)initWithDictionary:(NSDictionary *)conferenceDictionary;

@end

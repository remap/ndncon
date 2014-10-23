//
//  Conference.h
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChatRoom, User;

@interface Conference : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * conferenceDescription;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSSet *participants;
@property (nonatomic, retain) ChatRoom *chatRoom;
@end

@interface Conference (CoreDataGeneratedAccessors)

+(NSArray*)allConferencesFromContext:(NSManagedObjectContext*)context;

+(Conference*)conferenceWithName:(NSString*)name
                     fromContext:(NSManagedObjectContext*)context;
+(Conference*)newConferenceWithName:(NSString*)name
                          inContext:(NSManagedObjectContext*)context;
+(Conference*)newConferenceWithDictionaryRepresentation:(NSDictionary*)dictionary
                                              inContext:(NSManagedObjectContext*)context;

- (void)addParticipantsObject:(User *)value;
- (void)removeParticipantsObject:(User *)value;
- (void)addParticipants:(NSSet *)values;
- (void)removeParticipants:(NSSet *)values;

-(NSDictionary*)dictionaryRepresentation;

@end

//
//  NCUser.h
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <CoreData/CoreData.h>

//******************************************************************************
@protocol UserEntityProtocol <NSObject>

@property (nonatomic) NSString* name;
@property (nonatomic) NSString* prefix;

@end

//******************************************************************************
@interface User : NSManagedObject<UserEntityProtocol>

/**
 * Returns all user from DB
 */
+(NSArray *)allUsersFromContext:(NSManagedObjectContext*)context;

/**
 * Returns frist user found to have the same username as provided string
 */
+(User*)userByName:(NSString*)userName
       fromContext:(NSManagedObjectContext*)context;

+(User*)userByName:(NSString*)userName
         andPrefix:(NSString*)prefix
       fromContext:(NSManagedObjectContext*)context;


+(User*)newUserWithName:(NSString*)userName
              andPrefix:(NSString*)prefix
              inContext:(NSManagedObjectContext*)context;

@property (nonatomic) NSString* name;
@property (nonatomic) NSString* prefix;
@property (nonatomic) BOOL isMyself;

@property (nonatomic) NSImage* statusImage;
@property (nonatomic, readonly) NSString *userPrefix;
@property (nonatomic, readonly) NSString *privateChatRoomId;

@end

//******************************************************************************
@interface UserStub : NSObject<UserEntityProtocol>

@property (nonatomic) NSString* name;
@property (nonatomic) NSString* prefix;

@end

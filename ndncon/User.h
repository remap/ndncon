//
//  NCUser.h
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface User : NSManagedObject

/**
 * Returns all user from DB
 */
+(NSArray *)allUsersFromContext:(NSManagedObjectContext*)context;

/**
 * Returns frist user found to have the same username as provided string
 */
+(User*)userByName:(NSString*)userName
       fromContext:(NSManagedObjectContext*)context;

+(User*)newUserWithName:(NSString*)userName
              andPrefix:(NSString*)prefix
              inContext:(NSManagedObjectContext*)context;

@property (nonatomic) NSString* name;
@property (nonatomic) NSString* prefix;

@property (nonatomic) NSImage* statusImage;
@property (nonatomic, readonly) NSString *userPrefix;

@end

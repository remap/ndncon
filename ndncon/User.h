//
//  NCUser.h
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface User : NSManagedObject

+(NSArray *)allUsersFromContext:(NSManagedObjectContext*)context;

@property (nonatomic) NSString* name;
@property (nonatomic) NSString* prefix;

@property (nonatomic) NSImage* statusImage;
@property (nonatomic, readonly) NSString *userPrefix;

@end

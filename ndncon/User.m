//
//  NCUser.m
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "User.h"
#import "NCUserListViewController.h"
#import "NCNdnRtcLibraryController.h"
#import "NCErrorController.h"
#import "NCChatLibraryController.h"
#import "NCPreferencesController.h"

//******************************************************************************
@implementation User
{
    NSImage *_statusImage;
}

@dynamic name;
@dynamic prefix;


+(NSArray *)allUsersFromContext:(NSManagedObjectContext*)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([User class])];
    NSError *error = nil;
    
    NSArray *users = [context executeFetchRequest:request error:&error];
    
    if (!users)
        [[NCErrorController sharedInstance] postError:error];

    return users;
}

+(User *)userByName:(NSString *)userName fromContext:(NSManagedObjectContext *)context
{
    __block User *user = nil;
    
    [[self allUsersFromContext:context] enumerateObjectsUsingBlock:^(User* usr, NSUInteger idx, BOOL *stop) {
        if ([usr.name isEqualTo:userName])
        {
            user = usr;
            *stop = YES;
        }
    }];
    
    return user;
}

+(User*)userByName:(NSString *)userName
         andPrefix:(NSString *)prefix
       fromContext:(NSManagedObjectContext *)context
{
    __block User *user = nil;
    
    [[self allUsersFromContext:context] enumerateObjectsUsingBlock:^(User* usr, NSUInteger idx, BOOL *stop) {
        if ([usr.name isEqualTo:userName] && [usr.prefix isEqualTo:prefix])
        {
            user = usr;
            *stop = YES;
        }
    }];
    
    return user;
}

+(User *)newUserWithName:(NSString *)userName andPrefix:(NSString *)prefix inContext:(NSManagedObjectContext *)context
{
    User *user = [self userByName:userName fromContext:context];
    
    if (user == nil)
    {
        user = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([User class])
                                             inManagedObjectContext:context];
        user.name = userName;
        user.prefix = prefix;
        [context save:NULL];
    }
    
    return user;
}

-(BOOL)isMyself
{
    return [self.name isEqualToString:[NCPreferencesController sharedInstance].userName] &&
    [self.prefix isEqualToString:[NCPreferencesController sharedInstance].prefix];
}

-(NSImage *)statusImage
{
    NCSessionStatus status = [NCUserListViewController sessionStatusForUser:self.name
                                                                 withPrefix:self.prefix];
    
    return [[NCNdnRtcLibraryController sharedInstance] imageForSessionStatus:status];
}

-(void)setStatusImage:(NSImage *)statusImage
{
    _statusImage = statusImage;
}

-(NSString *)userPrefix
{
    return [NSString stringWithFormat:@"%@/%@", self.prefix, self.name];
}

-(NSString *)privateChatRoomId
{
    return [NCChatLibraryController privateChatRoomIdWithUser:self.userPrefix];
}

@end

//******************************************************************************
@implementation UserStub


@end

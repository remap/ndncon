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

@end

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

@implementation User
{
    NSImage *_statusImage;
}

@dynamic name;
@dynamic prefix;

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

@end

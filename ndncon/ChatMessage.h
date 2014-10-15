//
//  ChatMessage.h
//  NdnCon
//
//  Created by Peter Gusev on 10/14/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface ChatMessage : NSManagedObject

@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSManagedObject *chatRoom;
@property (nonatomic, retain) User *user;

@end

//
//  NSDate+PTNAdditions.h
//  PTNAdditions
//
//  Created by Peter Gusev on 1/31/13.
//  Copyright (c) 2013 peetonn inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (NCAdditions)
@property (nonatomic,readonly) NSUInteger year, month, day, hour, minute, second;
/**
 * Returns true if current date represent today's day. It's not just simple comparison with [NSDate date].
 */
-(bool)isToday;
/**
 * Returns true if current date is yesterday
 */
-(bool)isYesterday;
/**
 * Checks if dates are equal (does not take care about time)
 */
-(bool)isEqualToDateOnly:(NSDate*)dateTime;
/**
 * Checks if times are equal (does not take care about dates)
 */
-(bool)isEqualToTimeOnly:(NSDate*)dateTime;

@end

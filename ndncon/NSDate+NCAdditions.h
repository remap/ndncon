//
//  NSDate+PTNAdditions.h
//  PTNAdditions
//
//  Created by Peter Gusev on 1/31/13.
//  Copyright 2013-2015 Regents of the University of California
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
 * Returns true if current data is tomorrow
 */
-(bool)isTomorrow;
/**
 * Checks if dates are equal (does not take care about time)
 */
-(bool)isEqualToDateOnly:(NSDate*)dateTime;
/**
 * Checks if times are equal (does not take care about dates)
 */
-(bool)isEqualToTimeOnly:(NSDate*)dateTime;
/**
 * Returns a future date which is ahead of the current date by 
 * specified number of years
 */
-(NSDate*)dateByAddingYears:(NSUInteger)years;
/**
 * Returns time interval between current date and future date which
 * is ahead of the current date by specified number of years
 */
-(NSTimeInterval)timeIntervalForYearsAhead:(NSUInteger)years;


@end

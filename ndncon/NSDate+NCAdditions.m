//
//  NSDate+PTNAdditions.m
//  PTNAdditions
//
//  Created by Peter Gusev on 1/31/13.
//  Copyright (c) 2013 peetonn inc. All rights reserved.
//

#import "NSDate+NCAdditions.h"

@implementation NSDate (NCAdditions)
-(bool)isToday
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];
    
    NSDateComponents *todayComp = [cal components:(kCFCalendarUnitYear|kCFCalendarUnitMonth|kCFCalendarUnitDay) fromDate:today];
    NSDateComponents *selfComp = [cal components:(kCFCalendarUnitYear|kCFCalendarUnitMonth|kCFCalendarUnitDay) fromDate:self];
    
    bool res = [todayComp year]==[selfComp year] &&
    [todayComp month] == [selfComp month] &&
    [todayComp day] == [selfComp day];
    
    return res;
}
-(bool)isYesterday
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];
    
    NSDateComponents *todayComp = [cal components:(kCFCalendarUnitYear|kCFCalendarUnitMonth|kCFCalendarUnitDay) fromDate:today];
    NSDateComponents *selfComp = [cal components:(kCFCalendarUnitYear|kCFCalendarUnitMonth|kCFCalendarUnitDay) fromDate:self];
    
    bool res = [todayComp year]==[selfComp year] &&
    [todayComp month] == [selfComp month] &&
    [todayComp day] == [selfComp day]+1;
    
    return res;
}
-(bool)isTomorrow
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];
    
    NSDateComponents *todayComp = [cal components:(kCFCalendarUnitYear|kCFCalendarUnitMonth|kCFCalendarUnitDay) fromDate:today];
    NSDateComponents *selfComp = [cal components:(kCFCalendarUnitYear|kCFCalendarUnitMonth|kCFCalendarUnitDay) fromDate:self];
    
    bool res = [todayComp year]==[selfComp year] &&
    [todayComp month] == [selfComp month] &&
    [todayComp day] + 1 == [selfComp day];
    
    return res;
}
-(NSUInteger)day
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:kCFCalendarUnitDay fromDate:self];
    return [comp day];
}
-(NSUInteger)month
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:kCFCalendarUnitMonth fromDate:self];
    return [comp month];
}
-(NSUInteger)year
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:kCFCalendarUnitYear fromDate:self];
    return [comp year];
}
-(NSUInteger)hour
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:kCFCalendarUnitHour fromDate:self];
    return [comp hour];
}
-(NSUInteger)minute
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:kCFCalendarUnitMinute fromDate:self];
    return [comp minute];
}
-(NSUInteger)second
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:kCFCalendarUnitSecond fromDate:self];
    return [comp second];
}
-(bool)isEqualToDateOnly:(NSDate *)dateTime
{
    return self.day == dateTime.day && self.month == dateTime.month && self.year == dateTime.year;
}
-(bool)isEqualToTimeOnly:(NSDate *)dateTime
{
    return self.second == dateTime.second && self.minute == dateTime.minute && self.hour == dateTime.hour;
}
@end

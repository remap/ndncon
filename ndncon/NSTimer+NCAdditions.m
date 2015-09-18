//
//  NSTimer+PTNAdditions.m
//  PTNAdditions
//
//  Created by Peter Gusev on 1/29/13.
//  Copyright 2013-2015 Regents of the University of California
//

#import "NSTimer+NCAdditions.h"

@interface NSTimer()

@end

@implementation NSTimer (NCAdditions)

+(NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo fireBlock:(NCTimerBlock)block
{
    return [NSTimer scheduledTimerWithTimeInterval:ti
                                            target:self
                                          selector:@selector(NCExecuteBlockWithTimer:)
                                          userInfo:[block copy]
                                           repeats:yesOrNo];
}

+(NSTimer*)timerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo fireBlock:(NCTimerBlock)block
{
    return [NSTimer timerWithTimeInterval:ti
                                   target:self
                                 selector:@selector(NCExecuteBlockWithTimer:)
                                 userInfo:[block copy]
                                  repeats:yesOrNo];
}

+(void)NCExecuteBlockWithTimer:(NSTimer *)timer
{
    NCTimerBlock block = [timer userInfo];
    block(timer);
}

@end

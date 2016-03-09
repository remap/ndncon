//
//  NCStatisticCollector.m
//  NdnCon
//
//  Created by Peter Gusev on 3/8/16.
//  Copyright © 2016 REMAP. All rights reserved.
//

#include <ndnrtc/statistics.h>
#include <ndnrtc/ndnrtc-library.h>

#import "NCStatisticCollector.h"
#import "NCPreferencesController.h"
#import "NCStreamingController.h"
#import "NCNdnRtcLibraryController.h"
#import "NSString+NCAdditions.h"
#import "NSTimer+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"

#define STAT_FILE_LOCATION @"/tmp/ndnrtc.stat"

using namespace ndnrtc;
using namespace ndnrtc::new_api;
using namespace ndnrtc::new_api::statistics;

@interface NCStatisticCollector ()

@property (nonatomic) BOOL isRunning;
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic) NSOutputStream *outputStream;

@property (nonatomic) NSTimer *updateTimer;

@end


//******************************************************************************
@implementation NCStatisticCollector

+(NCStatisticCollector*)sharedInstance
{
    return (NCStatisticCollector*)[super sharedInstance];
}


+(PTNSingleton*)createInstance
{
    return [[NCStatisticCollector alloc] init];
}

+(dispatch_once_t *)token
{
    static dispatch_once_t token;
    return &token;
}

-(instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _interval = 0.5;
        [[NCPreferencesController sharedInstance] addObserver:self
                                                   forKeyPath:NSStringFromSelector(@selector(writeStatsToFile))
                                                      options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew)
                                                      context:NULL];
    }
    
    return self;
}

#pragma mark - public
-(void)start
{
    if (self.isRunning)
        return;
    
    self.isRunning = YES;
    [self setupFile];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:self.interval
                                                       repeats:YES
                                                     fireBlock:^(NSTimer *tmr) {
                                                         [self collectStats];
                                                     }];
    [self.updateTimer fire];
}

-(void)stop
{
    self.isRunning = NO;
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}

#pragma mark - callbacks
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == [NCPreferencesController sharedInstance])
    {
        if (![NCPreferencesController sharedInstance].writeStatsToFile.boolValue)
            [self stop];
        else
            [self start];
    }
}

-(void)collectStats
{
    NSArray *allFetchedUsers = [[NCStreamingController sharedInstance] allFetchedUsers];
    
    if (allFetchedUsers.count > 0)
    {
        for (NCFetchedUser *user in allFetchedUsers)
        {
            for (NSDictionary *streamConfiguration in user.fetchedStreams)
            {
                StatisticsStorage stat = [self queryStatForStream:streamConfiguration ofUser:user];
                [self writeStats: stat forStream:streamConfiguration ofUser:user];
            }
        }
        
        [self flushToDisk];
    }
}

#pragma mark - private
-(void)setupFile
{
    self.outputStream = [[NSOutputStream alloc] initToFileAtPath:STAT_FILE_LOCATION append:NO];
    [self.outputStream open];
}

-(void)closeFile
{
    [self.outputStream close];
}

-(StatisticsStorage)queryStatForStream:(NSDictionary*)streamConfiguration ofUser:(NCFetchedUser*)user
{
    NSString *streamPrefix = [NSString streamPrefixForStream:streamConfiguration[kNameKey]
                                                        user:user.username
                                                  withPrefix:user.hubPrefix];
    INdnRtcLibrary *libHandle = (INdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    std::string prefix([streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    
    return libHandle->getRemoteStreamStatistics(prefix);;
}

-(void)writeStats:(const StatisticsStorage&)stat
        forStream:(NSDictionary*)streamConfiguration
           ofUser:(NCFetchedUser*)user
{
    NSDictionary *statDict = [self convertStatToDict:stat];
    NSDictionary *streamInfoDict = [self packStreamInfo:(NSDictionary*)streamConfiguration forUser:user];
    
    [self writeJson: @{@"stream": streamInfoDict, @"stats": statDict}];
}

-(void)flushToDisk
{
}

-(NSDictionary*)convertStatToDict:(const StatisticsStorage&)stat
{
    NSMutableDictionary *statDict = [[NSMutableDictionary alloc] init];
    StatisticsStorage::StatRepo repo = stat.getIndicators();
    
    for (StatisticsStorage::StatRepo::iterator it = repo.begin(); it != repo.end(); it++)
    {
        Indicator indicator = it->first;
        std::string indicatorName = StatisticsStorage::IndicatorKeywords.at(indicator);
        double indicatorValue = round(it->second*100)/100;
        
        NSString *key = [NSString stringWithCString:indicatorName.c_str() encoding:NSASCIIStringEncoding];
        NSNumber *value = [NSNumber numberWithDouble:indicatorValue];
        
        statDict[key] = value;
    }
    
    return [NSDictionary dictionaryWithDictionary:statDict];
}

-(NSDictionary*)packStreamInfo:(NSDictionary*)streamConfiguration forUser:(NCFetchedUser*)user
{
    return @{
             @"user":   user.username,
             @"prefix": user.hubPrefix,
             @"stream": streamConfiguration[kNameKey],
             @"totalStreams": @(user.fetchedStreams.count)
             };
}

-(void)writeJson:(id)jsonBundle
{
    NSError *error = NULL;
    [NSJSONSerialization writeJSONObject:jsonBundle toStream:self.outputStream
                                 options:0 error:&error];
    static const uint8_t crlf[2] = {'\r', '\n'};
    [self.outputStream write:crlf maxLength:2];
}

@end

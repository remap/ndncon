//
//  NCStatisticsWindowController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/8/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndnrtc/statistics.h>
#include <ndnrtc/ndnrtc-library.h>

#import "NCStatisticsWindowController.h"
#import "NCNdnRtcLibraryController.h"
#import "NCConversationViewController.h"
#import "NSString+NCAdditions.h"
#import "NSTimer+NCAdditions.h"

#define INTEREST_AVERAGE_SIZE_BYTES 150
#define STAT_UPDATE_RATE 20 // per second

using namespace ndnrtc;

//******************************************************************************
@interface NCStatisticsStreamEntryValueTransformer : NSValueTransformer

@end

//******************************************************************************
@interface NCStatisticsWindowController ()

@property (nonatomic) NSString *selectedStream;
@property (nonatomic) NSArray *streamsArray;

@property (nonatomic) NSLock *streamPrefixLock;
@property (nonatomic) NSString *activeStreamPrefix;
@property (nonatomic) NSTimer *statUpdateTimer;
@property (nonatomic) NSString *activeThread;
@property (weak) IBOutlet NSTextField *outRateEstimationLabel;

@property (nonatomic) double nBytesPerSec, interestFrequency, segmentsFrequency;
@property (nonatomic) double rttEstimation;
@property (nonatomic) unsigned int jitterPlayableMs, jitterEstimationMs, jitterTargetMs;
@property (nonatomic) double actualProducerRate;
@property (nonatomic) unsigned int nDataReceived, nTimeouts;

//PlayoutStatistics
@property (nonatomic) unsigned int nPlayed, nPlayedKey, nSkippedNoKey, nSkippedIncomplete, nSkippedInvalidGop, nSkippedIncompleteKey;
@property (nonatomic) double latency;

//BufferStatistics
@property (nonatomic) unsigned int nAcquired, nAcquiredKey, nDropped, nDroppedKey;
@property (nonatomic) unsigned int nAssembled, nAssembledKey, nRescued, nRescuedKey, nRecovered, nRecoveredKey, nIncomplete, nIncompleteKey;

//PipelinerStatistics
@property (nonatomic) double avgSegNum, avgSegNumKey, avgSegNumParity, avgSegNumParityKey, rtxFreq;
@property (nonatomic) unsigned int nRtx, nRebuffer, nRequested, nRequestedKey, nInterestSent;

@end

//******************************************************************************
@implementation NCStatisticsWindowController

-(id)init
{
    self = [super initWithWindowNibName:@"NCStatisticsWindow"];
    
    if (self)
    {
        self.activeStreamPrefix = nil;
        self.streamPrefixLock = [[NSLock alloc] init];
    }
    
    return self;
}

-(void)dealloc
{
    self.streamPrefixLock = nil;
    self.activeStreamPrefix = nil;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    if (self.streamsArray.count > 0)
    {
        [self setSelectedStream:[self getShortNameForStream:[self.streamsArray firstObject]]];
    }
}

-(void)windowDidBecomeKey:(NSNotification *)notification
{
    [self startStatUpdate:STAT_UPDATE_RATE];
}

-(void)windowWillClose:(NSNotification *)notification
{
    if (self.window == notification.object)
        [self stopStatUpdate];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(statisticsWindowControllerWindowWillClose:)])
        [self.delegate statisticsWindowControllerWindowWillClose:self];
}

-(NSArray*)streamsArray
{
    NSArray *participantsArray = [self.delegate statisticsWindowControllerNeedParticipantsArray:self];
    
    __block NSMutableArray *streamsArray = [[NSMutableArray alloc] init];
    
    [participantsArray enumerateObjectsUsingBlock:^(NSDictionary *participant, NSUInteger idx, BOOL *stop) {
        NSDictionary *remoteStreams = [participant valueForKey:kNCRemoteStreamsDictionaryKey];
        
        [remoteStreams.allKeys enumerateObjectsUsingBlock:^(NSString *stream, NSUInteger idx, BOOL *stop) {
            [streamsArray addObject:stream];
        }];
    }];
    
    return streamsArray;
}

-(void)setSelectedStream:(NSString *)selectedStream
{
    _selectedStream = selectedStream;
    
    NSString *userName = [[selectedStream componentsSeparatedByString:@":"] firstObject];
    NSString *streamName = [[selectedStream componentsSeparatedByString:@":"] lastObject];
    
    [self.streamsArray enumerateObjectsUsingBlock:^(NSString *streamPrefix, NSUInteger idx, BOOL *stop) {
        if ([[streamPrefix getNdnRtcUserName] isEqualTo:userName] &&
            [[streamPrefix getNdnRtcStreamName] isEqualTo:streamName])
        {
            *stop = YES;
            [self switchStatisticsForStream:streamPrefix];
        }
    }];
}

// private
-(void)startStatUpdate:(NSTimeInterval)refreshRate
{
    __weak NCStatisticsWindowController *weakSelf = self;
    self.statUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:(1./refreshRate)
                                                           repeats:YES
                                                         fireBlock:^(NSTimer *timer) {
                                                             [weakSelf queryStatisticsForStream:weakSelf.activeStreamPrefix];
                                                         }];
}

-(void)stopStatUpdate
{
    [self.statUpdateTimer invalidate];
    self.statUpdateTimer = nil;
}

-(void)switchStatisticsForStream:(NSString*)streamPrefix
{
    [self.streamPrefixLock lock];
    self.activeStreamPrefix = streamPrefix;
    [self.streamPrefixLock unlock];
}

-(void)queryStatisticsForStream:(NSString*)aStreamPrefix
{
    NdnRtcLibrary *libHandle = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    ReceiverChannelPerformance stat;

    [self.streamPrefixLock lock];
    std::string streamPrefix([aStreamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    [self.streamPrefixLock unlock];
    
    libHandle->getRemoteStreamStatistics(streamPrefix, stat);
    
    std::string threadName = libHandle->getStreamThread(streamPrefix);
    self.activeThread = [NSString ncStringFromCString:threadName.c_str()];

    self.nBytesPerSec = (stat.nBytesPerSec_*8/1000);
    self.interestFrequency = stat.interestFrequency_;
    self.segmentsFrequency = stat.segmentsFrequency_;
    self.rttEstimation = stat.rttEstimation_;
    self.jitterEstimationMs = stat.jitterEstimationMs_;
    self.jitterPlayableMs = stat.jitterPlayableMs_;
    self.jitterTargetMs = stat.jitterTargetMs_;
    self.actualProducerRate = stat.actualProducerRate_;
    self.nDataReceived = stat.nDataReceived_;
    self.nTimeouts = stat.nTimeouts_;
    
    self.nPlayed = stat.playoutStat_.nPlayed_;
    self.nPlayedKey = stat.playoutStat_.nPlayedKey_;
    self.nSkippedNoKey = stat.playoutStat_.nSkippedNoKey_;
    self.nSkippedInvalidGop = stat.playoutStat_.nSkippedInvalidGop_;
    self.nSkippedIncompleteKey = stat.playoutStat_.nSkippedIncompleteKey_;
    self.nSkippedIncomplete = stat.playoutStat_.nSkippedIncomplete_;
    self.latency = stat.playoutStat_.latency_;
    
    self.nAcquired = stat.bufferStat_.nAcquired_;
    self.nAcquiredKey = stat.bufferStat_.nAcquiredKey_;
    self.nDropped = stat.bufferStat_.nDropped_;
    self.nDroppedKey = stat.bufferStat_.nDroppedKey_;
    self.nAssembled  = stat.bufferStat_.nAssembled_;
    self.nAssembledKey = stat.bufferStat_.nAssembledKey_;
    self.nRescued = stat.bufferStat_.nRescued_;
    self.nRescuedKey = stat.bufferStat_.nRescuedKey_;
    self.nRecovered = stat.bufferStat_.nRecovered_;
    self.nRecoveredKey = stat.bufferStat_.nRecoveredKey_;
    self.nIncomplete = stat.bufferStat_.nIncomplete_;
    self.nIncompleteKey = stat.bufferStat_.nIncompleteKey_;
    
    self.avgSegNum = stat.pipelinerStat_.avgSegNum_;
    self.avgSegNumKey = stat.pipelinerStat_.avgSegNumKey_;
    self.avgSegNumParity = stat.pipelinerStat_.avgSegNumParity_;
    self.avgSegNumParityKey = stat.pipelinerStat_.avgSegNumParityKey_;
    self.rtxFreq = stat.pipelinerStat_.rtxFreq_;
    self.nRtx = stat.pipelinerStat_.nRtx_;
    self.nRebuffer = stat.pipelinerStat_.nRebuffer_;
    self.nRequested = stat.pipelinerStat_.nRequested_;
    self.nRequestedKey = stat.pipelinerStat_.nRequestedKey_;
    
    self.outRateEstimationLabel.stringValue = [[NSNumber numberWithDouble:(INTEREST_AVERAGE_SIZE_BYTES*stat.interestFrequency_*8/1000.)] stringValue];
}

-(NSString*)getShortNameForStream:(NSString*)prefix
{
    NCStatisticsStreamEntryValueTransformer *transromer = [[NCStatisticsStreamEntryValueTransformer alloc] init];
    
    return [transromer transformedValue:prefix];
}

@end

//******************************************************************************
@implementation NCStatisticsStreamEntryValueTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;
}

-(id)transformedArrayValue:(id)value
{
    if (!value || ![value isKindOfClass:[NSArray class]])
        return nil;
    
    __block NSMutableArray *result = [NSMutableArray array];
    
    [value enumerateObjectsUsingBlock:^(NSString *streamPrefix, NSUInteger idx, BOOL *stop) {
        [result addObject:[NSString stringWithFormat:@"%@:%@",
                          [streamPrefix getNdnRtcUserName],
                          [streamPrefix getNdnRtcStreamName]]];
    }];
    
    return result;
}

-(id)transformedValue:(id)value
{
    if (!value)
        return nil;
    
    if ([value isKindOfClass:[NSArray class]])
        return [self transformedArrayValue:value];
    
    return [NSString stringWithFormat:@"%@:%@",
            [value getNdnRtcUserName],
            [value getNdnRtcStreamName]];
}

@end

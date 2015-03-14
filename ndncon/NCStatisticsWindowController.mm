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
#define STAT_UPDATE_RATE 10 // per second

using namespace ndnrtc;
using namespace ndnrtc::new_api::statistics;

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
@property (nonatomic) unsigned int dw;
@property (nonatomic) int w;
@property (nonatomic) double RTTprime;

@property (nonatomic) double fetchEfficiency, playbackEfficiency;

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
    if (aStreamPrefix)
    {
        NdnRtcLibrary *libHandle = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
        
        [self.streamPrefixLock lock];
        std::string streamPrefix([aStreamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
        [self.streamPrefixLock unlock];
        
        StatisticsStorage stat = libHandle->getRemoteStreamStatistics(streamPrefix);
        
        std::string threadName = libHandle->getStreamThread(streamPrefix);
        self.activeThread = [NSString ncStringFromCString:threadName.c_str()];
        
        self.nBytesPerSec = stat[Indicator::InBitrateKbps];
        self.interestFrequency = stat[Indicator::InterestRate];
        self.segmentsFrequency = stat[Indicator::InRateSegments];
        self.rttEstimation = stat[Indicator::RttEstimation];
        self.jitterEstimationMs = stat[Indicator::BufferEstimatedSize];
        self.jitterPlayableMs = stat[Indicator::BufferPlayableSize];
        self.jitterTargetMs = stat[Indicator::BufferTargetSize];
        self.actualProducerRate = stat[Indicator::CurrentProducerFramerate];
        self.nDataReceived = stat[Indicator::SegmentsReceivedNum];
        self.nTimeouts = stat[Indicator::TimeoutsNum];
        
        self.nPlayed = stat[Indicator::PlayedNum];
        self.nPlayedKey = stat[Indicator::PlayedKeyNum];
        self.nSkippedNoKey = stat[Indicator::SkippedNoKeyNum];
        self.nSkippedInvalidGop = stat[Indicator::SkippedBadGopNum];
        self.nSkippedIncompleteKey = stat[Indicator::SkippedIncompleteKeyNum];
        self.nSkippedIncomplete = stat[Indicator::SkippedIncompleteNum];
        self.latency = stat[Indicator::LatencyEstimated];
        
        self.nAcquired = stat[Indicator::AcquiredNum];
        self.nAcquiredKey = stat[Indicator::AcquiredKeyNum];
        self.nDropped = stat[Indicator::DroppedNum];
        self.nDroppedKey = stat[Indicator::DroppedKeyNum];
        self.nAssembled  = stat[Indicator::AssembledNum];
        self.nAssembledKey = stat[Indicator::AssembledKeyNum];
        self.nRescued = stat[Indicator::RescuedNum];
        self.nRescuedKey = stat[Indicator::RescuedKeyNum];
        self.nRecovered = stat[Indicator::RecoveredNum];
        self.nRecoveredKey = stat[Indicator::RecoveredKeyNum];
        self.nIncomplete = stat[Indicator::IncompleteNum];
        self.nIncompleteKey = stat[Indicator::IncompleteKeyNum];
        
        self.avgSegNum = stat[Indicator::SegmentsDeltaAvgNum];
        self.avgSegNumKey = stat[Indicator::SegmentsKeyAvgNum];
        self.avgSegNumParity = stat[Indicator::SegmentsDeltaParityAvgNum];
        self.avgSegNumParityKey = stat[Indicator::SegmentsKeyParityAvgNum];
        self.rtxFreq = stat[Indicator::RtxFrequency];
        self.nRtx = stat[Indicator::RtxNum];
        self.nRebuffer = stat[Indicator::RebufferingsNum];
        self.nRequested = stat[Indicator::RequestedNum];
        self.nRequestedKey = stat[Indicator::RequestedKeyNum];
        
        self.w = stat[Indicator::W];
        self.dw = stat[Indicator::DW];
        self.RTTprime = stat[Indicator::RttPrime];
        
        self.fetchEfficiency = round((double)(self.nPlayed)/(double)(self.nRequested)*10000)/100;
        double allSkipped = self.nSkippedIncomplete+self.nSkippedInvalidGop+self.nSkippedNoKey;
        self.playbackEfficiency = round(allSkipped/(double)self.nPlayed*10000)/100;
        
        self.outRateEstimationLabel.stringValue = [[NSNumber numberWithDouble:(INTEREST_AVERAGE_SIZE_BYTES*stat[Indicator::InterestRate]*8/1000.)] stringValue];
    }
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

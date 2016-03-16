//
//  NCStatisticsWindowController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/8/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#include <ndnrtc/statistics.h>
#include <ndnrtc/ndnrtc-library.h>

#import "NCStatisticsWindowController.h"
#import "NCNdnRtcLibraryController.h"
#import "NSString+NCAdditions.h"
#import "NSTimer+NCAdditions.h"
#import "NCStreamingController.h"
#import "NSDictionary+NCAdditions.h"
#import "NSObject+NCAdditions.h"
#import "NSArray+NCAdditions.h"

#define INTEREST_AVERAGE_SIZE_BYTES 150
#define STAT_UPDATE_RATE 10 // per second

using namespace ndnrtc;
using namespace ndnrtc::new_api::statistics;

//******************************************************************************
@interface NCStatisticsStreamEntryValueTransformer : NSValueTransformer

@end

//******************************************************************************
@interface NCStatisticsWindowController ()
{
    StatisticsStorage::StatRepo _prevStat;
}

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *hubPrefix;

@property (nonatomic) NSArray *streamsArray;
@property (nonatomic) NSArray *audioStreamsArray;
@property (nonatomic) NSString *selectedAudioStream;

@property (nonatomic) NSLock *streamPrefixLock;
@property (nonatomic) NSString *activeStreamPrefix;
@property (nonatomic) NSTimer *statUpdateTimer;
@property (nonatomic) NSString *activeThread;
@property (weak) IBOutlet NSTextField *outRateEstimationLabel;
@property (nonatomic) unsigned int refreshRate;
@property (nonatomic) NSDictionary *rateMeters;

@property (nonatomic) double nBytesPerSec, interestFrequency, segmentsFrequency;
@property (nonatomic) double rttEstimation;
@property (nonatomic) unsigned int jitterPlayableMs, jitterEstimationMs, jitterTargetMs;
@property (nonatomic) double actualProducerRate;
@property (nonatomic) unsigned int nDataReceived, nTimeouts;
@property (nonatomic, readonly) BOOL isAudioAvailable;
@property (nonatomic) BOOL isAudioSelected;
@property (nonatomic) BOOL isShowingStats;

@property (strong) IBOutlet NSView *statsView;
@property (weak) IBOutlet NSLayoutConstraint *statViewCenteringConstraint;

@property (strong) IBOutlet NSView *chartsView;
@property (strong) IBOutlet NSLayoutConstraint *chartsViewCenteringConstraint;

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
    self = [super initWithNibName:@"NCStatisticsWindow" bundle:nil];
    
    if (self)
    {
        for (auto it:StatisticsStorage::IndicatorKeywords)
            _prevStat[it.first] = 0.;
        
        self.activeStreamPrefix = nil;
        self.streamPrefixLock = [[NSLock alloc] init];
        self.chartsView.alphaValue = 0;
        self.statsView.alphaValue = 0;
        
        [self subscribeForNotificationsAndSelectors:
         kNCFetchedStreamsAddedNotification, @selector(onFetchedStreamsChanged:),
         kNCFetchedStreamsRemovedNotification, @selector(onFetchedStreamsChanged:),
         nil];
    }
    
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.chartsView];
    self.chartsViewCenteringConstraint = [NSLayoutConstraint constraintWithItem:self.chartsView
                                                                      attribute:NSLayoutAttributeCenterX
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeCenterX
                                                                     multiplier:1.
                                                                       constant:NSWidth(self.statsView.frame)/2.];
    [self.view addConstraint:self.chartsViewCenteringConstraint];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.chartsView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.
                                                           constant:-12]];
    NSView *chartsView = self.chartsView;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(8@999)-[chartsView]-(8@999)-|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(chartsView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(32@999)-[chartsView]-(8@999)-|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(chartsView)]];
    self.isShowingStats = YES;
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
    
    self.streamPrefixLock = nil;
    self.activeStreamPrefix = nil;
}

-(NSArray*)streamsArray
{
    return [[NCStreamingController sharedInstance] getCurrentStreamsForUser:self.username
                                                                 withPrefix:self.hubPrefix];
}

-(NSArray *)audioStreamsArray
{
    return [[NCStreamingController sharedInstance] allFetchedAudioStreamsForUser:self.username
                                                                      withPrefix:self.hubPrefix];
}

-(void)setSelectedStream:(NSString *)selectedStream
{
    _selectedStream = selectedStream;
    if (!self.isAudioSelected)
        [self switchStatisticsForStream:[NSString streamPrefixForStream:selectedStream
                                                                   user:self.username
                                                             withPrefix:self.hubPrefix]];
}

-(void)setSelectedAudioStream:(NSString *)selectedAudioStream
{
    _selectedAudioStream = selectedAudioStream;
    if (self.isAudioSelected)
        [self switchStatisticsForStream:[NSString streamPrefixForStream:selectedAudioStream
                                                                   user:self.username
                                                             withPrefix:self.hubPrefix]];
}

-(void)startStatUpdateForStream:(NSString*)streamName
                           user:(NSString*)username
                     withPrefix:(NSString*)hubPrefix
{
    [self willChangeValueForKey:@"streamsArray"];
    [self willChangeValueForKey:@"audioStreamsArray"];
    [self willChangeValueForKey:@"isAudioAvailable"];
    self.username = username;
    self.hubPrefix = hubPrefix;
    [self didChangeValueForKey:@"isAudioAvailable"];
    [self didChangeValueForKey:@"audioStreamsArray"];
    [self didChangeValueForKey:@"streamsArray"];
    
    if (self.isAudioSelected)
    {
        if (self.audioStreamsArray.count)
            self.selectedAudioStream = self.audioStreamsArray[0][kNameKey];
        [self selectAudio:nil];
    }
    else
        self.selectedStream = streamName;
    
    [self startStatUpdate:STAT_UPDATE_RATE];
}

-(void)stopStatUpdate
{
    [self.statUpdateTimer invalidate];
    self.statUpdateTimer = nil;
}

-(BOOL)isAudioAvailable
{
    return [[NCStreamingController sharedInstance] allFetchedAudioStreamsForUser:self.username
                                                                      withPrefix:self.hubPrefix].count > 0;
}

-(void)setIsShowingStats:(BOOL)isShowingStats
{
    _isShowingStats = isShowingStats;
    
    if (isShowingStats)
    {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:.2];
            context.allowsImplicitAnimation = YES;
            self.statsView.alphaValue = 1.;
            self.chartsView.alphaValue = 0.;
            self.statViewCenteringConstraint.constant = 0;
            self.chartsViewCenteringConstraint.constant = NSWidth(self.view.frame);
            [self.view layoutSubtreeIfNeeded];
        }
                            completionHandler:nil];
    }
    else
    {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:.2];
            context.allowsImplicitAnimation = YES;
            self.statsView.alphaValue = 0.;
            self.chartsView.alphaValue = 1.;
            self.statViewCenteringConstraint.constant = NSWidth(self.view.frame);
            self.chartsViewCenteringConstraint.constant = 0;
            [self.view layoutSubtreeIfNeeded];
        }
                            completionHandler:nil];
    }
}

#pragma mark - actions
- (IBAction)selectAudio:(id)sender
{
    if (self.isAudioSelected)
    {
        [self switchStatisticsForStream:[NSString streamPrefixForStream:self.selectedAudioStream
                                                                   user:self.username
                                                             withPrefix:self.hubPrefix]];
    }
    else
    {
        [self switchStatisticsForStream:[NSString streamPrefixForStream:self.selectedStream
                                                                   user:self.username
                                                             withPrefix:self.hubPrefix]];
    }
}

#pragma mark - notifications
-(void)onFetchedStreamsChanged:(NSNotification*)notification
{
    NCFetchedUser *user = notification.object;
    
    if ([user.username isEqualToString:self.username] &&
        [user.hubPrefix isEqualToString:self.hubPrefix])
    {
        if ([notification.name isEqualToString:kNCFetchedStreamsRemovedNotification])
        {
            NSArray *removedStreams = notification.userInfo[kNCStreamConfigurationsKey];

            if ([[removedStreams valueForKey:kNameKey] containsObject:self.selectedStream])
            {
                if (self.isAudioAvailable)
                {
                    self.isAudioSelected = YES;
                    [self selectAudio:nil];
                }
                else
                    [self stopStatUpdate];
            }
            
            if ([[removedStreams valueForKey:kNameKey] containsObject:self.selectedAudioStream] &&
                self.isAudioSelected)
            {
                self.isAudioSelected = NO;
                [self selectAudio:nil];
            }
            
            if (self.audioStreamsArray.count == 0)
            {
                [self willChangeValueForKey:@"isAudioAvailable"];
                [self didChangeValueForKey:@"isAudioAvailable"];
            }
        }
        else
        {
            [self willChangeValueForKey:@"isAudioAvailable"];
            [self willChangeValueForKey:@"audioStreamsArray"];
            [self didChangeValueForKey:@"audioStreamsArray"];
            [self didChangeValueForKey:@"isAudioAvailable"];
        }
    }
}

#pragma mark - private
-(void)startStatUpdate:(NSTimeInterval)refreshRate
{
    __weak NCStatisticsWindowController *weakSelf = self;
    self.refreshRate = refreshRate;
    self.rateMeters = @{
                        @"incomingRate" : [[NSMutableArray alloc] initCircularArrayWithSize:refreshRate],
                        @"irate" : [[NSMutableArray alloc] initCircularArrayWithSize:refreshRate],
                        @"srate" : [[NSMutableArray alloc] initCircularArrayWithSize:refreshRate],
                        @"rtxRate" : [[NSMutableArray alloc] initCircularArrayWithSize:refreshRate]
                         };
    self.statUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:(1./refreshRate)
                                                           repeats:YES
                                                         fireBlock:^(NSTimer *timer) {
                                                             [weakSelf queryStatisticsForStream:weakSelf.activeStreamPrefix];
                                                         }];
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
        INdnRtcLibrary *libHandle = (INdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
        
        [self.streamPrefixLock lock];
        std::string streamPrefix([aStreamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
        [self.streamPrefixLock unlock];
        
        StatisticsStorage stat = libHandle->getRemoteStreamStatistics(streamPrefix);
        
        std::string threadName = libHandle->getStreamThread(streamPrefix);
        self.activeThread = [NSString ncStringFromCString:threadName.c_str()];
        
        [self.rateMeters[@"incomingRate"] push:@((stat[Indicator::RawBytesReceived] - _prevStat[Indicator::RawBytesReceived]))];
        self.nBytesPerSec = [self.rateMeters[@"incomingRate"] average]*self.refreshRate*8/1000;
        [self.rateMeters[@"irate"] push:@((stat[Indicator::InterestsSentNum] - _prevStat[Indicator::InterestsSentNum]))];
        self.interestFrequency = [self.rateMeters[@"irate"] average]*(double)self.refreshRate;
        [self.rateMeters[@"srate"] push:@((stat[Indicator::SegmentsReceivedNum] - _prevStat[Indicator::SegmentsReceivedNum]))];
        self.segmentsFrequency = [self.rateMeters[@"srate"] average]*(double)self.refreshRate;
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
        self.rtxFreq = [self.rateMeters[@"rtxRate"] average]*(double)self.refreshRate;
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
        
        self.outRateEstimationLabel.stringValue = [[NSNumber numberWithDouble:(INTEREST_AVERAGE_SIZE_BYTES*self.interestFrequency*8/1000.)] stringValue];

        _prevStat = stat.getIndicators();
        
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
    
    return [value valueForKey:kNameKey];
}

-(id)transformedValue:(id)value
{
    if (!value)
        return nil;
    
    if ([value isKindOfClass:[NSArray class]])
        return [self transformedArrayValue:value];
    
    return value[kNameKey];
}

@end

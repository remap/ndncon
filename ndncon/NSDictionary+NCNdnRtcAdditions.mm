//
//  NSDictionary+NSDictionaty_NCNdnRtcAdditions.m
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndnrtc/params.h>

#import "NSDictionary+NCNdnRtcAdditions.h"
#import "NCPreferencesController.h"
#import "NCStreamViewController.h"
#import "NCVideoThreadViewController.h"

using namespace ndnrtc;
using namespace ndnrtc::new_api;

@implementation NSDictionary (NCNdnRtcAdditions)

-(ndnrtc::new_api::MediaStreamParams)asVideoStreamParams
{
    MediaStreamParams params;
    params.type_ = MediaStreamParams::MediaStreamTypeVideo;
    
    if ([self valueForKey:kSegmentSizeKey])
        params.producerParams_.segmentSize_ = [[self valueForKey:kSegmentSizeKey] intValue];
    
    if ([self valueForKey:kFreshnessPeriodKey])
        params.producerParams_.freshnessMs_ = [[self valueForKey:kFreshnessPeriodKey] intValue];
    
    if ([self valueForKey:kNameKey])
        params.streamName_ = std::string([(NSString*)[self valueForKey:kNameKey] cStringUsingEncoding:NSASCIIStringEncoding]);
    
    if ([self valueForKey:kInputDeviceKey])
    {
        params.captureDevice_ = new CaptureDeviceParams();
        params.captureDevice_->deviceId_ = [[self valueForKey:kInputDeviceKey] intValue];
    }
    
    if ([self valueForKey:kThreadsArrayKey])
    {
        NSArray *threads = (NSArray *)[self valueForKey:kThreadsArrayKey];
        
        for (NSDictionary *threadConfiguration in threads)
        {
            VideoThreadParams *threadParams = new VideoThreadParams();
            *threadParams = [threadConfiguration asVideoThreadParams];
            params.mediaThreads_.push_back(threadParams);
        }
    }
    
    return params;
}

-(ndnrtc::new_api::MediaStreamParams)asAudioStreamParams
{
    MediaStreamParams params;
    params.type_ = MediaStreamParams::MediaStreamTypeAudio;
    
    if ([self valueForKey:kSegmentSizeKey])
        params.producerParams_.segmentSize_ = [[self valueForKey:kSegmentSizeKey] intValue];
    
    if ([self valueForKey:kFreshnessPeriodKey])
        params.producerParams_.freshnessMs_ = [[self valueForKey:kFreshnessPeriodKey] intValue];
    
    if ([self valueForKey:kNameKey])
        params.streamName_ = std::string([(NSString*)[self valueForKey:kNameKey] cStringUsingEncoding:NSASCIIStringEncoding]);
    
    if ([self valueForKey:kInputDeviceKey])
    {
        params.captureDevice_ = new CaptureDeviceParams();
        params.captureDevice_->deviceId_ = [[self valueForKey:kInputDeviceKey] intValue];
    }
    
    if ([self valueForKey:kThreadsArrayKey])
    {
        NSArray *threads = (NSArray *)[self valueForKey:kThreadsArrayKey];
        
        for (NSDictionary *threadConfiguration in threads)
        {
            AudioThreadParams *threadParams = new AudioThreadParams();
            *threadParams = [threadConfiguration asAudioThreadParams];
            params.mediaThreads_.push_back(threadParams);
        }
    }
    
    return params;
}

-(ndnrtc::new_api::VideoThreadParams)asVideoThreadParams
{
    VideoThreadParams params;
    
    if ([self valueForKey:kNameKey])
        params.threadName_ = std::string([(NSString*)[self valueForKey:kNameKey] cStringUsingEncoding:NSASCIIStringEncoding]);
    
    if ([self valueForKey:kFrameRateKey])
        params.coderParams_.codecFrameRate_ = [[self valueForKey:kFrameRateKey] intValue];
    
    if ([self valueForKey:kGopKey])
        params.coderParams_.gop_ = [[self valueForKey:kGopKey] intValue];
    
    if ([self valueForKey:kBitrateKey])
        params.coderParams_.startBitrate_ = [[self valueForKey:kBitrateKey] intValue];
    
    if ([self valueForKey:kMaxBitrateKey])
        params.coderParams_.maxBitrate_ = [[self valueForKey:kMaxBitrateKey] intValue];
    
    if ([self valueForKey:kEncodingHeightKey])
        params.coderParams_.encodeHeight_ = [[self valueForKey:kEncodingHeightKey] intValue];
    
    if ([self valueForKey:kEncodingWidthKey])
        params.coderParams_.encodeWidth_ = [[self valueForKey:kEncodingWidthKey] intValue];
    
    if ([self valueForKey:kDeltaAverageSegNumKey])
        params.deltaAvgSegNum_ = [[self valueForKey:kDeltaAverageSegNumKey] floatValue];
    
    if ([self valueForKey:kDeltaAverageParSegNumKey])
        params.deltaAvgParitySegNum_ = [[self valueForKey:kDeltaAverageParSegNumKey] floatValue];
    
    if ([self valueForKey:kKeyAverageSegNumKey])
        params.keyAvgSegNum_ = [[self valueForKey:kKeyAverageSegNumKey] floatValue];
    
    if ([self valueForKey:kKeyAverageParSegNumKey])
        params.keyAvgParitySegNum_ = [[self valueForKey:kKeyAverageParSegNumKey] floatValue];
    
    return params;
}

-(ndnrtc::new_api::AudioThreadParams)asAudioThreadParams
{
    AudioThreadParams params;
    
    if ([self valueForKey:kNameKey])
        params.threadName_ = std::string([(NSString*)[self valueForKey:kNameKey] cStringUsingEncoding:NSASCIIStringEncoding]);
    
    return params;
}

+(instancetype)configurationWithVideoStreamParams:(ndnrtc::new_api::MediaStreamParams &)params
{
    NSMutableDictionary *streamConfiguration = [NSMutableDictionary
                                                dictionaryWithDictionary:
                                                @{
                                                  kNameKey: [NSString stringWithCString:params.streamName_.c_str()
                                                                               encoding:NSASCIIStringEncoding],
                                                  kSegmentSizeKey: @(params.producerParams_.segmentSize_),
                                                  kFreshnessPeriodKey: @(params.producerParams_.freshnessMs_)
                                                  }];
    
    if (params.captureDevice_)
        [streamConfiguration setObject: @(params.captureDevice_->deviceId_) forKey:kInputDeviceKey];
    
    NSMutableArray *threads = [NSMutableArray array];
    
    for (int i = 0; i < params.mediaThreads_.size(); i++)
    {
        VideoThreadParams *threadParams = (VideoThreadParams*)params.mediaThreads_[i];
        [threads addObject:[NSDictionary configurationWithVideoThreadParams:*threadParams]];
    }
    
    [streamConfiguration setObject:threads forKey:kThreadsArrayKey];
    
    return [NSDictionary dictionaryWithDictionary:streamConfiguration];
}

+(instancetype)configurationWithAudioStreamParams:(ndnrtc::new_api::MediaStreamParams &)params
{
    NSMutableDictionary *streamConfiguration = [NSMutableDictionary
                                                dictionaryWithDictionary:
                                                @{
                                                  kNameKey: [NSString stringWithCString:params.streamName_.c_str()
                                                                               encoding:NSASCIIStringEncoding],
                                                  kSegmentSizeKey: @(params.producerParams_.segmentSize_),
                                                  kFreshnessPeriodKey: @(params.producerParams_.freshnessMs_)
                                                  }];
    
    if (params.captureDevice_)
        [streamConfiguration setObject: @(params.captureDevice_->deviceId_) forKey:kInputDeviceKey];
    
    NSMutableArray *threads = [NSMutableArray array];
    
    for (int i = 0; i < params.mediaThreads_.size(); i++)
    {
        AudioThreadParams *threadParams = (AudioThreadParams*)params.mediaThreads_[i];
        [threads addObject:[NSDictionary configurationWithAudioThreadParams:*threadParams]];
    }
    
    [streamConfiguration setObject:threads forKey:kThreadsArrayKey];
    
    return [NSDictionary dictionaryWithDictionary:streamConfiguration];
}

+(instancetype)configurationWithVideoThreadParams:(ndnrtc::new_api::VideoThreadParams &)params
{
    return @{
             kNameKey: [NSString stringWithCString:params.threadName_.c_str()
                                          encoding:NSASCIIStringEncoding],
             kFrameRateKey: @(params.coderParams_.codecFrameRate_),
             kGopKey: @(params.coderParams_.gop_),
             kBitrateKey: @(params.coderParams_.startBitrate_),
             kMaxBitrateKey: @(params.coderParams_.maxBitrate_),
             kEncodingWidthKey: @(params.coderParams_.encodeWidth_),
             kEncodingHeightKey: @(params.coderParams_.encodeHeight_),
             kDeltaAverageSegNumKey: @(params.deltaAvgSegNum_),
             kDeltaAverageParSegNumKey: @(params.deltaAvgParitySegNum_),
             kKeyAverageSegNumKey : @(params.keyAvgSegNum_),
             kKeyAverageParSegNumKey: @(params.keyAvgParitySegNum_)
             };
}

+(instancetype)configurationWithAudioThreadParams:(ndnrtc::new_api::AudioThreadParams &)params
{
    return @{
             kNameKey: [NSString stringWithCString:params.threadName_.c_str()
                                          encoding:NSASCIIStringEncoding],
             kBitrateKey: @(90)
             };
}


@end

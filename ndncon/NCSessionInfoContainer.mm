//
//  NCSessionInfoContainer.m
//  NdnCon
//
//  Created by Peter Gusev on 4/24/15.
//  Copyright 2013-2015 Regents of the University of California
//

#include <ndnrtc/ndnrtc-library.h>

#import "NCSessionInfoContainer.h"
#import "NSDictionary+NCNdnRtcAdditions.h"

using namespace ndnrtc;
using namespace ndnrtc::new_api;

@interface NCSessionInfoContainer()
{
    SessionInfo *_sessionInfo;
}

@end

@implementation NCSessionInfoContainer

-(id)initWithSessionInfo:(void*)sessionInfo
{
    self = [super init];
    
    if (self)
    {
        _sessionInfo = new SessionInfo(*((SessionInfo*)sessionInfo));
    }
    
    return self;
}

-(void)dealloc
{
    delete _sessionInfo;
}

+(NCSessionInfoContainer*)containerWithSessionInfo:(void*)sessionInfo
{
    NCSessionInfoContainer *container = [[NCSessionInfoContainer alloc] initWithSessionInfo:sessionInfo];
    return container;
}

+(NCSessionInfoContainer*)audioOnlyContainerWithSessionInfo:(void *)sessionInfo
{
    SessionInfo *audioOnly = new SessionInfo(*((SessionInfo*)sessionInfo));
    audioOnly->videoStreams_.clear();
    
    NCSessionInfoContainer *container = [[NCSessionInfoContainer alloc] initWithSessionInfo:audioOnly];
    delete audioOnly;
    
    return container;
}

+(NCSessionInfoContainer*)videoOnlyContainerWithSessionInfo:(void *)sessionInfo
{
    SessionInfo *videoOnly = new SessionInfo(*((SessionInfo*)sessionInfo));
    videoOnly->audioStreams_.clear();
    
    NCSessionInfoContainer *container = [[NCSessionInfoContainer alloc] initWithSessionInfo:videoOnly];
    delete videoOnly;
    
    return container;
}

-(void*)sessionInfo
{
    return _sessionInfo;
}

-(NSArray *)audioStreamsConfigurations
{
    NSMutableArray *streams = [NSMutableArray array];
    
    if (_sessionInfo)
        for (std::vector<MediaStreamParams*>::iterator it = _sessionInfo->audioStreams_.begin();
             it != _sessionInfo->audioStreams_.end(); it++)
            [streams addObject:[NSDictionary configurationWithAudioStreamParams:*(*it)]];
    
    return streams;
}

-(NSArray *)videoStreamsConfigurations
{
    NSMutableArray *streams = [NSMutableArray array];
    
    if (_sessionInfo)
        for (std::vector<MediaStreamParams*>::iterator it = _sessionInfo->videoStreams_.begin();
             it != _sessionInfo->videoStreams_.end(); it++)
            [streams addObject:[NSDictionary configurationWithVideoStreamParams:*(*it)]];
    
    return streams;
}

-(BOOL)isEqual:(id)object
{
    if (!object || ![object isKindOfClass:[NCSessionInfoContainer class]])
        return NO;
    
    return [[self audioStreamsConfigurations] isEqual:[object audioStreamsConfigurations]] &&
    [[self videoStreamsConfigurations] isEqual:[object videoStreamsConfigurations]];
}

@end
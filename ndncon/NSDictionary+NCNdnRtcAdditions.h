//
//  NSDictionary+NSDictionaty_NCNdnRtcAdditions.h
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Foundation/Foundation.h>
#include <ndnrtc/params.h>

@interface NSDictionary (NCNdnRtcAdditions)

-(ndnrtc::new_api::MediaStreamParams)asAudioStreamParams;
-(ndnrtc::new_api::MediaStreamParams)asVideoStreamParams;
-(ndnrtc::new_api::VideoThreadParams)asVideoThreadParams;
-(ndnrtc::new_api::AudioThreadParams)asAudioThreadParams;

+(instancetype)configurationWithVideoStreamParams:(ndnrtc::new_api::MediaStreamParams&)params;
+(instancetype)configurationWithAudioStreamParams:(ndnrtc::new_api::MediaStreamParams&)params;
+(instancetype)configurationWithVideoThreadParams:(ndnrtc::new_api::VideoThreadParams&)params;
+(instancetype)configurationWithAudioThreadParams:(ndnrtc::new_api::AudioThreadParams&)params;

@end

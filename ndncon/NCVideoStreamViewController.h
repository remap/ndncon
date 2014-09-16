//
//  NCVideoStreamViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCStreamViewController.h"

/**
 * Video stream configuration:
 * {
 *      Name: <stream_name>;
 *      Input device: <device_idx>;
 *      Device configuration: <configuration_idx>;
 *      Synchronized to: <stream_idx>;
 *      Threads: [
 *          {
 *              Name: <thread_name>;
 *              Frame rate: <frame_rate>;
 *              GOP: <GOP>;
 *              Bitrate: <bitrate>;
 *              Max bitrate: <max_bitrate>;
 *              Encoding width: <encoding_width>;
 *              Encoding height: <encoding_height>;
 *          }, ...
 *      ];
 * }
 */

NSString* const kDeviceConfigurationKey;

@interface NCVideoStreamViewController : NCStreamViewController

@end

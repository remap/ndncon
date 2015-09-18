//
//  NCVideoStreamViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright 2013-2015 Regents of the University of California.
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
 *              GOP: <GOP>;
 *              Bitrate: <bitrate>;
 *              Max bitrate: <max_bitrate>;
 *              Encoding width: <encoding_width>;
 *              Encoding height: <encoding_height>;
 *          }, ...
 *      ];
 * }
 */

extern NSString* const kDeviceConfigurationKey;

@interface NCVideoStreamViewController : NCStreamViewController

+(NSDictionary*)defaultScreenConfguration;

@end

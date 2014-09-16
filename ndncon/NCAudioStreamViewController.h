//
//  NCAudioStreamViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCStreamViewController.h"

/**
 * Audio stream configuration:
 * {
 *      Name: <stream_name>;
 *      Input device: <device_idx>;
 *      Synchronized to: <stream_idx>;
 *      Threads: [
 *          {
 *              Name: <thread_name>;
 *              Bitrate: <bitrate>;
 *          }, ...
 *      ];
 * }
 */

@interface NCAudioStreamViewController : NCStreamViewController

@end

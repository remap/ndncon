//
//  NCAudioStreamViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright 2013-2015 Regents of the University of California.
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

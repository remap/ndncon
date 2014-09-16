//
//  NCAudioStreamViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCAudioStreamViewController.h"
#import "NCThreadViewController.h"

@interface NCAudioStreamViewController ()

@end

@implementation NCAudioStreamViewController

+(NSDictionary *)defaultAudioStreamConfguration
{
    return @{
             kNameKey:@"mic",
             kInputDeviceKey:@(0),  // any first device in the list
             kSynchornizedToKey:@(-1),  // index -1 means no synchornization
             kThreadsArrayKey:@[
                     @{
                         kNameKey:@"low",
                         kBitrateKey:@(90)
                         }]
             };
}

@end

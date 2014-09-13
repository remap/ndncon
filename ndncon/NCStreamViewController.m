//
//  NCStreamViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamViewController.h"

NSString* const kNameKey = @"Name";
NSString* const kSynchornizedToKey = @"Synchronized to";
NSString* const kInputDeviceKey = @"Input device";
NSString* const kThreadsArrayKey = @"Threads";
NSString* const kBitrateKey = @"Start bitrate";

@interface NCStreamViewController ()

@end

@implementation NCStreamViewController

-(void)dealloc
{
    self.preferences = nil;
    self.configuration = nil;
}

-(void)awakeFromNib
{
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
}

-(NSString *)streamName
{
    return [self.configuration valueForKey:kNameKey];
}

-(void)setStreamName:(NSString *)streamName
{
    [self.configuration setObject:streamName forKey:kNameKey];
}

@end

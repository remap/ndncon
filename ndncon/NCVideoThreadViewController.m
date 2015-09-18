//
//  NCVideoThread.m
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NCVideoThreadViewController.h"
#import "NCVideoStreamViewController.h"
#import "NSObject+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"

@interface NCVideoThreadViewController ()

@end

@implementation NCVideoThreadViewController

- (id)init
{
    self = [self initWithNibName:@"NCVideoThreadView" bundle:nil];
    
    if (self)
    {
    }
    
    return self;
}

+(NSDictionary*)defaultConfiguration
{
    return @{
             kNameKey:@"mid",
             kFrameRateKey:@(30),
             kGopKey:@(30),
             kBitrateKey:@(700),
             kMaxBitrateKey:@(0),
             kEncodingWidthKey:@(640),
             kEncodingHeightKey:@(480)
             };
}

-(void)startObservingSelf
{
    [super startObservingSelf];
    
    [self addObserver:self forKeyPaths:
     KEYPATH2(configuration, kFrameRateKey),
     KEYPATH2(configuration, kGopKey),
     KEYPATH2(configuration, kBitrateKey),
     KEYPATH2(configuration, kMaxBitrateKey),
     KEYPATH2(configuration, kEncodingHeightKey),
     KEYPATH2(configuration, kEncodingWidthKey),
     nil];
}

-(void)stopObservingSelf
{
    [self removeObserver:self forKeyPaths:
     KEYPATH2(configuration, kFrameRateKey),
     KEYPATH2(configuration, kGopKey),
     KEYPATH2(configuration, kBitrateKey),
     KEYPATH2(configuration, kMaxBitrateKey),
     KEYPATH2(configuration, kEncodingHeightKey),
     KEYPATH2(configuration, kEncodingWidthKey),
     nil];
    
    [super stopObservingSelf];
}

@end

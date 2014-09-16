//
//  NCAudioThreadViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/16/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCAudioThreadViewController.h"

@interface NCAudioThreadViewController ()

@end

@implementation NCAudioThreadViewController

+(NSDictionary *)defaultConfiguration
{
    return @{
             kNameKey:@"mic",
             kBitrateKey:@(90)
             };
}

- (id)init
{
    self = [self initWithNibName:@"NCAudioThreadView" bundle:nil];
    if (self) {
        
    }
    return self;
}



@end

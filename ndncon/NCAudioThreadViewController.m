//
//  NCAudioThreadViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/16/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NCAudioThreadViewController.h"
#import "NSDictionary+NCAdditions.h"

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

//
//  NCErrorController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/2/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCErrorController.h"

@implementation NCErrorController

+(NCErrorController *)sharedInstance
{
    return (NCErrorController*)[super sharedInstance];
}

+(PTNSingleton *)createInstance
{
    return [[NCErrorController alloc] init];
}

-(void)postError:(NSError*)error
{
    NSLog(@"error occurred: %@", error.localizedDescription);
}

-(void)postErrorWithMessage:(NSString*)errorMessage
{
    NSLog(@"error occurred: %@", errorMessage);
}

-(void)postErrorWithCode:(NSInteger)errorCode andMessage:(NSString*)errorMessage
{
    NSLog(@"error with code %d occurred: %@", errorCode, errorMessage);
}

@end

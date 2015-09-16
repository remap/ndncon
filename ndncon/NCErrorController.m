//
//  NCErrorController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/2/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCErrorController.h"

@interface NCErrorController ()

@property (nonatomic) NSLock *alertLock;

@end

@implementation NCErrorController

+(NCErrorController *)sharedInstance
{
    return (NCErrorController*)[super sharedInstance];
}

+(PTNSingleton *)createInstance
{
    return [[NCErrorController alloc] init];
}

+(dispatch_once_t *)token
{
    static dispatch_once_t token;
    return &token;
}

-(instancetype)init
{
    self = [super init];
    
    if (self)
        self.alertLock = [[NSLock alloc] init];
    
    return self;
}

-(void)postError:(NSError*)error
{
    NSLog(@"error occurred: %@", error.localizedDescription);
    [self showAlertWithErrorCode:error.code andMessage:error.localizedDescription];
}

-(void)postErrorWithMessage:(NSString*)errorMessage
{
    NSLog(@"error occurred: %@", errorMessage);
    [self showAlertWithErrorCode:-1 andMessage:errorMessage];
}

-(void)postErrorWithCode:(NSInteger)errorCode andMessage:(NSString*)errorMessage
{
    NSLog(@"error with code %ld occurred: %@", (long)errorCode, errorMessage);
    [self showAlertWithErrorCode: errorCode andMessage:errorMessage];
}

-(void)showAlertWithErrorCode:(NSInteger)errorCode
                   andMessage:(NSString*)errorMessage
{
    if ([self.alertLock tryLock])
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = [NSString stringWithFormat:@"An error (%ld) has occurred:\n%@", errorCode, errorMessage];
            [alert runModal];
        });
        [self.alertLock unlock];
    }
    else
        NSLog(@"Error alert suppressed - alert window is active. Error supressed: %ld-%@",
              (long)errorCode, errorMessage);
}

@end

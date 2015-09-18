//
//  NCErrorController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/2/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Foundation/Foundation.h>
#import "PTNSingleton.h"

@interface NCErrorController : PTNSingleton

+(NCErrorController*)sharedInstance;

-(void)postError:(NSError*)error;
-(void)postErrorWithMessage:(NSString*)errorMessage;
-(void)postErrorWithCode:(NSInteger)errorCode andMessage:(NSString*)errorMessage;

@end

//
//  NCReporter.h
//  NdnCon
//
//  Created by Peter Gusev on 3/13/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import "PTNSingleton.h"
#import "FTPManager.h"

@interface NCReporter : PTNSingleton <FTPManagerDelegate>

+(NCReporter*)sharedInstance;

-(void)addStatReport:(NSString*)statReport;
-(void)flush;
-(void)submit;

@end

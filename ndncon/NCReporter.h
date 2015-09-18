//
//  NCReporter.h
//  NdnCon
//
//  Created by Peter Gusev on 3/13/15.
//  Copyright 2013-2015 Regents of the University of California
//

#import "PTNSingleton.h"
#import "FTPManager.h"

@interface NCReporter : PTNSingleton <FTPManagerDelegate>

+(NCReporter*)sharedInstance;

-(void)addStatReport:(NSString*)statReport;
-(void)flush;
-(void)submit;

@end

//
//  NCSessionInfoContainer.h
//  NdnCon
//
//  Created by Peter Gusev on 4/24/15.
//  Copyright 2013-2015 Regents of the University of California
//

#import <Foundation/Foundation.h>

@interface NCSessionInfoContainer : NSObject

+(NCSessionInfoContainer*)containerWithSessionInfo:(void*)sessionInfo;
+(NCSessionInfoContainer*)audioOnlyContainerWithSessionInfo:(void*)sessionInfo;
+(NCSessionInfoContainer*)videoOnlyContainerWithSessionInfo:(void*)sessionInfo;

-(id)initWithSessionInfo:(void*)sessionInfo;
-(void*)sessionInfo;

-(NSArray*)audioStreamsConfigurations;
-(NSArray*)videoStreamsConfigurations;

@end
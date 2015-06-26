//
//  NCSessionInfoContainer.h
//  NdnCon
//
//  Created by Peter Gusev on 4/24/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
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
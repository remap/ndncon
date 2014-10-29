//
//  NCFaceSingleton.h
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "PTNSingleton.h"
#include <ndn-conference-discovery/chrono-chat.h>

typedef void(^NCFaceSynchronizedBlock)();

@interface NCFaceSingleton : PTNSingleton

+(NCFaceSingleton*)sharedInstance;

-(void)startProcessingEvents;
-(void)stopProcessingEvents;

-(void)performSynchronizedWithFace:(NCFaceSynchronizedBlock)block;
-(void)performSynchronizedWithFaceBlocking:(NCFaceSynchronizedBlock)block;

-(ndn::Face*)getFace;
-(ndn::KeyChain*)getKeyChain;

@end

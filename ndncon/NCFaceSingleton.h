//
//  NCFaceSingleton.h
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "PTNSingleton.h"
#include <ndn-cpp/face.hpp>

typedef void(^NCFaceSynchronizedBlock)();

@interface NCFaceSingleton : PTNSingleton

+(NCFaceSingleton*)sharedInstance;

@property (nonatomic, readonly) BOOL isValid;

-(void)startProcessingEvents;
-(void)stopProcessingEvents;
-(void)markInvalid;
-(void)reset;

-(void)performSynchronizedWithFace:(NCFaceSynchronizedBlock)block;
-(void)performSynchronizedWithFaceBlocking:(NCFaceSynchronizedBlock)block;

-(ndn::Face*)getFace;
-(ndn::KeyChain*)getKeyChain;

@end

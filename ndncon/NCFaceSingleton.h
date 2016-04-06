//
//  NCFaceSingleton.h
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright 2013-2015 Regents of the University of California.
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
-(BOOL)reset;

-(void)performSynchronizedWithFace:(NCFaceSynchronizedBlock)block;
-(void)performSynchronizedWithFaceBlocking:(NCFaceSynchronizedBlock)block;

-(ndn::Face*)getFace;
-(ndn::KeyChain*)getSystemKeyChain;
-(ndn::KeyChain*)getInstanceKeyChain;

@end

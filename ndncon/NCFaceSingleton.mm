//
//  NCFaceSingleton.m
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCFaceSingleton.h"
#import "NCPreferencesController.h"
#import "NCErrorController.h"
#import "NSString+NCAdditions.h"
#import "NSObject+NCAdditions.h"

//******************************************************************************
@interface NCFaceSingleton()
{
    ndn::Face* _face;
    ndn::KeyChain* _keychain;
    dispatch_queue_t _faceQueue;
    BOOL _isRunningFace;
}

@end

//******************************************************************************
@implementation NCFaceSingleton

+(NCFaceSingleton *)sharedInstance
{
    NCFaceSingleton *singleton = (NCFaceSingleton*)[super sharedInstance];
    
    return singleton;
}

+(PTNSingleton *)createInstance
{
    return [[NCFaceSingleton alloc] init];
}

static dispatch_once_t token;
+(dispatch_once_t *)token
{
    return &token;
}

#pragma mark - init&dealloc
-(id)init
{
    self = [super init];
    
    if (self)
    {
        _faceQueue = dispatch_queue_create("ndncon.queue", DISPATCH_QUEUE_SERIAL);
        _face = NULL;
        _keychain = NULL;
        
        if (![self initFace])
            return nil;
        
        _isRunningFace = YES;
        [self runFace];
    }
    
    return self;
}

-(void)dealloc
{
    _isRunningFace = NO;
    delete _keychain;
    delete _face;
}

#pragma mark - public
-(void)startProcessingEvents
{
    dispatch_sync(_faceQueue, ^{
        if (!_isRunningFace)
        {
            _isRunningFace = YES;
            [self runFace];
        }
    });
}

-(void)stopProcessingEvents
{
    dispatch_sync(_faceQueue, ^{
        if (_isRunningFace)
            _isRunningFace = NO;
    });
}

-(BOOL)isValid
{
    return _face && _keychain;
}

-(void)markInvalid
{
    [self stopProcessingEvents];
    [self performSynchronizedWithFaceBlocking:^{
        delete _face;
        _face = NULL;
        delete _keychain;
        _keychain = NULL;
    }];
}

-(void)reset
{   
    [self initFace];
    _isRunningFace = YES;
    [self runFace];
}

-(void)performSynchronizedWithFace:(NCFaceSynchronizedBlock)block
{
    if (self.isValid)
        dispatch_async(_faceQueue, block);
}

-(void)performSynchronizedWithFaceBlocking:(NCFaceSynchronizedBlock)block
{
    if (self.isValid)
        dispatch_sync(_faceQueue, block);
}

-(ndn::Face *)getFace
{
    return _face;
}

-(ndn::KeyChain *)getKeyChain
{
    return _keychain;
}

#pragma mark - private
-(BOOL)initFace
{
    if (_face)
        delete _face;
    
    if (_keychain)
        delete _keychain;
    
    const char* host = [[NCPreferencesController sharedInstance].daemonHost cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned short port = (unsigned short)([NCPreferencesController sharedInstance].daemonPort.intValue);
    
    try {
        _face = new ndn::Face(host, port);
        _keychain = new ndn::KeyChain();
        _face->setCommandSigningInfo(*_keychain, _keychain->getDefaultCertificateName());
    }
    catch (std::exception &exception)
    {
        [[NCErrorController sharedInstance]
         postErrorWithMessage:[NSString ncStringFromCString:exception.what()]];
        
        return NO;
    }
    
    return YES;
}

-(void)runFace
{
    NCFaceSingleton* strongSelf = self;
    dispatch_async(_faceQueue, ^{
        try {
            strongSelf->_face->processEvents();
            usleep(10000);
        } catch (std::exception& exception) {
            NSLog(@"got exception from ndn-cpp face: %s", exception.what());
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (strongSelf->_isRunningFace)
                [strongSelf runFace];
        });
    });
}

@end

//
//  NCFaceSingleton.m
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#include <ndn-cpp/security/key-chain.hpp>

#import "NCFaceSingleton.h"
#import "NCPreferencesController.h"
#import "NCErrorController.h"
#import "NSString+NCAdditions.h"
#import "NSObject+NCAdditions.h"
#import "NCErrorController.h"

//******************************************************************************
@interface NCFaceSingleton()
{
    ndn::Face* _face;
    ndn::KeyChain* _keychain;
    dispatch_queue_t _faceQueue;
    dispatch_source_t _faceTimer;
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
        _faceQueue = dispatch_queue_create("ndncon.faceQueue", DISPATCH_QUEUE_SERIAL);
        _face = NULL;
        _keychain = NULL;
        
        if (![self initFace])
            return nil;
        
        _isRunningFace = NO;
    }
    
    return self;
}

-(void)dealloc
{
    _isRunningFace = NO;
    if (_keychain) delete _keychain;
    if (_face) delete _face;
}

#pragma mark - public
-(void)startProcessingEvents
{
    if (!_isRunningFace)
    {
        _isRunningFace = YES;
        [self setupFaceTimer];
    }
}

-(void)stopProcessingEvents
{
    if (_isRunningFace)
    {
        _isRunningFace = NO;
        [self cancelFaceTimer];
    }
}

-(BOOL)isValid
{
    return _face && _keychain;
}

-(void)markInvalid
{
    [self stopProcessingEvents];
    [self willChangeValueForKey:@"isValid"];
    if (_face) delete _face;
    _face = NULL;
    if (_keychain) delete _keychain;
    _keychain = NULL;
    [self didChangeValueForKey:@"isValid"];
}

-(BOOL)reset
{   
    if ([self initFace])
    {
        _isRunningFace = YES;
        [self runFace];
    }
    
    return [self isValid];
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
        [self willChangeValueForKey:@"isValid"];
        _face = new ndn::Face(host, port);
        _keychain = new ndn::KeyChain();
        
        [self didChangeValueForKey:@"isValid"];
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

-(void)setupFaceTimer
{
    _faceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                        0, 0, _faceQueue);
    if (_faceTimer)
    {
        NCFaceSingleton* strongSelf = self;
        
        dispatch_source_set_timer(_faceTimer, dispatch_walltime(NULL, 0), 10*NSEC_PER_MSEC, 0);
        dispatch_source_set_event_handler(_faceTimer, ^{
            if (strongSelf->_isRunningFace)
                [strongSelf runFace];
        });
        dispatch_resume(_faceTimer);
    }
    else
        [[NCErrorController sharedInstance] postErrorWithMessage:@"Can't start face processing"];
}

-(void)cancelFaceTimer
{
    _faceTimer = nil;
}

-(void)runFace
{
    @autoreleasepool {
        if (_face && _isRunningFace)
            try {
                _face->processEvents();
            } catch (std::exception& exception) {
                [self markInvalid];
                [[NCErrorController sharedInstance]
                 postErrorWithMessage:[NSString stringWithFormat:@"Error while processing Face: %@",
                                       [NSString stringWithCString:exception.what() encoding:NSASCIIStringEncoding]]];
            }
    }
}

@end

//
//  NCNdnRtcLibraryController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/18/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCNdnRtcLibraryController.h"
#import "NCPreferencesController.h"

#include <ndnrtc/ndnrtc-library.h>

using namespace ndnrtc;
using namespace ndnrtc::new_api;

NSString* const NCSessionStatusUpdateNotification = @"NCSessionStatusUpdateNotificaiton";
NSString* const NCSessionErrorNotification = @"NCSessionErrorNotificaiton";

NSString* const kNCSessionUsernameKey = @"username";
NSString* const kNCSessionPrefixKey = @"prefix";
NSString* const kNCSessionStatusKey = @"status";
NSString* const kNCSessionErrorCodeKey = @"errorCode";
NSString* const kNCSessionErrorMessageKey = @"errorMessage";

class SessionObserver;
static NCNdnRtcLibraryController *SharedInstance = NULL;

//******************************************************************************
@interface NCNdnRtcLibraryController ()
{
    NdnRtcLibrary *_ndnRtcLib;
    SessionObserver *_sessionObserverInstance;
    NSString *_sessionPrefix;
}

@property (nonatomic) NCSessionStatus sessionStatus;

+(ndnrtc::SessionStatus)ndnRtcStatus:(NCSessionStatus)ncStatus;
+(NCSessionStatus)ncStatus:(ndnrtc::SessionStatus)ndnrtcStatus;

@end

//******************************************************************************
class SessionObserver : public ISessionObserver
{
public:
    SessionObserver(){}
    ~SessionObserver(){}

    void
    onSessionStatusUpdate(const char* username, const char* sessionPrefix,
                     SessionStatus status)
    {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:NCSessionStatusUpdateNotification
         object:nil
         userInfo:@{kNCSessionUsernameKey: [NSString stringWithCString:username encoding:NSASCIIStringEncoding],
                    kNCSessionPrefixKey: [NSString stringWithCString:sessionPrefix encoding:NSASCIIStringEncoding],
                    kNCSessionStatusKey: @([NCNdnRtcLibraryController ncStatus:status])}];
        
        [NCNdnRtcLibraryController sharedInstance].sessionStatus = [NCNdnRtcLibraryController ncStatus:status];
    }

    void
    onSessionError(const char* username, const char* sessionPrefix,
                   SessionStatus status, unsigned int errorCode,
                   const char* errorMessage)
    {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:NCSessionErrorNotification
         object:nil
         userInfo:@{kNCSessionUsernameKey: [NSString stringWithCString:username encoding:NSASCIIStringEncoding],
                    kNCSessionPrefixKey: [NSString stringWithCString:sessionPrefix encoding:NSASCIIStringEncoding],
                    kNCSessionStatusKey: @([NCNdnRtcLibraryController ncStatus:status]),
                    kNCSessionErrorCodeKey: @(errorCode),
                    kNCSessionErrorMessageKey: [NSString stringWithCString:errorMessage encoding:NSASCIIStringEncoding]}];
    }
};

//******************************************************************************
@implementation NCNdnRtcLibraryController

+(ndnrtc::SessionStatus)ndnRtcStatus:(NCSessionStatus)ncStatus
{
    ndnrtc::SessionStatus sessionStatus;
    
    switch (ncStatus) {
        case SessionStatusOnlineNotPublishing:
            sessionStatus = ndnrtc::SessionOnlineNotPublishing;
            break;
        case SessionStatusOnlinePublishing:
            sessionStatus = ndnrtc::SessionOnlinePublishing;
            break;
        default:
            sessionStatus = ndnrtc::SessionOffline;
            break;
    }
    
    return sessionStatus;
}

+(NCSessionStatus)ncStatus:(ndnrtc::SessionStatus)ndnrtcStatus
{
    NCSessionStatus sessionStatus;
    
    switch (ndnrtcStatus) {
        case ndnrtc::SessionOnlineNotPublishing:
            sessionStatus = SessionStatusOnlineNotPublishing;
            break;
        case ndnrtc::SessionOnlinePublishing:
            sessionStatus = SessionStatusOnlinePublishing;
            break;
        default:
            sessionStatus = SessionStatusOffline;
            break;
    }
    
    return sessionStatus;
}

// do not allow instantiating
-(id)init
{
    return nil;
}

-(id)initPrivate
{
    self = [super init];
    
    if (self)
        [self instantiateLibrary];
    
    return self;
}

-(void)dealloc
{
    [self releaseLibrary];
}

+(NCNdnRtcLibraryController*)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedInstance = [[NCNdnRtcLibraryController alloc] initPrivate];
    });
    
    return SharedInstance;
}

-(void)instantiateLibrary
{
    _ndnRtcLib = new NdnRtcLibrary(NULL);
    _sessionObserverInstance = new SessionObserver();
}

-(void *)getLibraryObject
{
    return _ndnRtcLib;
}

-(void)releaseLibrary
{
    delete _ndnRtcLib;
    _ndnRtcLib = NULL;
    delete _sessionObserverInstance;
    _sessionObserverInstance = NULL;
}

-(BOOL)startSession
{
    if (_ndnRtcLib)
    {
        std::string username = std::string([[NCPreferencesController sharedInstance].userName cStringUsingEncoding:NSASCIIStringEncoding]);
        GeneralParams generalParams;
        
        [[NCPreferencesController sharedInstance] getNdnRtcGeneralParameters:&generalParams];
        
        std::string sessionPrefix = _ndnRtcLib->startSession(username,
                                                            generalParams,
                                                            _sessionObserverInstance);
        _sessionPrefix = [NSString stringWithCString:sessionPrefix.c_str()
                                           encoding:NSASCIIStringEncoding];
        return (sessionPrefix != "");
    }
    
    return NO;
}

-(BOOL)stopSession
{
    if (_ndnRtcLib)
        return (_ndnRtcLib->stopSession([_sessionPrefix cStringUsingEncoding:NSASCIIStringEncoding]) == RESULT_OK);
    
    return NO;
}

-(NSString *)sessionPrefix
{
    return _sessionPrefix;
}

@end

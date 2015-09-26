//
//  NCNdnRtcLibraryController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/18/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NCNdnRtcLibraryController.h"
#import "NCPreferencesController.h"
#import "NSObject+NCAdditions.h"
#import "NCErrorController.h"
#import "NSString+NCAdditions.h"
#import "NCFaceSingleton.h"
#import "NCDiscoveryLibraryController.h"

#include <ndnrtc/ndnrtc-library.h>
#include <ndnrtc/error-codes.h>

using namespace ndnrtc;
using namespace ndnrtc::new_api;

NSString* const NCLocalSessionStatusUpdateNotification = @"NCLocalSessionStatusUpdateNotificaiton";
NSString* const NCLocalSessionErrorNotification = @"NCLocalSessionErrorNotificaiton";

NSString* const NCRemoteSessionStatusUpdateNotification = @"NCRemoteSessionStatusUpdateNotificaiton";
NSString* const NCRemoteSessionErrorNotification = @"NCRemoteSessionErrorNotificaiton";

NSString* const kSessionUsernameKey = @"username";
NSString* const kSessionPrefixKey = @"prefix";
NSString* const kSessionStatusKey = @"status";
NSString* const kSessionOldStatusKey = @"oldStatus";
NSString* const kSessionErrorCodeKey = @"errorCode";
NSString* const kSessionErrorMessageKey = @"errorMessage";

class SessionObserver;
class LibraryObserver;

static NCNdnRtcLibraryController *SharedInstance = NULL;

//******************************************************************************
@interface NCNdnRtcLibraryController ()
{
    NdnRtcLibrary *_ndnRtcLib;
    SessionObserver *_sessionObserverInstance;
    LibraryObserver *_libObserver;
    NSString *_sessionPrefix;
}

@property (nonatomic) NSString *sessionPrefix;
@property (nonatomic) NCSessionStatus sessionStatus;

+(ndnrtc::SessionStatus)ndnRtcStatus:(NCSessionStatus)ncStatus;
+(NCSessionStatus)ncStatus:(ndnrtc::SessionStatus)ndnrtcStatus;

@end

//******************************************************************************
class LibraryObserver : public INdnRtcLibraryObserver
{
public:
    void onStateChanged(const char *state, const char *args)
    {
        @autoreleasepool {
            NSLog(@"Library state changed: %s - %s", state, args);
        }
    }
    
    void onErrorOccurred(int errorCode, const char* message)
    {
        @autoreleasepool {
            [[NCErrorController sharedInstance] postErrorWithCode:errorCode
                                                       andMessage:[NSString ncStringFromCString:message]];
            
            switch (errorCode) {
                case NRTC_ERR_SIGPIPE:
                {
                    if ([NCNdnRtcLibraryController sharedInstance].sessionPrefix)
                        [[NCNdnRtcLibraryController sharedInstance] stopSession];
                    
                    [[NCFaceSingleton sharedInstance] markInvalid];
                }
                    break;
                default:
                    // do nothing
                    break;
            }
        }
    }
};

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
        @autoreleasepool {
            if (![NCNdnRtcLibraryController sharedInstance].sessionPrefix)
                [NCNdnRtcLibraryController sharedInstance].sessionPrefix = [NSString stringWithCString:sessionPrefix encoding:NSASCIIStringEncoding];
            
            NCSessionStatus oldStatus = [NCNdnRtcLibraryController sharedInstance].sessionStatus;
            [NCNdnRtcLibraryController sharedInstance].sessionStatus = [NCNdnRtcLibraryController ncStatus:status];
            
            NSLog(@"new local session status - %d", status);
            NSString *usernameStr = [NSString ncStringFromCString:username];
            NSString *sessionPrefixStr = [NSString ncStringFromCString:sessionPrefix];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[NSObject alloc] init] notifyNowWithNotificationName:NCLocalSessionStatusUpdateNotification
                                                           andUserInfo:@{kSessionUsernameKey: usernameStr,
                                                                         kSessionPrefixKey: sessionPrefixStr,
                                                                         kSessionStatusKey: @([NCNdnRtcLibraryController ncStatus:status]),
                                                                         kSessionOldStatusKey: @(oldStatus)}];
            });
        }
    }

    void
    onSessionError(const char* username, const char* sessionPrefix,
                   SessionStatus status, unsigned int errorCode,
                   const char* errorMessage)
    {
        @autoreleasepool {
            [NCNdnRtcLibraryController sharedInstance].sessionStatus = [NCNdnRtcLibraryController ncStatus:status];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[NSObject alloc] init] notifyNowWithNotificationName: NCLocalSessionErrorNotification
                                                           andUserInfo:@{kSessionUsernameKey: [NSString stringWithCString:username encoding:NSASCIIStringEncoding],
                                                                         kSessionPrefixKey: [NSString stringWithCString:sessionPrefix encoding:NSASCIIStringEncoding],
                                                                         kSessionStatusKey: @([NCNdnRtcLibraryController ncStatus:status]),
                                                                         kSessionErrorCodeKey: @(errorCode),
                                                                         kSessionErrorMessageKey: [NSString stringWithCString:errorMessage encoding:NSASCIIStringEncoding]}];
                
            });
        }
    }
    
    void
    onSessionInfoUpdate(const new_api::SessionInfo& sessionInfo)
    {
        @autoreleasepool {
            [[NCUserDiscoveryController sharedInstance]
             announceInfo:[NCSessionInfoContainer containerWithSessionInfo:(new_api::SessionInfo*)&sessionInfo]];
        }
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
    _ndnRtcLib = &(NdnRtcLibrary::getSharedInstance());
    _libObserver = new LibraryObserver();
    _ndnRtcLib->setObserver(_libObserver);
    
    _sessionObserverInstance = new SessionObserver();
}

-(void *)getLibraryObject
{
    return _ndnRtcLib;
}

-(void)releaseLibrary
{
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
    {
        int res = _ndnRtcLib->stopSession([_sessionPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
        _sessionPrefix = nil;
        
        return (res == RESULT_OK);
    }
    
    return NO;
}

-(NSString *)sessionPrefix
{
    return _sessionPrefix;
}

-(NSImage*)imageForSessionStatus:(NCSessionStatus)status
{
    switch (status) {
        case SessionStatusOnlineNotPublishing:
            return [NSImage imageNamed:@"session_passive"];
        case SessionStatusOnlinePublishing:
            return [NSImage imageNamed:@"session_active"];
        default:
            return [NSImage imageNamed:@"session_offline"];
    }
}

@end

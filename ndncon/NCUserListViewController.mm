//
//  NCUserListViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndnrtc/ndnrtc-library.h>

#import "NCUserListViewController.h"
#import "NCNdnRtcLibraryController.h"
#import "NCPreferencesController.h"
#import "NSObject+NCAdditions.h"

NSString* const kNCSessionInfoKey = @"sessionInfo";
NSString* const kNCHubPrefixKey = @"hubPrefix";

using namespace ndnrtc;
using namespace ndnrtc::new_api;

//******************************************************************************
@interface NCSessionInfoContainer()
{
    SessionInfo *_sessionInfo;
}

@end

@implementation NCSessionInfoContainer

-(id)initWithSessionInfo:(void*)sessionInfo
{
    self = [super init];
    
    if (self)
    {
        _sessionInfo = new SessionInfo(*((SessionInfo*)sessionInfo));
    }
    
    return self;
}

-(void)dealloc
{
    delete _sessionInfo;
}

+(NCSessionInfoContainer*)containerWithSessionInfo:(void*)sessionInfo
{
    NCSessionInfoContainer *container = [[NCSessionInfoContainer alloc] initWithSessionInfo:sessionInfo];
    return container;
}

-(void*)sessionInfo
{
    return _sessionInfo;
}

@end

//******************************************************************************
class RemoteSessionObserver : public IRemoteSessionObserver
{
public:
    RemoteSessionObserver(std::string& username, std::string& prefix):
    username_(username), prefix_(prefix) {};
    
private:
    std::string username_, prefix_;
    bool freshStart_ = true;
    unsigned int nTimeouts_ = 0;
    
    NSDictionary* sessionUserInfo()
    {
        return @{kNCSessionUsernameKey: [NSString stringWithCString:username_.c_str() encoding:NSASCIIStringEncoding],
                 kNCHubPrefixKey: [NSString stringWithCString:prefix_.c_str() encoding:NSASCIIStringEncoding]};
    }
    
    void
    onSessionInfoUpdate(const new_api::SessionInfo& sessionInfo)
    {
        std::cout << "session update: " << std::endl << sessionInfo;
        
        freshStart_ = false;
        
        NCSessionStatus status = (sessionInfo.audioStreams_.size() == 0 &&
                                  sessionInfo.videoStreams_.size() == 0)?SessionStatusOnlineNotPublishing:
                                    SessionStatusOnlinePublishing;
        NSMutableDictionary *userInfo = [sessionUserInfo() mutableCopy];
        [userInfo setObject:@(status)
                     forKey:kNCSessionStatusKey];
        [userInfo setObject:[NCSessionInfoContainer containerWithSessionInfo: (void*)&sessionInfo]
                     forKey:kNCSessionInfoKey];
        
        [[[NSObject alloc] init]
         notifyNowWithNotificationName:NCSessionStatusUpdateNotification
         andUserInfo:userInfo];
    }
    
    void
    onUpdateFailedWithTimeout()
    {
        nTimeouts_++;

        if (nTimeouts_ > 5 || freshStart_)
            notifyStatusUpdate(SessionStatusOffline);
        
        freshStart_ = false;
    }
    
    void
    onUpdateFailedWithError(const char* errMsg)
    {
        NSMutableDictionary *userInfo = [sessionUserInfo() mutableCopy];
        
        [userInfo setObject:[NSString stringWithCString:errMsg encoding:NSASCIIStringEncoding]
                     forKey: kNCSessionErrorMessageKey];
        
        [[[NSObject alloc] init]
         notifyNowWithNotificationName:NCSessionErrorNotification
         andUserInfo:userInfo];
    }
    
    void
    notifyStatusUpdate(NCSessionStatus status)
    {
        NSMutableDictionary *userInfo = [sessionUserInfo() mutableCopy];
        
        [userInfo setObject:@(status)
                     forKey:kNCSessionStatusKey];
        
        [[[NSObject alloc] init]
         notifyNowWithNotificationName:NCSessionStatusUpdateNotification
         andUserInfo:userInfo];
    }
};

//******************************************************************************
@interface NCUserListViewController()
{
    std::vector<RemoteSessionObserver*> _sessionObservers;
}

@end

@implementation NCUserListViewController

-(id)init
{
    self = [super init];
    
    if (self)
        [self initialize];
    
    return self;
}

-(void)initialize
{
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    std::string username = [[NCPreferencesController sharedInstance].userName cStringUsingEncoding:NSASCIIStringEncoding];
    std::string prefix = [[NCPreferencesController sharedInstance].prefix cStringUsingEncoding:NSASCIIStringEncoding];
    
    GeneralParams generalParams;
    
    [[NCPreferencesController sharedInstance] getNdnRtcGeneralParameters:&generalParams];
    RemoteSessionObserver *observer = new RemoteSessionObserver(username, prefix);
    lib->setRemoteSessionObserver(username, prefix, generalParams, observer);
    _sessionObservers.push_back(observer);
}

- (void)dealloc
{
    for (int i = 0; i < _sessionObservers.size(); i++)
        delete _sessionObservers[i];
    
    _sessionObservers.clear();
}

@end

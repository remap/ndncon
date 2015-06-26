//
//  NCConferenceDiscoveryController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndn-entity-discovery/entity-discovery.h>
#include <ndn-entity-discovery/external-observer.h>
#include <ndnrtc/ndnrtc-library.h>

#import "NSObject+NCAdditions.h"
#import "NCDiscoveryLibraryController.h"
#import "NCFaceSingleton.h"
#import "Conference.h"
#import "User.h"
#import "AppDelegate.h"
#import "NSString+NCAdditions.h"
#import "NCErrorController.h"

NSString* const NCConferenceDiscoveredNotification = @"NCConferenceDiscoveredNotification";
NSString* const NCConferenceWithdrawedNotification = @"NCConferenceWithdrawedNotification";
NSString* const NCConferenceUpdatedNotificaiton = @"NCConferenceUpdatedNotificaiton";

NSString* const NCUserDiscoveredNotification = @"NCUserDiscoveredNotification";
NSString* const NCUserWithdrawedNotification = @"NCUserWithdrawedNotification";
NSString* const NCUserUpdatedNotificaiton = @"NCUserUpdatedNotificaiton";

//******************************************************************************
using namespace entity_discovery;
using namespace ndnrtc;
using namespace ndnrtc::new_api;

typedef std::map<std::string, ndn::ptr_lib::shared_ptr<EntityInfoBase>> EntityMap;

//******************************************************************************
@interface NSMutableData (NCAdditions)

-(void)appendByte:(const unsigned char)byte;

@end

@implementation NSMutableData (NCAdditions)

-(void)appendByte:(const unsigned char)byte
{
    [self appendBytes:&byte length:1];
}

-(void)appendBytesFromString:(NSString*)string
{
    [self appendBytes:[string dataUsingEncoding:NSASCIIStringEncoding].bytes
               length:string.length];
    [self appendByte:0];
}

@end

//******************************************************************************
class EntityDiscoveryObserver;

@interface NCEntityDiscoveryController ()
{
@protected
    boost::shared_ptr<EntityDiscoveryObserver> _discoveryObserver;
    
@protected
    boost::shared_ptr<EntityDiscovery> _discovery;
    boost::shared_ptr<IEntitySerializer> _entitySerializer;
}

@property (nonatomic) BOOL isInitialized;
@property (nonatomic, readonly) NSManagedObjectContext *context;

-(void)onAddMessage:(const std::string&)msg withTimestamp:(double)timestamp;
-(void)onRemoveMessage:(const std::string&)msg withTimestamp:(double)timestamp;
-(void)onSetMessage:(const std::string&)msg withTimestamp:(double)timestamp;

@end

//******************************************************************************
class EntityDiscoveryObserver : public IDiscoveryObserver
{
public:
    EntityDiscoveryObserver(NCEntityDiscoveryController *controller):controller_(controller){}
    ~EntityDiscoveryObserver(){}
    
    void
    onStateChanged(MessageTypes type, const char *msg, double timestamp)
    {
        NSLog(@"DISCOVERY: type: %d, msg: %s, timestamp: %f", type, msg, timestamp);
        std::string msgStr(msg);
        
        if (controller_)
            switch (type) {
                case MessageTypes::ADD:
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [controller_ onAddMessage:msgStr withTimestamp:timestamp];
                    });
                }
                    break;
                case MessageTypes::REMOVE:
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [controller_ onRemoveMessage:msgStr withTimestamp:timestamp];
                    });
                }
                    break;
                case MessageTypes::SET:{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [controller_ onSetMessage:msgStr withTimestamp:timestamp];
                    });
                }
                    break;
                default:
                    break;
            }
    }

private:
    __weak NCEntityDiscoveryController *controller_;
};

//******************************************************************************
@implementation NCEntityDiscoveryController

-(id)init
{
    self = [super init];
    
    if (self)
    {
        if (![NCFaceSingleton sharedInstance])
            return nil;
        
        [self subscribeForNotificationsAndSelectors:NCLocalSessionStatusUpdateNotification,
         @selector(onLocalSessionStatusChanged:)];
        [[NCFaceSingleton sharedInstance] startProcessingEvents];
        
        _discoveryObserver.reset(new EntityDiscoveryObserver(self));
    }
    
    return self;
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
}

-(NSManagedObjectContext *)context
{
    return [(AppDelegate*)[NSApp delegate] managedObjectContext];
}

-(void)onLocalSessionStatusChanged:(NSNotification*)notification
{
    NCSessionStatus status = (NCSessionStatus)[notification.userInfo[kSessionStatusKey] integerValue];
    NCSessionStatus oldStatus = (NCSessionStatus)[notification.userInfo[kSessionOldStatusKey] integerValue];

    if (status == SessionStatusOffline)
    {
        [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
            try {
                _discovery->shutdown();
                NSLog(@"discovery shut down");
            }
            catch (std::exception &exception){
                [[NCFaceSingleton sharedInstance] markInvalid];
                NSLog(@"exception while shutting down discovery: %@",
                      [NSString ncStringFromCString:exception.what()]);
            }
        }];
        
        [self onLocalSessionOffline];
    }
    else {
        if (oldStatus == SessionStatusOffline)
        {
            [self onLocalSessionOnline];
        }
    }
}

-(void)onLocalSessionOnline
{
    @throw [NSException exceptionWithName:@"NCExcpetionUnimplemented"
                                   reason:@"unimplemented"
                                 userInfo:nil];
}

-(void)onLocalSessionOffline
{
    @throw [NSException exceptionWithName:@"NCExcpetionUnimplemented"
                                   reason:@"unimplemented"
                                 userInfo:nil];
}

-(void)onAddMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    @throw [NSException exceptionWithName:@"NCExcpetionUnimplemented"
                                   reason:@"unimplemented"
                                 userInfo:nil];
}

-(void)onRemoveMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    @throw [NSException exceptionWithName:@"NCExcpetionUnimplemented"
                                   reason:@"unimplemented"
                                 userInfo:nil];
}

-(void)onSetMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    @throw [NSException exceptionWithName:@"NCExcpetionUnimplemented"
                                   reason:@"unimplemented"
                                 userInfo:nil];
}

@end

//******************************************************************************
class ConferenceDescription : public EntityInfoBase
{
public:
    ConferenceDescription():conference_(nil), conferenceDictionary_(nil){}
    ConferenceDescription(Conference *conference):conference_(conference), conferenceDictionary_(nil){}
    ConferenceDescription(NSDictionary *dictionary):conference_(nil),conferenceDictionary_(dictionary){}
    ~ConferenceDescription()
    {
        if (conference_)
            conference_ = nil;
        
        if (conferenceDictionary_)
            conferenceDictionary_ = nil;
    }
    
    Conference*
    getConference()
    { return conference_; }
    
    NSDictionary*
    getConferenceDictionary()
    { return conferenceDictionary_; }
    
private:
    Conference *conference_;
    NSDictionary *conferenceDictionary_;
};

//******************************************************************************
class ConferenceDescriptionSerializer : public IEntitySerializer
{
public:
    ConferenceDescriptionSerializer(){}
    
    ndn::Blob
    serialize(const boost::shared_ptr<EntityInfoBase> &description)
    {
        boost::shared_ptr<ConferenceDescription> conferenceDescription = boost::dynamic_pointer_cast<ConferenceDescription>(description);
        Conference *conference = conferenceDescription->getConference();
        NSString *organizerName = [NCPreferencesController sharedInstance].userName;
        NSString *organizerPrefix = [NCPreferencesController sharedInstance].prefix;
        
        // conference is stored in the following format:
        // [<name>\0<description>\0
        //  <stat_time_string>\0<duration>\0
        //  <organizer_name>\0<organizer_prefix>\0
        //  <participant_num>\0
        //  [<participant1_name>\0<participant1_prefix>\0, ...]]
        NSMutableData *data = [NSMutableData data];
        
        [data appendBytesFromString:conference.name];
        [data appendBytesFromString:conference.conferenceDescription];
        [data appendBytesFromString:[@([conference.startDate timeIntervalSince1970]) stringValue]];
        [data appendBytesFromString:conference.duration.stringValue];
        [data appendBytesFromString:organizerName];
        [data appendBytesFromString:organizerPrefix];
        [data appendBytesFromString:[NSString stringWithFormat:@"%lu", (unsigned long)conference.participants.count]];
        
        for (User *user in conference.participants)
        {
            [data appendBytesFromString:user.name];
            [data appendBytesFromString:user.prefix];
        }
        
        return ndn::Blob((const uint8_t*)data.bytes, data.length);
    }
    
    boost::shared_ptr<EntityInfoBase>
    deserialize(ndn::Blob srcBlob)
    {
        boost::shared_ptr<ConferenceDescription> description;
        
        if (srcBlob.isNull())
        {
            NSLog(@"got NULL blob");
        }
        else
        {
            static NSArray *fields =@[kConferenceNameKey, kConferenceDescriptionKey,
                                      kConferenceStartDateKey, kConferenceDurationKey,
                                      kConferenceOrganizerNameKey,
                                      kConferenceOrganizerPrefixKey];
            NSUInteger fieldIdx = 0;
            NSMutableDictionary *conferenceDictionary = [NSMutableDictionary dictionary];
            int i = 0;
            
            for (fieldIdx = 0; fieldIdx < fields.count; fieldIdx++)
            {
                NSString *field = [NSString ncStringFromCString:(const char*)(&(srcBlob.buf()[i]))];
                i += field.length;
                conferenceDictionary[fields[fieldIdx]] = field;
                i++;
            }
            
            NSString *participantsNumStr = [NSString ncStringFromCString:(const char*)(&(srcBlob.buf()[i]))];
            NSUInteger participantsNum = [participantsNumStr integerValue];
            
            conferenceDictionary[kConferenceParticipantsKey] = [NSMutableArray array];
            
            if (participantsNum)
            {
                i += participantsNumStr.length+1;
                
                for (int j = 0; j < participantsNum; j++)
                {
                    NSString *participant = [NSString ncStringFromCString:(const char*)&(srcBlob.buf()[i])];
                    i += participant.length+1;
                    NSString *participantPrefix = [NSString ncStringFromCString:(const char*)&(srcBlob.buf()[i])];
                    i += participantPrefix.length+1;
                    
                    [conferenceDictionary[kConferenceParticipantsKey]
                     addObject:@{kConferenceParticipantNameKey:participant,
                                 kConferenceParticipantPrefixKey:participantPrefix}];
                }
            }
            
            description.reset(new ConferenceDescription(conferenceDictionary));
        }
        
        return description;
    }
};

//******************************************************************************
@interface NCConferenceDiscoveryController()

@property (nonatomic) NSArray *discoveredConferences;

@end


//******************************************************************************
@implementation NCConferenceDiscoveryController

+(NCConferenceDiscoveryController*)sharedInstance
{
    return (NCConferenceDiscoveryController*)[super sharedInstance];
}

+(PTNSingleton *)createInstance
{
    return [[NCConferenceDiscoveryController alloc] init];
}

+(dispatch_once_t *)token
{
    static dispatch_once_t token;
    return &token;
}

#pragma mark - init & dealloc
-(id)init
{
    self = [super init];
    
    if (self)
    {
        _entitySerializer.reset(new ConferenceDescriptionSerializer());
        self.isInitialized = NO;
    }
    
    return self;
}

#pragma mark - public
-(NSArray *)discoveredConferences
{
    __block NSMutableArray *conferences = [NSMutableArray array];

    if (self.isInitialized)
    {
        [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
            EntityMap conferenceMap = _discovery->getDiscoveredEntityList();
            
            EntityMap::iterator it = conferenceMap.begin();
            while (it != conferenceMap.end())
            {
                boost::shared_ptr<ConferenceDescription> conferenceDescription =
                boost::dynamic_pointer_cast<ConferenceDescription>(it->second);
                [conferences addObject:[[NCRemoteConference alloc] initWithDictionary:conferenceDescription->getConferenceDictionary()]];
                it++;
            }
        }];
    }
    
    return [NSArray arrayWithArray:conferences];
}

-(void)announceConference:(Conference*)conference
{
    if (self.isInitialized)
        [self publishConference:conference];
}

-(void)withdrawConference:(Conference*)conference
{
    assert(conference);
    
    if (self.isInitialized)
    {
        std::string conferenceName([conference.name cStringUsingEncoding:NSASCIIStringEncoding]);
        std::string conferencePrefix([[NCConferenceDiscoveryController
                                       conferencesAppPrefixWithHubPrefix:[NCPreferencesController sharedInstance].prefix]
                                      cStringUsingEncoding:NSASCIIStringEncoding]);
        _discovery->stopPublishingEntity(conferenceName, conferencePrefix);
        NSLog(@"withdrawn conference %@", conference.name);
    }
}

#pragma mark - private
-(void)onLocalSessionOnline
{
    if (!self.isInitialized)
    {
        if (![NCFaceSingleton sharedInstance].isValid)
            [[NCFaceSingleton sharedInstance] reset];
        [self initConferenceDiscovery];
    }
    
    if (self.isInitialized)
        [self publishConferences];
}
-(void)onLocalSessionOffline
{
    [self withdrawConferences];
    self.isInitialized = NO;
    _discovery.reset();
    self.discoveredConferences = [NSArray array];
}

-(void)onAddMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    boost::shared_ptr<ConferenceDescription> description =
    boost::dynamic_pointer_cast<ConferenceDescription>(_discovery->getEntity(std::string(msg)));
    
    NSLog(@"new conference discovered: %@", description->getConference().name);
    
    [[[NSObject alloc] init]
     notifyNowWithNotificationName:NCConferenceDiscoveredNotification
     andUserInfo:description->getConferenceDictionary()];
    
}

-(void)onRemoveMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    NSLog(@"conference withdrawn: %@", [NSString ncStringFromCString:msg.c_str()]);
}

-(void)onSetMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    boost::shared_ptr<ConferenceDescription> description =
    boost::dynamic_pointer_cast<ConferenceDescription>(_discovery->getEntity(std::string(msg)));
    
    NSLog(@"conference updated: %@", description->getConference().name);
    
    [[[NSObject alloc] init]
     notifyNowWithNotificationName:NCConferenceUpdatedNotificaiton
     andUserInfo:description->getConferenceDictionary()];
}

-(void)publishConference:(Conference*)conference
{
    assert(conference);
    
    std::string conferenceName([conference.name cStringUsingEncoding:NSASCIIStringEncoding]);
    std::string conferencePrefix([[NCConferenceDiscoveryController
                                  conferencesAppPrefixWithHubPrefix:[NCPreferencesController sharedInstance].prefix]
                                  cStringUsingEncoding:NSASCIIStringEncoding]);
    boost::shared_ptr<EntityInfoBase> conferenceDescription(new ConferenceDescription(conference));
    
    [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
        try {
            _discovery->publishEntity(conferenceName,
                                      conferencePrefix,
                                      conferenceDescription);
            NSLog(@"published conference %@", conference.name);
        } catch (std::exception &exception) {
            NSLog(@"Exception while publishing conference: %@", [NSString ncStringFromCString:exception.what()]);
            [[NCFaceSingleton sharedInstance] markInvalid];
        }
    }];
    
}

-(void)initConferenceDiscovery
{
    std::string broadcastPrefix([[NCPreferencesController sharedInstance].conferenceBroadcastPrefix
                                 cStringUsingEncoding:NSASCIIStringEncoding]);
    _discovery.reset(new EntityDiscovery(broadcastPrefix,
                                         _discoveryObserver.get(),
                                         _entitySerializer,
                                         *[[NCFaceSingleton sharedInstance] getFace],
                                         *[[NCFaceSingleton sharedInstance] getKeyChain],
                                         [[NCFaceSingleton sharedInstance] getKeyChain]->getDefaultCertificateName()));
    
    [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
        try {
            _discovery->start();
            NSLog(@"initialized conference discovery");
        }
        catch (std::exception &exception) {
            _discovery.reset();
            NSLog(@"Exception while initializing conference discovery: %@",
                  [NSString ncStringFromCString:exception.what()]);
            [[NCFaceSingleton sharedInstance] markInvalid];
        }
    }];
    
    self.isInitialized = (_discovery.get() != NULL);
}

-(void)publishConferences
{
    NSArray *conferences = [Conference allConferencesFromContext:self.context];
    NSArray *ongoingAndFutureConferences = [conferences filteredArrayUsingPredicate:
                                            [NSPredicate predicateWithBlock:
                                             ^BOOL(Conference *conference, NSDictionary *bindings) {
        NSDate *conferenceEndDate = [conference.startDate dateByAddingTimeInterval:[conference.duration doubleValue]];
        NSComparisonResult res = [conferenceEndDate compare:[NSDate date]];
        return (res == NSOrderedSame) || (res == NSOrderedDescending);
    }]];
    
    [ongoingAndFutureConferences enumerateObjectsUsingBlock:^(Conference *conference, NSUInteger idx, BOOL *stop) {
        [self publishConference:conference];
    }];
}

-(void)withdrawConferences
{
    if (self.isInitialized)
    {
        NSLog(@"Withdrawing all published conferences...");
        
        EntityMap hostedConferences = _discovery->getHostedEntityList();

        for (EntityMap::iterator it = hostedConferences.begin(); it != hostedConferences.end(); ++it)
        {
            Conference *conference = boost::dynamic_pointer_cast<ConferenceDescription>(it->second)->getConference();
            [self withdrawConference:conference];
        }
    }
}

+(NSString*)conferencesAppPrefixWithHubPrefix:(NSString*)hubPrefix
{
    return [NSString stringWithFormat:@"%@/%@/conference",
            hubPrefix, [NSString ndnRtcAppNameComponent]];;
}

@end

//******************************************************************************
@interface NCActiveUserInfo ()

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *prefix;
@property (nonatomic) NCSessionInfoContainer *sessionInfo;

@end

@implementation NCActiveUserInfo

-(instancetype)initWithUsername:(NSString*)username
                         prefix:(NSString*)prefix
                 andSessionInfo:(NCSessionInfoContainer*)sessionInfo
{
    if ((self = [super init]))
    {
        _username = username;
        _prefix = prefix;
        _sessionInfo = sessionInfo;
    }
    
    return self;
}

@end

//******************************************************************************
class UserInfo : public EntityInfoBase
{
public:
    UserInfo(const SessionInfo &sessionInfo):sessionInfo_(new SessionInfo(sessionInfo)){}
    ~UserInfo(){}
    
    boost::shared_ptr<SessionInfo>
    getSessionInfo()
    { return sessionInfo_; }
    
private:
    std::string username_;
    std::string prefix_;
    boost::shared_ptr<SessionInfo> sessionInfo_;
};

class UserInfoSerializer : public IEntitySerializer
{
public:
    UserInfoSerializer(){}
    
    ndn::Blob
    serialize(const boost::shared_ptr<EntityInfoBase> &info)
    {
        boost::shared_ptr<UserInfo> userInfo = boost::dynamic_pointer_cast<UserInfo>(info);
        SessionInfo *sessionInfo = userInfo->getSessionInfo().get();
        unsigned int length = 0;
        unsigned char *bytes;
        ndnrtc::NdnRtcLibrary *lib = ((ndnrtc::NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject]);
        
        lib->serializeSessionInfo(*sessionInfo, length, &bytes);
        
        if (length)
        {
            ndn::Blob blob((const uint8_t*)bytes, length);
            free(bytes);
            return blob;
        }
        
        return ndn::Blob();
    }
    
    boost::shared_ptr<EntityInfoBase>
    deserialize(ndn::Blob srcBlob)
    {
        SessionInfo sessionInfo;
        ndnrtc::NdnRtcLibrary *lib = ((ndnrtc::NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject]);
        
        bool res = lib->deserializeSessionInfo(srcBlob.size(),
                                               (const unsigned char*)srcBlob.buf(),
                                               sessionInfo);

        if (res)
        {
            boost::shared_ptr<UserInfo> userInfo(new UserInfo(sessionInfo));
            return userInfo;
        }
        
        return boost::shared_ptr<EntityInfoBase>();
    }
};

@interface NCUserDiscoveryController ()

@property (nonatomic) NSArray *discoveredUsers;

@end

@implementation NCUserDiscoveryController

+(NCUserDiscoveryController *)sharedInstance
{
    return (NCUserDiscoveryController*)[super sharedInstance];
}

+(PTNSingleton *)createInstance
{
    return [[NCUserDiscoveryController alloc] init];
}

+(dispatch_once_t *)token
{
    static dispatch_once_t token;
    return &token;
}

#pragma mark - init & dealloc
-(id)init
{
    self = [super init];
    
    if (self)
    {
        _entitySerializer.reset(new UserInfoSerializer());
        self.isInitialized = NO;
    }
    
    return self;
}

#pragma mark - public
-(NSArray *)discoveredUsers
{
    __block NSMutableArray *users = [NSMutableArray array];
    
    if (self.isInitialized)
        [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
            EntityMap userMap = _discovery->getDiscoveredEntityList();
            EntityMap::iterator it = userMap.begin();
            
            while (it != userMap.end()) {
                boost::shared_ptr<UserInfo> userInfo = boost::dynamic_pointer_cast<UserInfo>(it->second);
                
                [users addObject:[NCSessionInfoContainer containerWithSessionInfo:userInfo->getSessionInfo().get()]];
            }
        }];
    
    return [NSArray arrayWithArray:users];
}

-(void)announceInfo:(NCSessionInfoContainer *)sessionInfo
{
    assert(sessionInfo);
    
    if (self.isInitialized)
    {
        NSString *userFullName = [NCNdnRtcLibraryController sharedInstance].sessionPrefix;
        NSString *userInfoPrefix = [userFullName stringByAppendingNdnComponent:[NSString ndnRtcSessionInfoComponent]
                                    ];
        boost::shared_ptr<UserInfo> userInfo(new UserInfo(*(SessionInfo*)sessionInfo.sessionInfo));
        
        [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
            try {
                std::string entityName([userFullName cStringUsingEncoding:NSASCIIStringEncoding]);
                std::string entityPrefix([userInfoPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
                _discovery->publishEntity(entityName, entityPrefix, userInfo);
                
                NSLog(@"published user info: %@", userInfoPrefix);
            } catch (std::exception &exception) {
                NSLog(@"Exception while announcing user info: %@", [NSString ncStringFromCString:exception.what()]);
                [[NCFaceSingleton sharedInstance] markInvalid];
            }
        }];
    }
}

-(void)withdrawInfo
{
    if (self.isInitialized)
    {
        NSString *userFullName = [NCNdnRtcLibraryController sharedInstance].sessionPrefix;
        NSString *userInfoPrefix = [userFullName stringByAppendingNdnComponent:[NSString ndnRtcSessionInfoComponent]
                                    ];
        std::string entityName([userFullName cStringUsingEncoding:NSASCIIStringEncoding]);
        std::string entityPrefix([userInfoPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
        
        _discovery->stopPublishingEntity(entityName, entityPrefix);
        NSLog(@"withdrawn user info %@", userFullName);
    }
}

#pragma mark - private
-(void)onLocalSessionOnline
{
    if (!self.isInitialized)
    {
        if (![NCFaceSingleton sharedInstance].isValid)
            [[NCFaceSingleton sharedInstance] reset];
        [self initUserDiscovery];
    }
}

-(void)onLocalSessionOffline
{
    self.isInitialized = NO;
    _discovery.reset();
    self.discoveredUsers = [NSArray array];
}

#pragma mark - private
-(void)initUserDiscovery
{
    std::string broadcastPrefix([[NCPreferencesController sharedInstance].userBroadcastPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    _discovery.reset(new EntityDiscovery(EntityDiscovery(broadcastPrefix,
                                                         _discoveryObserver.get(),
                                                         _entitySerializer,
                                                         *[[NCFaceSingleton sharedInstance] getFace],
                                                         *[[NCFaceSingleton sharedInstance] getKeyChain],
                                                         [[NCFaceSingleton sharedInstance] getKeyChain]->getDefaultCertificateName())));
    
    [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
        try {
            _discovery->start();
            NSLog(@"initialized user discovery");
        } catch (std::exception &exception) {
            _discovery.reset();
            NSLog(@"Exception while initializing user discovery: %@", [NSString ncStringFromCString:exception.what()]);
            [[NCFaceSingleton sharedInstance] markInvalid];
        }
    }];
    
    self.isInitialized = (_discovery.get() != NULL);
}

-(void)onAddMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    boost::shared_ptr<UserInfo> description =
    boost::dynamic_pointer_cast<UserInfo>(_discovery->getEntity(std::string(msg)));
    NCSessionInfoContainer *sessionInfoContainer = [NCSessionInfoContainer containerWithSessionInfo:description->getSessionInfo().get()];
    NSString *userName = [[NSString ncStringFromCString:msg.c_str()] getNdnRtcUserName];
    
    NSLog(@"user discovered: %@", userName);
    
    [self notifyNowWithNotificationName:NCUserDiscoveredNotification
                            andUserInfo:@{kSessionPrefixKey: userName,
                                          kSessionInfoKey: sessionInfoContainer}];
}

-(void)onRemoveMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    NSLog(@"user disappeared: %@", [NSString ncStringFromCString:msg.c_str()]);
    NSString *userName = [[NSString ncStringFromCString:msg.c_str()] getNdnRtcUserName];
    
    [self notifyNowWithNotificationName:NCUserWithdrawedNotification
                            andUserInfo:@{kSessionPrefixKey: userName}];
}

-(void)onSetMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    boost::shared_ptr<UserInfo> description =
    boost::dynamic_pointer_cast<UserInfo>(_discovery->getEntity(msg));
    NCSessionInfoContainer *sessionInfoContainer = [NCSessionInfoContainer containerWithSessionInfo:description->getSessionInfo().get()];
    NSString *userName = [[NSString ncStringFromCString:msg.c_str()] getNdnRtcUserName];
    
    NSLog(@"user updated: %@", userName);
    
    [self notifyNowWithNotificationName:NCUserUpdatedNotificaiton
                            andUserInfo:@{kSessionPrefixKey: userName,
                                          kSessionInfoKey: sessionInfoContainer}];
}

@end

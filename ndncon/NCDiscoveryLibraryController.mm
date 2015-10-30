//
//  NCConferenceDiscoveryController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#include <ndn-entity-discovery/entity-discovery.h>
#include <ndn-entity-discovery/external-observer.h>
#include <ndnrtc/ndnrtc-library.h>
#include <ndnrtc/name-components.h>

#import "NSObject+NCAdditions.h"
#import "NCNdnRtcLibraryController.h"
#import "NCDiscoveryLibraryController.h"
#import "NCFaceSingleton.h"
#import "Conference.h"
#import "User.h"
#import "AppDelegate.h"
#import "NSString+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"
#import "NCErrorController.h"

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

NSString* const NCConferenceDiscoveredNotification = @"NCConferenceDiscoveredNotification";
NSString* const NCConferenceWithdrawedNotification = @"NCConferenceWithdrawedNotification";
NSString* const NCConferenceUpdatedNotificaiton = @"NCConferenceUpdatedNotificaiton";

NSString* const NCUserDiscoveredNotification = @"NCUserDiscoveredNotification";
NSString* const NCUserWithdrawedNotification = @"NCUserWithdrawedNotification";
NSString* const NCUserUpdatedNotificaiton = @"NCUserUpdatedNotificaiton";

NSString* const NCChatroomDiscoveredNotification = @"NCChatroomDiscoveredNotification";
NSString* const NCChatroomWithdrawedNotification = @"NCChatroomWithdrawedNotification";
NSString* const NCChatroomUpdatedNotificaiton = @"NCChatroomUpdatedNotificaiton";
NSString* const kChatroomKey = @"chatroom";

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
        @autoreleasepool {
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
        
        [self subscribeForNotificationsAndSelectors:
         NCLocalSessionStatusUpdateNotification,@selector(onLocalSessionStatusChanged:),
         nil];
        
        _discoveryObserver.reset(new EntityDiscoveryObserver(self));
    }
    
    return self;
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
}

-(NSString*)description
{
    return @"discovery mechanism";
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
        [self onLocalSessionOffline];
    else if (oldStatus == SessionStatusOffline)
        [self onLocalSessionOnline];
}

-(void)onLocalSessionOnline
{
    [self initDiscovery];
}

-(void)onLocalSessionOffline
{
    [self shutdown];
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

-(NSString*)broadcastPrefix
{
    @throw [NSException exceptionWithName:@"NCExcpetionUnimplemented"
                                   reason:@"unimplemented"
                                 userInfo:nil];
}

-(void)initDiscovery
{
    if (!self.isInitialized)
    {
        if ([NCFaceSingleton sharedInstance].isValid)
        {   
            [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
                try {
                    std::string broadcastPrefix([[self broadcastPrefix] cStringUsingEncoding:NSASCIIStringEncoding]);
                    _discovery.reset(new EntityDiscovery(broadcastPrefix,
                                                         _discoveryObserver.get(),
                                                         _entitySerializer,
                                                         *[[NCFaceSingleton sharedInstance] getFace],
                                                         *[[NCFaceSingleton sharedInstance] getKeyChain],
                                                         [[NCFaceSingleton sharedInstance] getKeyChain]->getDefaultCertificateName()));
                    _discovery->start();
                    NSLog(@"initialized %@", self);
                }
                catch (std::exception &exception) {
                    [self failInit:[NSString ncStringFromCString:exception.what()]];
                }
            }];
            
            self.isInitialized = (_discovery.get() != NULL);
        }
    }
    
    if (self.isInitialized)
        [[NCFaceSingleton sharedInstance] addObserver:self
                                          forKeyPaths:@"isValid", nil];
}

-(void)failInit:(NSString*)what
{
    _discovery.reset();
    [[NCFaceSingleton sharedInstance] markInvalid];
    [[NCNdnRtcLibraryController sharedInstance] stopSession];
    
    [[NCErrorController sharedInstance] postErrorWithMessage:
     [NSString stringWithFormat:@"Can't initialize %@: %@", self, what]];
}

-(void)shutdown
{
    if (self.isInitialized)
    {
        NSLog(@"shutdown discovery for %@", NSStringFromClass([self class]));
        [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
            try {
                _discovery->shutdown();
            }
            catch (std::exception &exception){
                NSLog(@"exception while shutting down discovery: %@",
                      [NSString ncStringFromCString:exception.what()]);
            }
        }];
        
        self.isInitialized = NO;
        _discovery.reset();
        
        [[NCFaceSingleton sharedInstance] removeObserver:self
                                             forKeyPaths:@"isValid", nil];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary<NSString *,id> *)change
                      context:(void *)context
{
    if (object == [NCFaceSingleton sharedInstance])
    {
        if (![NCFaceSingleton sharedInstance].isValid)
        {
            [self shutdown];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[NCNdnRtcLibraryController sharedInstance] stopSession]; 
            });
        }
    }
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
class UserInfo : public EntityInfoBase
{
public:
    UserInfo(const std::string& username,
             const std::string& prefix,
             const SessionInfo &sessionInfo):
    sessionInfo_(new SessionInfo(sessionInfo)),
    username_(username),
    prefix_(prefix)
    {}
    
    ~UserInfo()
    {}
    
    boost::shared_ptr<SessionInfo>
    getSessionInfo()
    { return sessionInfo_; }
    
    std::string
    getUsername()
    { return username_; }
    
    std::string
    getPrefix()
    { return prefix_; }
    
private:
    std::string username_;
    std::string prefix_;
    boost::shared_ptr<SessionInfo> sessionInfo_;
};

//******************************************************************************
@interface NCActiveUserInfo ()
{
    NSArray *_streamConfigurations;
}

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *prefix DEPRECATED;
@property (nonatomic) NSString *sessionPrefix;
@property (nonatomic) NSString *hubPrefix;

@end

@implementation NCActiveUserInfo

+(NSArray*)selectFetchThreadsFromStreamArray:(NSArray*)streamArray
                      withDefaultThreadArray:(NSArray*)defaultThreadsArray
{
    NSMutableArray *streamConfigurations = [NSMutableArray array];
    
    for (NSDictionary *stream in streamArray)
    {
        NSMutableDictionary *streamToFetch = [NSMutableDictionary dictionaryWithDictionary:stream];
        [streamToFetch removeObjectForKey:kThreadsArrayKey];
        
        NSArray *threads = stream[kThreadsArrayKey];
        
        if (threads.count)
        {
            NSDictionary *threadToFetch = stream[kThreadsArrayKey][0];
            
            for (NSDictionary *thread in threads)
            {
                NSString *threadId = [NSString stringWithFormat:@"%@:%@", stream[kNameKey], thread[kNameKey]];
                
                if ([defaultThreadsArray indexOfObject:threadId] != NSNotFound)
                {
                    threadToFetch = thread;
                    break;
                }
            } // for thread
            
            streamToFetch[kThreadsArrayKey] = @[threadToFetch];
            [streamConfigurations addObject:streamToFetch];
        } // if
    } // for stream
    
    return [NSArray arrayWithArray:streamConfigurations];
}

-(instancetype)initWithUserInfo:(UserInfo*)userInfo
{
    if ((self = [super init]))
    {
        _username = [NSString ncStringFromCString:userInfo->getUsername().c_str()];
        _sessionPrefix = [NSString ncStringFromCString: userInfo->getPrefix().c_str()];
        _hubPrefix = [_sessionPrefix getNdnRtcHubPrefix];
        _sessionInfo = [NCSessionInfoContainer containerWithSessionInfo:userInfo->getSessionInfo().get()];
    }
    
    return self;
}

-(void)setSessionInfo:(NCSessionInfoContainer *)sessionInfo
{
    _sessionInfo = sessionInfo;
    [self updateStreamConfigurations];
}

-(NSArray *)streamConfigurations
{
    if (!_streamConfigurations)
        [self updateStreamConfigurations];
    
    return _streamConfigurations;
}

-(NSUInteger)hash
{
    return NSUINTROTATE([_sessionPrefix hash], NSUINT_BIT / 2) ^ [_username hash] ^ [self.streamConfigurations hash];
}

-(BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    
    if ([object isKindOfClass:[NCActiveUserInfo class]])
    {
        NCActiveUserInfo *other = object;
        BOOL equal = [self.username isEqualToString: other.username] &&
        [self.sessionPrefix isEqualToString:other.sessionPrefix];// &&
//        [_streamConfigurations isEqualToArray:other.streamConfigurations];
        
        return equal; //(self.hash == other.hash);
    }
    
    return NO;
}

-(BOOL)isEqualTo:(id)object
{
    return [self isEqual:object];
}

-(void)updateStreamConfigurations
{
    NSMutableArray *streams = [NSMutableArray arrayWithArray:self.sessionInfo.audioStreamsConfigurations];
    [streams addObjectsFromArray:self.sessionInfo.videoStreamsConfigurations];
    _streamConfigurations = [NSArray arrayWithArray:streams];
}

-(NSArray *)getDefaultFetchAudioThreads
{
    NSDictionary *userFetchOptions = [[NCPreferencesController sharedInstance] getFetchOptionsForUser:self.username withPrefix:self.sessionPrefix];
    NSArray *defaultAudioThreads = userFetchOptions[kUserFetchOptionDefaultAudioThreadsKey];
    
    return [NCActiveUserInfo selectFetchThreadsFromStreamArray:self.sessionInfo.audioStreamsConfigurations
                                        withDefaultThreadArray:defaultAudioThreads];
}

-(NSArray *)getDefaultFetchVideoThreads
{
    NSDictionary *userFetchOptions = [[NCPreferencesController sharedInstance] getFetchOptionsForUser:self.username withPrefix:self.sessionPrefix];
    NSArray *defaultVideoThreads = userFetchOptions[kUserFetchOptionDefaultVideoThreadsKey];

    return [NCActiveUserInfo selectFetchThreadsFromStreamArray:self.sessionInfo.videoStreamsConfigurations
                                        withDefaultThreadArray:defaultVideoThreads];
}

@end

//******************************************************************************
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
        ndnrtc::INdnRtcLibrary *lib = ((ndnrtc::INdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject]);
        
        if (lib)
        {
            lib->serializeSessionInfo(*sessionInfo, length, &bytes);
            
            if (length)
            {
                ndn::Blob blob((const uint8_t*)bytes, length);
                free(bytes);
                return blob;
            }
        }
        
        return ndn::Blob();
    }
    
    boost::shared_ptr<EntityInfoBase>
    deserialize(ndn::Blob srcBlob)
    {
        SessionInfo sessionInfo;
        ndnrtc::INdnRtcLibrary *lib = ((ndnrtc::INdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject]);
        
        if (lib)
        {
            bool res = lib->deserializeSessionInfo(srcBlob.size(),
                                                   (const unsigned char*)srcBlob.buf(),
                                                   sessionInfo);
            
            if (res)
            {
                NSString *sessionPrefix = [NSString ncStringFromCString: sessionInfo.sessionPrefix_.c_str()];
                
                if (sessionPrefix)
                {
                    NSString *username = [sessionPrefix getNdnRtcUserName];
                    
                    if (username && sessionPrefix)
                    {
                        boost::shared_ptr<UserInfo> userInfo(new UserInfo([username cStringUsingEncoding:NSASCIIStringEncoding],
                                                                          [sessionPrefix cStringUsingEncoding:NSASCIIStringEncoding],
                                                                          sessionInfo));
                        return userInfo;
                    }
                }
            }
        }
        
        return boost::shared_ptr<EntityInfoBase>();
    }
};

//******************************************************************************
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

-(NSString*)description
{
    return @"user discovery mechanism";
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
                
                [users addObject:[[NCActiveUserInfo alloc] initWithUserInfo: userInfo.get()]];
                it++;
            }
        }];
    
    return [NSArray arrayWithArray:users];
}

-(NCActiveUserInfo*)userWithName:(NSString*)username andHubPrefix:(NSString*)prefix
{
    NSArray *users = [self.discoveredUsers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NCActiveUserInfo *userInfo, NSDictionary *bindings) {
        return [userInfo.username isEqualToString:username] && [userInfo.hubPrefix isEqualToString:prefix];
    }]];
    
    return (users.count) ? [users firstObject] : nil;
}

-(void)announceInfo:(NCSessionInfoContainer *)sessionInfo
{
    assert(sessionInfo);
    
    if (self.isInitialized)
    {
        NSString *userFullName = [NCNdnRtcLibraryController sharedInstance].sessionPrefix;
        NSString *userInfoPrefix = [userFullName stringByAppendingNdnComponent:[NSString ndnRtcSessionInfoComponent]
                                    ];
        boost::shared_ptr<UserInfo> userInfo(new UserInfo([[userFullName getNdnRtcUserName] cStringUsingEncoding:NSASCIIStringEncoding],
                                                          [userFullName cStringUsingEncoding:NSASCIIStringEncoding],
                                                          *(SessionInfo*)sessionInfo.sessionInfo));
        
        [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
            try {
                std::string entityName([userFullName cStringUsingEncoding:NSASCIIStringEncoding]);
                std::string entityPrefix([userInfoPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
                _discovery->publishEntity(entityName, entityPrefix, userInfo);
            } catch (std::exception &exception) {
                NSLog(@"Exception while announcing user info: %@", [NSString ncStringFromCString:exception.what()]);
                [[NCFaceSingleton sharedInstance] markInvalid];
                [[NCErrorController sharedInstance] postErrorWithMessage:[NSString ncStringFromCString:exception.what()]];
            }
        }];
    }
}

-(void)withdrawInfo
{
    if (self.isInitialized)
    {
        EntityMap chatroomsMap = _discovery->getHostedEntityList();
        
        for (auto user:chatroomsMap)
        {
            boost::shared_ptr<UserInfo> userInfo = boost::dynamic_pointer_cast<UserInfo>(user.second);
            std::string entityName(NameComponents::getUserPrefix(userInfo->getUsername(), userInfo->getPrefix()));
            std::string entityPrefix([[[NSString ncStringFromCString:entityName.c_str()] stringByAppendingNdnComponent:[NSString ndnRtcSessionInfoComponent]] cStringUsingEncoding:NSASCIIStringEncoding]);
            
            _discovery->stopPublishingEntity(entityName, entityPrefix);
            NSLog(@"withdrawn user %s", userInfo->getUsername().c_str());
        }
    }
}

#pragma mark - private
-(void)shutdown
{
    [super shutdown];
    [self withdrawInfo];
    self.discoveredUsers = [NSArray array];
}

#pragma mark - private
-(NSString*)broadcastPrefix
{
    return [NCPreferencesController sharedInstance].userBroadcastPrefix;
}

-(void)onAddMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    boost::shared_ptr<UserInfo> description =
    boost::dynamic_pointer_cast<UserInfo>(_discovery->getEntity(std::string(msg)));
    NCActiveUserInfo *userInfo = [[NCActiveUserInfo alloc] initWithUserInfo:description.get()];
    
    NSLog(@"user discovered: %@", userInfo.username);
    
    [self notifyNowWithNotificationName:NCUserDiscoveredNotification
                            andUserInfo:@{kUserInfoKey: userInfo}];
}

-(void)onRemoveMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    NSLog(@"user disappeared: %@", [NSString ncStringFromCString:msg.c_str()]);
    NSString *userName = [[NSString ncStringFromCString:msg.c_str()] getNdnRtcUserName];
    NSString *hubPrefx = [[NSString ncStringFromCString:msg.c_str()] getNdnRtcHubPrefix];
    
    NCActiveUserInfo *userInfo = [[NCActiveUserInfo alloc] init];
    userInfo.username = userName;
    userInfo.hubPrefix = hubPrefx;
    
    [self notifyNowWithNotificationName:NCUserWithdrawedNotification
                            andUserInfo:@{kUserInfoKey: userInfo}];
}

-(void)onSetMessage:(const std::string&)msg withTimestamp:(double)timestamp
{
    boost::shared_ptr<UserInfo> description =
    boost::dynamic_pointer_cast<UserInfo>(_discovery->getEntity(std::string(msg)));
    NCActiveUserInfo *userInfo = [[NCActiveUserInfo alloc] initWithUserInfo:description.get()];
    
//    NSLog(@"user updated: %@", userInfo.username);
    
    [self notifyNowWithNotificationName:NCUserUpdatedNotificaiton
                            andUserInfo:@{kUserInfoKey: userInfo}];
}

@end

//******************************************************************************
class ChatroomInfo : public EntityInfoBase
{
public:
    ChatroomInfo(const std::string& chatroomName,
                 const std::vector<std::string>& participants):
    chatroomName_(chatroomName), participants_(participants)
    {}
    ChatroomInfo(NSString *chatroomName,
                 NSArray *participants)
    {
        chatroomName_ = std::string([chatroomName cStringUsingEncoding:NSASCIIStringEncoding]);
        
        for (NSString *participant in participants)
            participants_.push_back(std::string([participant cStringUsingEncoding:NSASCIIStringEncoding]));
    }
    ~ChatroomInfo()
    {}
    
    std::string
    getChatroomName()
    { return chatroomName_; }
    
    std::vector<std::string>
    getParticipants()
    { return participants_; }
    
private:
    std::string chatroomName_;
    std::vector<std::string> participants_;
};

//******************************************************************************
class ChatroomInfoSerializer : public IEntitySerializer
{
public:
    ChatroomInfoSerializer(){}
    
    ndn::Blob
    serialize(const boost::shared_ptr<EntityInfoBase>& info)
    {
        boost::shared_ptr<ChatroomInfo> chatroomInfo = boost::dynamic_pointer_cast<ChatroomInfo>(info);
        std::vector<std::string> participants = chatroomInfo->getParticipants();
        unsigned int allocatedSize = (unsigned int)(chatroomInfo->getChatroomName().size()+1+participants.size()*512);
        unsigned char *bytes = (unsigned char*)malloc(allocatedSize);
        
        memset(bytes, 0, allocatedSize);
        memcpy(bytes, chatroomInfo->getChatroomName().c_str(), chatroomInfo->getChatroomName().size());
        
        unsigned int actualSize = (unsigned int)(chatroomInfo->getChatroomName().size()+1);
        
        for (std::string participant:participants)
        {
            if (actualSize+participant.size()+1 >= allocatedSize)
            {
                allocatedSize = 2*allocatedSize;
                bytes = (unsigned char*)realloc(bytes, allocatedSize);
            }
            
            memcpy(bytes+actualSize, participant.c_str(), participant.size());
            actualSize += participant.size()+1;
            *((unsigned char*)(bytes+actualSize-1)) = '\0';
        }
        
        ndn::Blob blob((const uint8_t*)bytes, actualSize);
        free(bytes);
        
        return blob;
    }
    
    boost::shared_ptr<EntityInfoBase>
    deserialize(ndn::Blob srcBlob)
    {
        const unsigned char *bytes = srcBlob.buf();
        unsigned int index = 0;
        std::string chatroomName;
        std::vector<std::string> participants;
        
        chatroomName = std::string((const char*)bytes+index);
        index += chatroomName.size()+1;
        
        while (index < srcBlob.size()) {
            std::string participant((const char*)bytes+index);
            participants.push_back(participant);
            index += participant.size()+1;
        }
        
        boost::shared_ptr<ChatroomInfo> chatroomInfo(new ChatroomInfo(chatroomName, participants));
        return chatroomInfo;
    }
};

//******************************************************************************
@interface NCChatRoom ()

@property (nonatomic) NSString *chatroomName;
@property (nonatomic) NSArray *participants;

+(NCChatRoom*)chatroomWithInfo:(ChatroomInfo*)chatRoomInfo;

@end

@implementation NCChatRoom

+(NCChatRoom*)chatRoomWithName:(NSString *)chatroomName andParticipants:(NSArray *)participantsArray
{
    NCChatRoom *chatroom = [[NCChatRoom alloc] init];
    
    chatroom.chatroomName = chatroomName;
    chatroom.participants = [NSArray arrayWithArray:participantsArray];
    
    return chatroom;
}

+(NCChatRoom *)chatroomWithInfo:(ChatroomInfo *)chatRoomInfo
{
    NSString *chatroomName = [NSString ncStringFromCString:chatRoomInfo->getChatroomName().c_str()];
    NSMutableArray *participants = [NSMutableArray array];
    
    for (auto participant:chatRoomInfo->getParticipants())
    {
        NSString *nsParticipant = [NSString ncStringFromCString:participant.c_str()];
        [participants addObject:nsParticipant];
    }
    
    return [NCChatRoom chatRoomWithName:chatroomName andParticipants:participants];
}

-(NSString *)description
{
    return self.chatroomName;
}

@end

//******************************************************************************
@interface NCChatroomDiscoveryController ()

@property (nonatomic) NSArray *discoveredChatrooms;

@end

@implementation NCChatroomDiscoveryController

+(NCChatroomDiscoveryController*)sharedInstance
{
    return (NCChatroomDiscoveryController*)[super sharedInstance];
}

+(PTNSingleton*)createInstance
{
    return [[NCChatroomDiscoveryController alloc] init];
}

+(dispatch_once_t*)token
{
    static dispatch_once_t token;
    return &token;
}

#pragma mark - ini & dealloc
-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _entitySerializer.reset(new ChatroomInfoSerializer());
        self.isInitialized = NO;
    }
    return self;
}

-(NSString*)description
{
    return @"chatroom discovery mechanism";
}

#pragma mark - public
-(NCChatRoom *)chatroomWithName:(NSString *)chatroomName
{
    NSArray *chatroom = [self.discoveredChatrooms filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NCChatRoom *cr, NSDictionary *bindings) {
        return [chatroomName isEqualToString:cr.chatroomName];
    }]];
    
    return (chatroom.count) ? [chatroom firstObject] : nil;
}

-(NSArray*)discoveredChatrooms
{
    __block NSMutableArray *chatrooms = [NSMutableArray array];
    
    if (self.isInitialized)
    {
        [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
            EntityMap chatroomsMap = _discovery->getDiscoveredEntityList();
            
            for (auto chatroom:chatroomsMap)
            {
                boost::shared_ptr<ChatroomInfo> chatroomInfo = boost::dynamic_pointer_cast<ChatroomInfo>(chatroom.second);
                [chatrooms addObject:[NCChatRoom chatroomWithInfo:chatroomInfo.get()]];
            }
        }];
    }
    
    _discoveredChatrooms = [NSArray arrayWithArray:chatrooms];
    return _discoveredChatrooms;
}

-(void)announceChatroom:(NCChatRoom *)chatroom
{
    assert(chatroom);
    
    if (self.isInitialized)
    {
        NSString *nsEntityPrefix = [NSString chatroomPrefixForChat:chatroom.chatroomName
                                                            user:[NCPreferencesController sharedInstance].userName
                                                      withPrefix:[NCPreferencesController sharedInstance].prefix];
        boost::shared_ptr<ChatroomInfo> chatroomInfo(new ChatroomInfo(chatroom.chatroomName, chatroom.participants));
        [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
            try {
                std::string entityPrefix([nsEntityPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
                _discovery->publishEntity(chatroomInfo->getChatroomName(),
                                          entityPrefix,
                                          chatroomInfo);
                NSLog(@"published chatroom: %@", chatroom.chatroomName);
            } catch (std::exception& exception) {
                NSLog(@"exception while announcing chatroom: %@", [NSString ncStringFromCString:exception.what()]);
                [[NCFaceSingleton sharedInstance] markInvalid];
                [[NCErrorController sharedInstance] postErrorWithMessage:[NSString ncStringFromCString:exception.what()]];
            }
        }];
    }
}

-(void)withdrawChatroom:(NCChatRoom *)chatroom
{
    assert(chatroom);
    
    if (self.isInitialized)
    {
        std::string chatroomName([chatroom.chatroomName cStringUsingEncoding:NSASCIIStringEncoding]);
        NSString *nsEntityPrefix = [NSString chatroomPrefixForChat:chatroom.chatroomName
                                                              user:[NCPreferencesController sharedInstance].userName
                                                        withPrefix:[NCPreferencesController sharedInstance].prefix];
        std::string entityPrefix([nsEntityPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
        
        _discovery->stopPublishingEntity(chatroomName, entityPrefix);
        NSLog(@"withdrawn chatroom info %@", chatroom.chatroomName);
    }
}

-(void)withdrawAllChatrooms
{
    EntityMap chatroomsMap = _discovery->getHostedEntityList();
    
    [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
        try {
            EntityMap chatroomsMap = _discovery->getDiscoveredEntityList();
            
            for (auto chatroom:chatroomsMap)
            {
                boost::shared_ptr<ChatroomInfo> chatroomInfo = boost::dynamic_pointer_cast<ChatroomInfo>(chatroom.second);
                NSString *nsEntityPrefix = [NSString chatroomPrefixForChat:[NSString ncStringFromCString:chatroomInfo->getChatroomName().c_str()]
                                                                      user:[NCPreferencesController sharedInstance].userName
                                                                withPrefix:[NCPreferencesController sharedInstance].prefix];
                std::string entityPrefix([nsEntityPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
                _discovery->stopPublishingEntity(chatroomInfo->getChatroomName(), entityPrefix);
                NSLog(@"withdrawn chatroom %s", chatroomInfo->getChatroomName().c_str());
            }
        }
        catch (std::exception &e)
        {
            NSLog(@"excpetion while withdrawing chatroom %s", e.what());
            [[NCErrorController sharedInstance] postErrorWithMessage:[NSString ncStringFromCString:e.what()]];
        }
    }];
}

#pragma mark - private
-(NSString*)broadcastPrefix
{
    return [NCPreferencesController sharedInstance].chatBroadcastPrefix;
}

-(void)shutdown
{
    [super shutdown];
    self.discoveredChatrooms = [NSArray array];
}

-(void)onAddMessage:(const std::string &)msg withTimestamp:(double)timestamp
{
    boost::shared_ptr<ChatroomInfo> description = boost::dynamic_pointer_cast<ChatroomInfo>(_discovery->getEntity(std::string(msg)));
    NCChatRoom *chatroom = [NCChatRoom chatroomWithInfo:description.get()];
    
    NSLog(@"chatroom discovered: %@", chatroom.chatroomName);
    [self discoveredChatrooms];
    [self notifyNowWithNotificationName:NCChatroomDiscoveredNotification
                            andUserInfo:@{kChatroomKey:chatroom}];
}

-(void)onRemoveMessage:(const std::string &)msg withTimestamp:(double)timestamp
{
    // it's kinda hacky
    NSString *chatroomName = [[[NSString ncStringFromCString:msg.c_str()] pathComponents] lastObject];
    
    NSLog(@"chatroom closed %@", chatroomName);
    [self notifyNowWithNotificationName:NCChatroomWithdrawedNotification
                            andUserInfo:@{kChatroomKey: chatroomName}];
}

-(void)onSetMessage:(const std::string &)msg withTimestamp:(double)timestamp
{
    boost::shared_ptr<ChatroomInfo> description = boost::dynamic_pointer_cast<ChatroomInfo>(_discovery->getEntity(std::string(msg)));
    NCChatRoom *chatroom = [NCChatRoom chatroomWithInfo:description.get()];

    NSLog(@"chatroom updated: %@", chatroom.chatroomName);
    [self notifyNowWithNotificationName:NCChatroomUpdatedNotificaiton
                            andUserInfo:@{kChatroomKey: chatroom}];
}

@end

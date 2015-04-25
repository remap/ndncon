//
//  NCDiscoveryLibraryController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndn-entity-discovery/entity-discovery.h>
#include <ndn-entity-discovery/external-observer.h>

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

//******************************************************************************
using namespace entity_discovery;
typedef std::map<std::string, ndn::ptr_lib::shared_ptr<EntityInfoBase>> ConferenceMap;

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
class ConferenceDiscoveryObserver : public IDiscoveryObserver
{
public:
    ConferenceDiscoveryObserver(bool isActive):isActive_(isActive),discovery_(NULL){}
    virtual ~ConferenceDiscoveryObserver()
    {}
    
    void
    onStateChanged(MessageTypes type, const char *msg, double timestamp)
    {
        NSLog(@"DISCOVERY: type: %d, msg: %s, timestamp: %f", type, msg, timestamp);
        boost::shared_ptr<ConferenceDescription> description =
            boost::dynamic_pointer_cast<ConferenceDescription>(discovery_->getEntity(std::string(msg)));
        
        if (description.get())
            switch (type) {
                case MessageTypes::ADD:
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[NSObject alloc] init]
                         notifyNowWithNotificationName:NCConferenceDiscoveredNotification
                         andUserInfo:description->getConferenceDictionary()];
                    });
                }
                    break;
                case MessageTypes::REMOVE:
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[NSObject alloc] init]
                         notifyNowWithNotificationName:NCConferenceWithdrawedNotification
                         andUserInfo:description->getConferenceDictionary()];
                    });
                }
                    break;
                case MessageTypes::SET:{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[NSObject alloc] init]
                         notifyNowWithNotificationName:NCConferenceUpdatedNotificaiton
                         andUserInfo:description->getConferenceDictionary()];
                    });
                }
                    break;
                default:
                    break;
            }
    }
    
    void
    setConferenceDiscovery(boost::shared_ptr<EntityDiscovery> discovery)
    { discovery_ = discovery; }
    
    boost::shared_ptr<EntityDiscovery>
    getDiscovery()
    { return discovery_; }

private:
    bool isActive_;
    boost::shared_ptr<EntityDiscovery> discovery_;
};

//******************************************************************************
@interface NCDiscoveryLibraryController()
{
    boost::shared_ptr<ConferenceDiscoveryObserver> _ConferenceDiscoveryObserver;
    boost::shared_ptr<IEntitySerializer> _conferenceDescriptionSerializer;
}

@property (nonatomic) BOOL initialized;
@property (nonatomic, readonly) NSManagedObjectContext *context;

@end


//******************************************************************************
@implementation NCDiscoveryLibraryController

+(NCDiscoveryLibraryController*)sharedInstance
{
    return (NCDiscoveryLibraryController*)[super sharedInstance];
}

+(PTNSingleton *)createInstance
{
    return [[NCDiscoveryLibraryController alloc] init];
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
        _conferenceDescriptionSerializer.reset(new ConferenceDescriptionSerializer());
        
        if (![NCFaceSingleton sharedInstance])
            return nil;
        
        [[NCFaceSingleton sharedInstance] startProcessingEvents];

        self.initialized = NO;
        [self subscribeForNotificationsAndSelectors:
         NCLocalSessionStatusUpdateNotification, @selector(onLocalSessionStatusChanged:),
         nil];
    }
    
    return self;
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
}

#pragma mark - public
-(NSArray *)discoveredConferences
{
    __block NSMutableArray *conferences = [NSMutableArray array];

    if (self.initialized)
    {
        [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
            ConferenceMap conferenceMap = _ConferenceDiscoveryObserver->getDiscovery()->getDiscoveredEntityList();
            
            ConferenceMap::iterator it = conferenceMap.begin();
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
    if (self.initialized)
        [self publishConference:conference];
}

-(void)withdrawConference:(Conference*)conference
{
    assert(conference);
    
    if (self.initialized)
    {
        std::string conferenceName([conference.name cStringUsingEncoding:NSASCIIStringEncoding]);
        std::string conferencePrefix([[NCDiscoveryLibraryController
                                       conferencesAppPrefixWithHubPrefix:[NCPreferencesController sharedInstance].prefix]
                                      cStringUsingEncoding:NSASCIIStringEncoding]);
        _ConferenceDiscoveryObserver->getDiscovery()->stopPublishingEntity(conferenceName, conferencePrefix);
        NSLog(@"withdrawed conference %@", conference.name);
    }
}

#pragma mark - private
-(void)onLocalSessionStatusChanged:(NSNotification*)notification
{
#ifdef CONFERENCES_ENABLED
    NCSessionStatus status = (NCSessionStatus)[notification.userInfo[kSessionStatusKey] integerValue];
    NCSessionStatus oldStatus = (NCSessionStatus)[notification.userInfo[kSessionOldStatusKey] integerValue];
    
    if (status == SessionStatusOffline)
    {
        [self withdrawConferences];
        self.initialized = NO;

        [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
            try {
                _ConferenceDiscoveryObserver->getDiscovery()->shutdown();
                NSLog(@"conference discovery shut down");
            } catch (std::exception &exception) {
                NSLog(@"Exception while shutting down conference discovery: %@",
                      [NSString ncStringFromCString:exception.what()]);
                [[NCFaceSingleton sharedInstance] markInvalid];
            }
        }];
        _ConferenceDiscoveryObserver.reset();
        self.discoveredConferences = [NSArray array];
        [[NCFaceSingleton sharedInstance] markInvalid];
    }
    else
        if (oldStatus == SessionStatusOffline)
        {
            if (!self.initialized)
            {
                if (![NCFaceSingleton sharedInstance].isValid)
                    [[NCFaceSingleton sharedInstance] reset];
                
                [self initConferenceDiscovery];
            }
            
            if (self.initialized)
                [self publishConferences];
        }
#endif
}

-(void)publishConference:(Conference*)conference
{
    assert(conference);
    
    std::string conferenceName([conference.name cStringUsingEncoding:NSASCIIStringEncoding]);
    std::string conferencePrefix([[NCDiscoveryLibraryController
                                  conferencesAppPrefixWithHubPrefix:[NCPreferencesController sharedInstance].prefix]
                                  cStringUsingEncoding:NSASCIIStringEncoding]);
    boost::shared_ptr<EntityInfoBase> conferenceDescription(new ConferenceDescription(conference));
    
    [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
        try {
            _ConferenceDiscoveryObserver->getDiscovery()->publishEntity(conferenceName,
                                                                                conferencePrefix,
                                                                                conferenceDescription);
            NSLog(@"published conference %@", conference.name);
        } catch (std::exception &exception) {
            NSLog(@"Exception while publishing conference: %@", [NSString ncStringFromCString:exception.what()]);
            [[NCFaceSingleton sharedInstance] markInvalid];
        }
    }];
    
}

-(NSManagedObjectContext *)context
{
    return [(AppDelegate*)[NSApp delegate] managedObjectContext];
}

-(void)initConferenceDiscovery
{
    std::string broadcastPrefix([[NCPreferencesController sharedInstance].conferenceBroadcastPrefix
                                 cStringUsingEncoding:NSASCIIStringEncoding]);
    _ConferenceDiscoveryObserver.reset(new ConferenceDiscoveryObserver(true));
    __block boost::shared_ptr<EntityDiscovery> discovery(new EntityDiscovery(broadcastPrefix,
                                                                             _ConferenceDiscoveryObserver.get(),
                                                                             _conferenceDescriptionSerializer,
                                                                             *[[NCFaceSingleton sharedInstance] getFace],
                                                                             *[[NCFaceSingleton sharedInstance] getKeyChain],
                                                                             [[NCFaceSingleton sharedInstance] getKeyChain]->getDefaultCertificateName()));
    
    [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
        try {
            discovery->start();
            NSLog(@"initializing conference discovery..");
        }
        catch (std::exception &exception) {
            discovery.reset();
            NSLog(@"Exception while initializing conference discovery: %@",
                  [NSString ncStringFromCString:exception.what()]);
            [[NCFaceSingleton sharedInstance] markInvalid];
        }
    }];
    
    self.initialized = (discovery.get() != NULL);
    _ConferenceDiscoveryObserver->setConferenceDiscovery(discovery);
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
    if (self.initialized)
    {
        NSLog(@"Withdrawing all published conferences...");
        
        ConferenceMap hostedConferences = _ConferenceDiscoveryObserver->getDiscovery()->getHostedEntityList();

        for (ConferenceMap::iterator it = hostedConferences.begin(); it != hostedConferences.end(); ++it)
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

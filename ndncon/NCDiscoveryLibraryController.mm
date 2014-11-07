//
//  NCDiscoveryLibraryController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndn-conference-discovery/conference-discovery-sync.h>
#include <ndn-conference-discovery/external-observer.h>

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

//******************************************************************************
using namespace conference_discovery;

// change library's names for clarity
typedef ConferenceInfo IDiscoverableEntity;
typedef ConferenceInfoFactory IDiscoverableEntitySerializer;
typedef ConferenceDiscovery EntityBroadcaster;
typedef ConferenceDiscoveryObserver EntityBroadcasterObserver;
typedef std::map<std::string, ndn::ptr_lib::shared_ptr<ConferenceInfo>> ConferenceMap;

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
class ConferenceDescription : public IDiscoverableEntity
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
    
    ndn::Blob
    serialize(const boost::shared_ptr<IDiscoverableEntity> &description)
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
    
    boost::shared_ptr<IDiscoverableEntity>
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
class ConferenceDescriptionSerializer : public IDiscoverableEntitySerializer
{
public:
    ConferenceDescriptionSerializer(ndn::ptr_lib::shared_ptr<IDiscoverableEntity> conferenceInfo):
    IDiscoverableEntitySerializer(conferenceInfo){
    }
};

//******************************************************************************
class ConferenceBroadcasterObserver : public EntityBroadcasterObserver
{
public:
    ConferenceBroadcasterObserver(bool isActive):isActive_(isActive),broadcaster_(NULL){}
    virtual ~ConferenceBroadcasterObserver()
    {}
    
    void
    onStateChanged(MessageTypes type, const char *msg, double timestamp)
    {
        NSLog(@"DISCOVERY: type: %d, msg: %s, timestamp: %f", type, msg, timestamp);
        boost::shared_ptr<IDiscoverableEntity> description = broadcaster_->getConference(std::string(msg));
        
        switch (type) {
            case conference_discovery::MessageTypes::ADD:
            {
                if (description.get())
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[NSObject alloc] init]
                         notifyNowWithNotificationName:NCConferenceDiscoveredNotification
                         andUserInfo:boost::dynamic_pointer_cast<ConferenceDescription>(description)->getConferenceDictionary()];
                    });
                }
            }
                break;
            case conference_discovery::MessageTypes::REMOVE:
            {
                if (description.get())
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[NSObject alloc] init]
                         notifyNowWithNotificationName:NCConferenceWithdrawedNotification
                         andUserInfo:boost::dynamic_pointer_cast<ConferenceDescription>(description)->getConferenceDictionary()];
                    });
                }
            }
                break;
            default:
                break;
        }
    }
    
    void
    setConferenceBroadcaster(boost::shared_ptr<EntityBroadcaster> broadcaster)
    { broadcaster_ = broadcaster; }
    
    boost::shared_ptr<EntityBroadcaster>
    getBroadcaster()
    { return broadcaster_; }

private:
    bool isActive_;
    boost::shared_ptr<EntityBroadcaster> broadcaster_;
};

//******************************************************************************
@interface NCDiscoveryLibraryController()
{
    boost::shared_ptr<ConferenceBroadcasterObserver> _conferenceBroadcasterObserver;
    boost::shared_ptr<IDiscoverableEntitySerializer> _conferenceDescriptionSerializer;
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
        boost::shared_ptr<ConferenceInfo> conferenceDescriptionInstance(new ConferenceDescription());
        _conferenceDescriptionSerializer.reset(new ConferenceDescriptionSerializer(conferenceDescriptionInstance));
        
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
            ConferenceMap conferenceMap = _conferenceBroadcasterObserver->getBroadcaster()->getDiscoveredConferenceList();
            
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
        _conferenceBroadcasterObserver->getBroadcaster()->stopPublishingConference(conferenceName, conferencePrefix);
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
                _conferenceBroadcasterObserver->getBroadcaster()->shutdown();
                NSLog(@"conference discovery shut down");
            } catch (std::exception &exception) {
                NSLog(@"Exception while shutting down conference discovery: %@",
                      [NSString ncStringFromCString:exception.what()]);
                [[NCFaceSingleton sharedInstance] markInvalid];
            }
        }];
        _conferenceBroadcasterObserver.reset();
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
    boost::shared_ptr<EntityBroadcasterObserver> observer(new ConferenceBroadcasterObserver(false));
    boost::shared_ptr<IDiscoverableEntity> conferenceDescription(new ConferenceDescription(conference));
    
    [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
        try {
            _conferenceBroadcasterObserver->getBroadcaster()->publishConference(conferenceName,
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
    _conferenceBroadcasterObserver.reset(new ConferenceBroadcasterObserver(true));
    __block boost::shared_ptr<EntityBroadcaster> discoverer(new EntityBroadcaster(broadcastPrefix,
                                                                                  _conferenceBroadcasterObserver.get(),
                                                                                  _conferenceDescriptionSerializer,
                                                                                  *[[NCFaceSingleton sharedInstance] getFace],
                                                                                  *[[NCFaceSingleton sharedInstance] getKeyChain],
                                                                                  [[NCFaceSingleton sharedInstance] getKeyChain]->getDefaultCertificateName()));
    
    [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
        try {
            discoverer->start();
            NSLog(@"initializing conference discovery..");
        }
        catch (std::exception &exception) {
            discoverer.reset();
            NSLog(@"Exception while initializing conference discovery: %@",
                  [NSString ncStringFromCString:exception.what()]);
            [[NCFaceSingleton sharedInstance] markInvalid];
        }
    }];
    
    self.initialized = (discoverer.get() != NULL);
    _conferenceBroadcasterObserver->setConferenceBroadcaster(discoverer);
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
        
        ConferenceMap hostedConferences = _conferenceBroadcasterObserver->getBroadcaster()->getHostedConferenceList();

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

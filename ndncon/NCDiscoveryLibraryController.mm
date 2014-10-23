//
//  NCDiscoveryLibraryController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndn-conference-discovery/conference-discovery-sync.h>
#include <ndn-conference-discovery/external-observer.h>

#import "NCDiscoveryLibraryController.h"
#import "NCFaceSingleton.h"
#import "Conference.h"
#import "AppDelegate.h"
#import "NSString+NCAdditions.h"

using namespace conference_discovery;

// change library's names for clarity
typedef ConferenceInfo IDiscoverableEntity;
typedef ConferenceInfoFactory IDiscoverableEntitySerializer;
typedef ConferenceDiscovery EntityBroadcaster;
typedef ConferenceDiscoveryObserver EntityBroadcasterObserver;

//******************************************************************************
class ConferenceDescription : public IDiscoverableEntity
{
public:
    ConferenceDescription(){}
    ConferenceDescription(Conference *conference)
    {
        
    }
    
    Blob
    serialize(const ptr_lib::shared_ptr<IDiscoverableEntity> &description)
    {
        return Blob();
    }
    
    ptr_lib::shared_ptr<IDiscoverableEntity>
    deserialize(Blob srcBlob)
    {
        return ptr_lib::make_shared<ConferenceDescription>();
    }
    
private:
    __weak Conference *conference_;
};

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
    ConferenceBroadcasterObserver(bool isActive):isActive_(isActive){}
    ~ConferenceBroadcasterObserver(){}
    
    void
    onStateChanged(MessageTypes type, const char *msg, double timestamp)
    {
        NSLog(@"DISCOVERY: type: %d, msg: %s, timestamp: %f", type, msg, timestamp);
    }
    
    void
    setConferenceBroadcaster(EntityBroadcaster *broadcaster)
    { broadcaster_ = broadcaster; }
    
    EntityBroadcaster*
    getBroadcaster()
    { return broadcaster_; }

private:
    bool isActive_;
    EntityBroadcaster *broadcaster_;
};

//******************************************************************************
typedef std::map<std::string, shared_ptr<ConferenceBroadcasterObserver>> BroadcasterMap;
@interface NCDiscoveryLibraryController()
{
    shared_ptr<EntityBroadcasterObserver> _conferenceBroadcasterObserver;
    shared_ptr<IDiscoverableEntitySerializer> _conferenceDescriptionSerializer;
    BroadcasterMap _nameToBroadcasterObserverMap;
}

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
        shared_ptr<ConferenceInfo> conferenceDescriptionInstance(new ConferenceDescription());
        _conferenceDescriptionSerializer.reset(new ConferenceDescriptionSerializer(conferenceDescriptionInstance));
        
        if (![NCFaceSingleton sharedInstance])
            return nil;
        
        [[NCFaceSingleton sharedInstance] startProcessingEvents];
        
        [self initConferenceDiscovery];
        [self publishConferences];
    }
    
    return self;
}

-(void)dealloc
{
}

#pragma mark - public

#pragma mark - private
-(NSManagedObjectContext *)context
{
    return [(AppDelegate*)[NSApp delegate] managedObjectContext];
}

-(void)initConferenceDiscovery
{
    std::string broadcastPrefix([[NCPreferencesController sharedInstance].conferenceBroadcastPrefix
                                 cStringUsingEncoding:NSASCIIStringEncoding]);
    _conferenceBroadcasterObserver.reset(new ConferenceBroadcasterObserver(true));
    __block EntityBroadcaster *discoverer;
    
    [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
        discoverer = new EntityBroadcaster(broadcastPrefix, _conferenceBroadcasterObserver,
                                           _conferenceDescriptionSerializer,
                                           *[[NCFaceSingleton sharedInstance] getFace],
                                           *[[NCFaceSingleton sharedInstance] getKeyChain],
                                           [[NCFaceSingleton sharedInstance] getKeyChain]->getDefaultCertificateName());
    }];
    
    dynamic_pointer_cast<ConferenceBroadcasterObserver>(_conferenceBroadcasterObserver)->setConferenceBroadcaster(discoverer);
}

-(void)publishConferences
{
    NSArray *conferences = [Conference allConferencesFromContext:self.context];
    NSArray *ongoingAndFutureConferences = [conferences filteredArrayUsingPredicate:
                                            [NSPredicate predicateWithBlock:^BOOL(Conference *conference, NSDictionary *bindings) {
        NSDate *conferenceEndDate = [conference.startDate dateByAddingTimeInterval:[conference.duration doubleValue]];
        NSComparisonResult res = [conferenceEndDate compare:[NSDate date]];
        return (res == NSOrderedSame) || (res == NSOrderedAscending);
    }]];
    
    [ongoingAndFutureConferences enumerateObjectsUsingBlock:^(Conference *conference, NSUInteger idx, BOOL *stop) {
        [self publishConference:conference];
    }];
}

-(void)publishConference:(Conference*)conference
{
    std::string conferenceName([conference.name cStringUsingEncoding:NSASCIIStringEncoding]);
    BroadcasterMap::iterator it = _nameToBroadcasterObserverMap.find(conferenceName);
    
    if (it != _nameToBroadcasterObserverMap.end())
    {
        std::string broadcastPrefix([[NCPreferencesController sharedInstance].conferenceBroadcastPrefix
                                     cStringUsingEncoding:NSASCIIStringEncoding]);
        shared_ptr<EntityBroadcasterObserver> observer(new ConferenceBroadcasterObserver(false));
        __block EntityBroadcaster *conferenceBroadcaster;
        
        [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
            conferenceBroadcaster = new EntityBroadcaster(broadcastPrefix, observer, _conferenceDescriptionSerializer,
                                  *[[NCFaceSingleton sharedInstance] getFace],
                                  *[[NCFaceSingleton sharedInstance] getKeyChain],
                                  [[NCFaceSingleton sharedInstance] getKeyChain]->getDefaultCertificateName());
        }];
        
        dynamic_pointer_cast<ConferenceBroadcasterObserver>(observer)->setConferenceBroadcaster(conferenceBroadcaster);
        _nameToBroadcasterObserverMap[conferenceName] = dynamic_pointer_cast<ConferenceBroadcasterObserver>(observer);
    }
    else
        NSLog(@"conference %@ already exists", conference.name);
}

@end

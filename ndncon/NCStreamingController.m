//
//  NCStreamingController.m
//  NdnCon
//
//  Created by Peter Gusev on 7/8/15.
//  Copyright 2013-2015 Regents of the University of California
//

#import "NCStreamingController.h"
#import "NCStreamViewController.h"
#import "NSObject+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"
#import "NSArray+NCAdditions.h"
#import "NSString+NCAdditions.h"
#import "NCStatisticCollector.h"

NSString* const kNCFetchedStreamsRemovedNotification = @"NCFetchedStreamsRemovedNotification";
NSString* const kNCFetchedStreamsAddedNotification = @"NCFetchedStreamsAddedNotification";
NSString* const kNCFetchedUserRemovedNotification = @"NCFetchedUserRemovedNotification";
NSString* const kNCFetchedUserAddedNotification = @"NCFetchedUserAddedNotification";
NSString* const kNCPublishedStreamsRemovedNotification = @"NCPublishedStreamsRemovedNotification";
NSString* const kNCPublishedStreamsAddedNotification = @"NCPublishedStreamsAddedNotification";

NSString* const kNCStreamConfigurationsKey = @"streams";

//******************************************************************************
@implementation NCFetchedUser

-(id)initWithUsername:(NSString*)username andPrefix:(NSString*)prefix
{
    self = [super init];
    
    if (self)
    {
        _username = username;
        _prefix = prefix;
        _hubPrefix = _prefix; //[_prefix getNdnRtcHubPrefix];
        _fetchedStreams = [NSMutableArray array];
    }
    
    return self;
}

-(NSString *)userId
{
    return [NCFetchedUser userIdForUsername:self.username andPrefix:self.prefix];
}

-(void)removeStreams:(NSArray*)streamConfigurations
{
    NSArray *streamsToRemoveArray = [streamConfigurations valueForKey:kNameKey];
    
    NSArray *streamsToSave = [self.fetchedStreams filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *streamConf, NSDictionary *bindings) {
        return ([streamsToRemoveArray indexOfObject:streamConf[kNameKey]] == NSNotFound);
    }]];
    
    self.fetchedStreams = [streamsToSave mutableCopy];
}

-(void)removeStreamWithName:(NSString*)streamName
{
    NSArray *streamsToSave = [self.fetchedStreams filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *streamConf, NSDictionary *bindings) {
        return ![streamConf[kNameKey] isEqualToString:streamName];
    }]];
    
    self.fetchedStreams = [streamsToSave mutableCopy];
}

-(NSDictionary*)getStreamWithName:(NSString*)streamName
{
    NSArray *foundStreams = [self.fetchedStreams filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *streamConf, NSDictionary *bindings) {
        return [streamConf[kNameKey] isEqualToString:streamName];
    }]];
    
    NSAssert(foundStreams.count <= 1, @"found more than 1 stream with the same name");
    
    return [foundStreams objectAtIndex:0];
}

-(NSArray *)fetchedStreamNames
{
    return [self.fetchedStreams valueForKey:kNameKey];
}

-(NSSet*)fetchedThreadIds
{
    __block NSMutableSet *threadIds = [NSMutableSet set];
    [self.fetchedStreams enumerateObjectsUsingBlock:^(NSDictionary *streamConf, NSUInteger idx, BOOL *stop) {
        [streamConf[kThreadsArrayKey] enumerateObjectsUsingBlock:^(NSDictionary *threadConf, NSUInteger idx, BOOL *stop) {
            [threadIds addObject:[NSString stringWithFormat:@"%@:%@", streamConf[kNameKey], threadConf[kNameKey]]];
        }];
    }];
    
    return [NSSet setWithSet:threadIds];
}

-(NSArray *)fetchedAudioStreams
{
    return [self.fetchedStreams filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *streamConf, NSDictionary *bindings) {
        return ![streamConf isVideoStream];
    }]];
}

-(NSArray *)fetchedVideoStreams
{
    return [self.fetchedStreams filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *streamConf, NSDictionary *bindings) {
        return [streamConf isVideoStream];
    }]];
}

-(NSString*)sessionPrefix
{
    return [NSString userSessionPrefixForUser:self.username withHubPrefix:self.hubPrefix];
}

#pragma mark - static
+(NCFetchedUser*)fetchedUserWithName:(NSString*)username prefix:(NSString*)prefix andStreams:(NSArray*)streams
{
    NCFetchedUser *fetchedUser = [[NCFetchedUser alloc] initWithUsername:username
                                                               andPrefix:prefix];
    fetchedUser.fetchedStreams = [streams mutableCopy];
    return fetchedUser;
}

+(NSString*)userIdForUsername:(NSString*)username andPrefix:(NSString*)prefix
{
    return [NSString userIdWithName:username andPrefix:prefix];
}

@end

//******************************************************************************
@interface NCStreamingController ()

@property (nonatomic) NSMutableArray *publishedStreams;
@property (nonatomic) NSMutableDictionary *fetchedUsers;

@end

@implementation NCStreamingController

+(NCStreamingController *)sharedInstance
{
    return (NCStreamingController*)[super sharedInstance];
}

+(PTNSingleton *)createInstance
{
    return [[NCStreamingController alloc] init];
}

+(dispatch_once_t *)token
{
    static dispatch_once_t token;
    return &token;
}

-(instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _fetchedUsers = [NSMutableDictionary dictionary];
        _publishedStreams = [NSMutableArray array];
    }
    
    return self;
}

-(void)publishStreams:(NSArray *)streamConfigurations
{
    NSSet *publishedStreams = [NSSet setWithArray:[self.publishedStreams valueForKey:kNameKey]];
    NSMutableSet *newStreams = [NSMutableSet setWithArray:[streamConfigurations valueForKey:kNameKey]];
    
    if ([newStreams intersectsSet:publishedStreams])
    {
        __block NSMutableArray *streamsToRemove = [NSMutableArray array];
        NSMutableSet *intersect = [NSMutableSet setWithSet:newStreams];
        [intersect intersectSet:publishedStreams];
        
        for (NSString *streamName in intersect)
        {
            NSDictionary *streamConfiguration = [self.publishedStreams streamWithName:streamName];
            [streamsToRemove addObject:streamConfiguration];
        }
        
        if (streamsToRemove.count)
        {
            [self.publishedStreams removeObjectsInArray:streamsToRemove];
            [self notifyNowWithNotificationName:kNCPublishedStreamsRemovedNotification
                                    andUserInfo:@{kNCStreamConfigurationsKey:streamsToRemove}];
        }
    }
    
    [self.publishedStreams addObjectsFromArray:streamConfigurations];
    [self notifyNowWithNotificationName:kNCPublishedStreamsAddedNotification
                            andUserInfo:@{kNCStreamConfigurationsKey:streamConfigurations}];
}

-(void)stopPublishingStreams:(NSArray *)streamConfigurations
{
    NSSet *publishedStreams = [NSSet setWithArray:[self.publishedStreams valueForKey:kNameKey]];
    NSMutableSet *streamsToStop = [NSMutableSet setWithArray:[streamConfigurations valueForKey:kNameKey]];
    
    [streamsToStop intersectSet:publishedStreams];
    
    if (streamsToStop.count)
    {
        NSMutableArray *streamsToRemove = [NSMutableArray array];
        
        for (NSString *streamName in streamsToStop)
        {
            [streamsToRemove addObject:[streamConfigurations streamWithName:streamName]];
        }
        
        if (streamsToRemove.count)
        {
            [self.publishedStreams removeObjectsInArray:streamsToRemove];
            [self notifyNowWithNotificationName:kNCPublishedStreamsRemovedNotification
                                    andUserInfo:@{kNCStreamConfigurationsKey:streamsToRemove}];
        }
    }
}

-(void)fetchStreams:(NSArray *)streamConfigurations fromUser:(NSString *)username withPrefix:(NSString *)prefix
{
    NCFetchedUser *fetchedUser = self.fetchedUsers[[NCFetchedUser userIdForUsername:username andPrefix:prefix]];
    
    if (!fetchedUser)
    {
        fetchedUser = [NCFetchedUser fetchedUserWithName:username
                                                  prefix:prefix
                                              andStreams:streamConfigurations];
        self.fetchedUsers[fetchedUser.userId] = fetchedUser;
        [fetchedUser notifyNowWithNotificationName:kNCFetchedStreamsAddedNotification
                                       andUserInfo:@{kNCStreamConfigurationsKey:streamConfigurations}];
    }
    else
    {
        NSMutableSet *newThreads = [NSMutableSet set];
        
        [streamConfigurations enumerateObjectsUsingBlock:^(NSDictionary *streamConf, NSUInteger idx, BOOL *stop) {
            [streamConf[kThreadsArrayKey] enumerateObjectsUsingBlock:^(NSDictionary *threadConf, NSUInteger idx, BOOL *stop) {
                [newThreads addObject:[NSString stringWithFormat:@"%@:%@", streamConf[kNameKey], threadConf[kNameKey]]];
            }];
        }];
        
        [newThreads minusSet:fetchedUser.fetchedThreadIds];
        
        if ([newThreads count] > 0)
        {
            NSArray *newStreamNames = [streamConfigurations valueForKey:kNameKey];
            NSArray *fetchedStreamNames = fetchedUser.fetchedStreamNames;
            __block NSMutableArray *removedStreams = [NSMutableArray array];
            
            [newStreamNames enumerateObjectsUsingBlock:^(NSString *streamName, NSUInteger idx, BOOL *stop) {
                if ([fetchedStreamNames indexOfObject:streamName] != NSNotFound)
                {
                    [removedStreams addObject:[fetchedUser getStreamWithName:streamName]];
                    [fetchedUser removeStreamWithName:streamName];
                }
            }];
            
            if (removedStreams.count)
                [fetchedUser notifyNowWithNotificationName:kNCFetchedStreamsRemovedNotification
                                               andUserInfo:@{kNCStreamConfigurationsKey:removedStreams}];
            
            [streamConfigurations enumerateObjectsUsingBlock:^(NSDictionary *streamConf, NSUInteger idx, BOOL *stop) {
                [fetchedUser.fetchedStreams addObject:streamConf];
            }];
            
            [fetchedUser notifyNowWithNotificationName:kNCFetchedStreamsAddedNotification
                                           andUserInfo:@{kNCStreamConfigurationsKey:streamConfigurations}];
        }
    }
    
    if ([NCPreferencesController sharedInstance].writeStatsToFile.boolValue &&
        ![NCStatisticCollector sharedInstance].isRunning)
        [[NCStatisticCollector sharedInstance] start];
    
}

-(void)stopFetchingStreams:(NSArray *)streamConfigurations fromUser:(NSString *)username withPrefix:(NSString *)prefix
{
    NCFetchedUser *fetchedUser = self.fetchedUsers[[NCFetchedUser userIdForUsername:username andPrefix:prefix]];
    
    if (fetchedUser)
    {
        [fetchedUser removeStreams:streamConfigurations];
        
        if (fetchedUser.fetchedStreams.count == 0)
        {
            [fetchedUser notifyNowWithNotificationName:kNCFetchedUserRemovedNotification andUserInfo:@{kNCStreamConfigurationsKey:streamConfigurations}];
            [self.fetchedUsers removeObjectForKey:[NCFetchedUser userIdForUsername:username andPrefix:prefix]];
        }
        else
            [fetchedUser notifyNowWithNotificationName:kNCFetchedStreamsRemovedNotification
                                           andUserInfo:@{kNCStreamConfigurationsKey:streamConfigurations}];
    }
}

-(void)stopFetchingAllStreams
{
    for (NCFetchedUser *userId in self.fetchedUsers.allKeys)
    {
        NCFetchedUser *user = self.fetchedUsers[userId];
        [self stopFetchingStreams:user.fetchedStreams fromUser:user.username withPrefix:user.hubPrefix];
    }
}

-(NSArray *)getCurrentStreamsForUser:(NSString *)username withPrefix:(NSString *)prefix
{
    NCFetchedUser *fetchedUser = self.fetchedUsers[[NCFetchedUser userIdForUsername:username andPrefix:prefix]];
    return fetchedUser ? [NSArray arrayWithArray:fetchedUser.fetchedStreams] : @[];
}

-(NSArray *)allPublishedStreams
{
    return [self.publishedStreams copy];
}

-(NSArray*)allPublishedAudioStreams
{
    return [self.publishedStreams filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *streamConf, NSDictionary *bindings) {
        return ![streamConf isVideoStream];
    }]];
}

-(NSArray *)allPublishedVideoStreams
{
    return [self.publishedStreams filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *streamConf, NSDictionary *bindings) {
        return [streamConf isVideoStream];
    }]];
}

-(NSArray *)allFetchedStreams
{
    __block NSMutableArray *allFetchedStreams = [NSMutableArray array];
    [self.fetchedUsers enumerateKeysAndObjectsUsingBlock:^(id key, NCFetchedUser *user, BOOL *stop) {
        [allFetchedStreams addObjectsFromArray:user.fetchedStreams];
    }];
    return [allFetchedStreams copy];
}

-(NSArray *)allFetchedAudioStreams
{
    __block NSMutableArray *allFetchedStreams = [NSMutableArray array];
    [self.fetchedUsers enumerateKeysAndObjectsUsingBlock:^(id key, NCFetchedUser *user, BOOL *stop) {
        [allFetchedStreams addObjectsFromArray:user.fetchedAudioStreams];
    }];
    return [allFetchedStreams copy];
}

-(NSArray *)allFetchedVideoStreams
{
    __block NSMutableArray *allFetchedStreams = [NSMutableArray array];
    [self.fetchedUsers enumerateKeysAndObjectsUsingBlock:^(id key, NCFetchedUser *user, BOOL *stop) {
        [allFetchedStreams addObjectsFromArray:user.fetchedVideoStreams];
    }];
    return [allFetchedStreams copy];
}

-(NSArray *)allFetchedStreamsForUser:(NSString *)username
                          withPrefix:(NSString *)prefix
{
    NCFetchedUser *fetchedUser = self.fetchedUsers[[NSString userIdWithName:username andPrefix:prefix]];
    
    return (fetchedUser)?[fetchedUser.fetchedStreams copy]:@[];
}

-(NSArray *)allFetchedAudioStreamsForUser:(NSString *)username
                               withPrefix:(NSString *)prefix
{
    NCFetchedUser *fetchedUser = self.fetchedUsers[[NSString userIdWithName:username andPrefix:prefix]];
    
    return (fetchedUser)?[fetchedUser.fetchedAudioStreams copy]:@[];
}

-(NSArray *)allFetchedVideoStreamsForUser:(NSString *)username
                               withPrefix:(NSString *)prefix
{
    NCFetchedUser *fetchedUser = self.fetchedUsers[[NSString userIdWithName:username andPrefix:prefix]];
    
    return (fetchedUser)?[fetchedUser.fetchedVideoStreams copy]:@[];
}

-(NSArray*)allFetchedUsers
{
    NSMutableArray *users = [[NSMutableArray alloc] init];
    
    for (NSString *key in self.fetchedUsers)
        [users addObject:self.fetchedUsers[key]];
    
    return [NSArray arrayWithArray: users];
}

#pragma mark - private
-(void)updateStreamingStatus
{
    
}

@end

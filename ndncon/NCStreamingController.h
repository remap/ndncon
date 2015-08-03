//
//  NCStreamingController.h
//  NdnCon
//
//  Created by Peter Gusev on 7/8/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTNSingleton.h"
#import "NCNdnRtcLibraryController.h"

extern NSString* const kNCFetchedStreamsRemovedNotification;
extern NSString* const kNCFetchedStreamsAddedNotification;
extern NSString* const kNCFetchedUserRemovedNotification;
extern NSString* const kNCFetchedUserAddedNotification;
extern NSString* const kNCPublishedStreamsRemovedNotification;
extern NSString* const kNCPublishedStreamsAddedNotification;

extern NSString* const kNCStreamConfigurationsKey;

//******************************************************************************
@interface NCFetchedUser : NSObject

@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *prefix;
@property (nonatomic, readonly) NSString *hubPrefix;
@property (nonatomic, readonly) NSString *userId;

@property (nonatomic) NSMutableArray *fetchedStreams;
@property (nonatomic, readonly) NSArray *fetchedStreamNames;
@property (nonatomic, readonly) NSSet *fetchedThreadIds;

@property (nonatomic, readonly) NSArray *fetchedAudioStreams;
@property (nonatomic, readonly) NSArray *fetchedVideoStreams;

@end

//******************************************************************************
@interface NCStreamingController : PTNSingleton

+(NCStreamingController*)sharedInstance;

-(void)publishStreams:(NSArray*)streamConfigurations;
-(void)stopPublishingStreams:(NSArray*)streamConfigurations;

-(void)fetchStreams:(NSArray*)streamConfigurations
           fromUser:(NSString*)username
         withPrefix:(NSString*)prefix;
-(void)stopFetchingStreams:(NSArray*)streamConfigurations
                  fromUser:(NSString*)username
                withPrefix:(NSString*)prefix;
-(void)stopFetchingAllStreams;

-(NSArray*)getCurrentStreamsForUser:(NSString*)username
                         withPrefix:(NSString*)prefix;

-(NSArray*)allPublishedStreams;
-(NSArray*)allPublishedAudioStreams;
-(NSArray*)allPublishedVideoStreams;

-(NSArray*)allFetchedStreams;
-(NSArray*)allFetchedAudioStreams;
-(NSArray*)allFetchedVideoStreams;
-(NSArray*)allFetchedStreamsForUser:(NSString*)username
                         withPrefix:(NSString*)prefix;
-(NSArray*)allFetchedAudioStreamsForUser:(NSString*)username
                              withPrefix:(NSString*)prefix;
-(NSArray*)allFetchedVideoStreamsForUser:(NSString*)username
                              withPrefix:(NSString*)prefix;
@end

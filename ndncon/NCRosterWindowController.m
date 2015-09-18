//
//  NCRosterWindowController.m
//  NdnCon
//
//  Created by Peter Gusev on 4/27/15.
//  Copyright 2013-2015 Regents of the University of California
//

#import "NCRosterWindowController.h"
#import "NCDiscoveryLibraryController.h"
#import "NSObject+NCAdditions.h"
#import "NCRosterUserCell.h"
#import "NCStreamViewController.h"
#import "NCStreamingController.h"
#import "NCNdnRtcLibraryController.h"
#import "NSDictionary+NCAdditions.h"

@interface NCRosterWindowController()

@property (weak) IBOutlet NSView *localContrainerView;
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, strong) NSArray *discoveredUsers;

@property (nonatomic) BOOL isAudioPublish;
@property (nonatomic) BOOL isVideoPublish;
@property (nonatomic) BOOL isPublishing;
@property (nonatomic, readonly) BOOL canPublish;

@property (nonatomic) BOOL isGlobalVideoFetchActive;
@property (nonatomic) BOOL isGlobalAudioFetchActive;

@end

@implementation NCRosterWindowController

-(NCPreferencesController *)preferences
{
    return [NCPreferencesController sharedInstance];
}

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _discoveredUsers = @[];
        [self subscribeForNotificationsAndSelectors:NCLocalSessionStatusUpdateNotification, @selector(onLocalSessionStatusUpdate:),
         nil];
    }
    
    return self;
}

-(void)dealloc
{
    self.discoveredUsers = nil;
    [self unsubscribeFromNotifications];
}

-(void)awakeFromNib
{
    [self subscribeForNotificationsAndSelectors:
     NCUserDiscoveredNotification, @selector(onUserDiscovered:),
     NCUserUpdatedNotificaiton, @selector(onUserUpdated:),
     NCUserWithdrawedNotification, @selector(onUserWithdrawed:),
     nil];
    
    NSDictionary *userPublishOptions = [[NCPreferencesController sharedInstance] getFetchOptionsForUser:@"me" withPrefix:@""];
    NSDictionary *globalFetchOptions = [[NCPreferencesController sharedInstance] getGlobalFetchOptions];
    
    self.isAudioPublish = [userPublishOptions[kUserFetchOptionFetchAudioKey] boolValue];
    self.isVideoPublish = [userPublishOptions[kUserFetchOptionFetchVideoKey] boolValue];
    self.isGlobalAudioFetchActive = [globalFetchOptions[kUserFetchOptionFetchAudioKey] boolValue];
    self.isGlobalVideoFetchActive = [globalFetchOptions[kUserFetchOptionFetchVideoKey] boolValue];
    
    [self.window setAcceptsMouseMovedEvents:YES];
}

#pragma mark notifications
-(void)onLocalSessionStatusUpdate:(NSNotification*)notification
{
    self.isPublishing = [notification.userInfo[kSessionStatusKey] intValue] == SessionStatusOnlinePublishing;
}

-(void)onUserDiscovered:(NSNotification*)notification
{
    self.discoveredUsers = [NCUserDiscoveryController sharedInstance].discoveredUsers;
    [self.outlineView reloadData];
}

-(void)onUserUpdated:(NSNotification*)notification
{
    self.discoveredUsers = [NCUserDiscoveryController sharedInstance].discoveredUsers;
    [self.outlineView reloadData];
}

-(void)onUserWithdrawed:(NSNotification*)notification
{
    self.discoveredUsers = [NCUserDiscoveryController sharedInstance].discoveredUsers;
    [self.outlineView reloadData];
}

#pragma mark - actions
- (IBAction)onPublishClick:(id)sender
{
    if (self.isPublishing)
    {
        NSMutableArray *streamsToPublish = [NSMutableArray array];
        
        if (self.isAudioPublish)
            [streamsToPublish addObjectsFromArray:[NCPreferencesController sharedInstance].audioStreams];
        
        if (self.isVideoPublish)
            [streamsToPublish addObjectsFromArray:[NCPreferencesController sharedInstance].videoStreams];
        
        if (streamsToPublish.count)
            [[NCStreamingController sharedInstance] publishStreams:streamsToPublish];
    }
    else
    {
        [[NCStreamingController sharedInstance] stopPublishingStreams:
         [[NCStreamingController sharedInstance] allPublishedStreams]];
    }
}

- (IBAction)onAudioSelected:(id)sender
{
    // save user choice
    [[NCPreferencesController sharedInstance] addFetchOptions:@{kUserFetchOptionFetchAudioKey:@([sender state] == NSOnState)}
                                                      forUser:@"me"
                                                   withPrefix:@""];
    
    
    if (self.isPublishing)
    {
        if (self.isAudioPublish)
        {
            [[NCStreamingController sharedInstance] publishStreams:[NCPreferencesController sharedInstance].audioStreams];
        }
        else
        {
            [[NCStreamingController sharedInstance] stopPublishingStreams:
             [[NCStreamingController sharedInstance] allPublishedAudioStreams]];
        }
    }
}

- (IBAction)onVideoSelected:(id)sender
{
    // save user choice
    [[NCPreferencesController sharedInstance] addFetchOptions:@{kUserFetchOptionFetchVideoKey:@([sender state] == NSOnState)}
                                                      forUser:@"me"
                                                   withPrefix:@""];
    
    if (self.isPublishing)
    {
        if (self.isVideoPublish)
        {
            [[NCStreamingController sharedInstance] publishStreams:[NCPreferencesController sharedInstance].videoStreams];
        }
        else
        {
            [[NCStreamingController sharedInstance] stopPublishingStreams:
             [[NCStreamingController sharedInstance] allPublishedVideoStreams]];
        }
    }
}

- (IBAction)setGlobalVideoFetchingFilter:(id)sender
{
    NSMutableDictionary *options = [[[NCPreferencesController sharedInstance] getGlobalFetchOptions] deepMutableCopy];
    
    options[kUserFetchOptionFetchVideoKey] = @(self.isGlobalVideoFetchActive);
    [[NCPreferencesController sharedInstance] setGlobalFetchOptions:options];
}

- (IBAction)setGlobalAudioFetchingFilter:(id)sender
{
    NSMutableDictionary *options = [[[NCPreferencesController sharedInstance] getGlobalFetchOptions] deepMutableCopy];
    
    options[kUserFetchOptionFetchAudioKey] = @(self.isGlobalAudioFetchActive);
    [[NCPreferencesController sharedInstance] setGlobalFetchOptions:options];
}

#pragma mark - properties
-(BOOL)canPublish
{
    return self.isAudioPublish || self.isVideoPublish;
}

-(void)setIsAudioPublish:(BOOL)isAudioPublish
{
    [self willChangeValueForKey:@"isAudioPublish"];
    [self willChangeValueForKey:@"canPublish"];
    _isAudioPublish = isAudioPublish;
    [self didChangeValueForKey:@"canPublish"];
    [self didChangeValueForKey:@"isAudioPublish"];
}

-(void)setIsVideoPublish:(BOOL)isVideoPublish
{
    [self willChangeValueForKey:@"isVideoPublish"];
    [self willChangeValueForKey:@"canPublish"];
    _isVideoPublish = isVideoPublish;
    [self didChangeValueForKey:@"canPublish"];
    [self didChangeValueForKey:@"isVideoPublish"];
}

#pragma mark - NSOutlineView Delegate and Data Source
-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item && [item isKindOfClass:[NCActiveUserInfo class]])
        return  [[(NCActiveUserInfo*)item streamConfigurations] objectAtIndex:index];
    
    return (!item) ? [self.discoveredUsers objectAtIndex:index] : nil;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (item && [item isKindOfClass:[NCActiveUserInfo class]])
        return [(NCActiveUserInfo*)item streamConfigurations].count > 0;
    
    return !item ? YES : NO;
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item)
        return [(NCActiveUserInfo*)item streamConfigurations].count;
    
    return !item ? self.discoveredUsers.count : 0;
}

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    // make sure stream items are unique
    if ([item isKindOfClass:[NSDictionary class]] &&
        ![item objectForKey:@"id"])
    {
        NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
        newItem[@"id"] = [NSUUID UUID];
        
        return [NSDictionary dictionaryWithDictionary: newItem];
    }
    
    return item;
}

-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([item isKindOfClass:[NCActiveUserInfo class]])
    {
        NCActiveUserInfo *userInfo = (NCActiveUserInfo*)item;
        NCRosterUserCell *userCell = [outlineView makeViewWithIdentifier:@"UserCell" owner:self];
        
        userCell.delegate = self;
        userCell.objectValue = @{@"user": userInfo.username, @"prefix": userInfo.sessionPrefix};
        userCell.userInfo = userInfo;
        
        return userCell;
    }
    
    if ([item isKindOfClass:[NSDictionary class]])
    {
        NCActiveUserInfo *userInfo = [outlineView parentForItem:item];
        NCRosterStreamCell *streamCell = [outlineView makeViewWithIdentifier:@"StreamCell" owner:outlineView];

        streamCell.delegate = self;
        streamCell.objectValue = item;
        streamCell.isFirstRow = ([userInfo.streamConfigurations indexOfObject:item] == 0);
        streamCell.isLastRow = ([userInfo.streamConfigurations indexOfObject:item] == userInfo.streamConfigurations.count-1);
        streamCell.userInfo = userInfo;
        streamCell.streamConfiguration = item;
        
        return streamCell;
    }
    
    return nil;
}

-(CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return ([item isKindOfClass:[NCActiveUserInfo class]])?100:60;
}

#pragma mark - NCRosterUserCellDelegate, NCRosterStreamCellDelegate
-(void)rosterStreamCell:(NCRosterStreamCell *)cell didSelectToFetchStream:(NSDictionary *)streamConfiguration
{
    [[NCStreamingController sharedInstance] fetchStreams:@[streamConfiguration]
                                                fromUser:cell.userInfo.username
                                              withPrefix:cell.userInfo.hubPrefix];
    
    // update UI for corresponding parent cell
    id item = [self.outlineView parentForItem:cell.streamConfiguration];
    NSInteger rowIdx = [self.outlineView rowForItem:item];
    
    if (rowIdx >= 0)
        [self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:rowIdx] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

-(void)rosterStreamCell:(NCRosterStreamCell *)cell didSelectToStopStream:(NSDictionary *)streamConfiguration
{
    [[NCStreamingController sharedInstance] stopFetchingStreams:@[streamConfiguration]
                                                       fromUser:cell.userInfo.username
                                                     withPrefix:cell.userInfo.hubPrefix];
    
    // update UI for corresponding parent cell
    id item = [self.outlineView parentForItem:cell.streamConfiguration];
    NSInteger rowIdx = [self.outlineView rowForItem:item];
    
    if (rowIdx >= 0)
        [self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:rowIdx] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

-(void)rosterUserCell:(NCRosterUserCell *)cell didSelectToFetchStreams:(NSArray *)streamConfigurations
{
    [[NCStreamingController sharedInstance] fetchStreams:streamConfigurations
                                                fromUser:cell.userInfo.username
                                              withPrefix:cell.userInfo.hubPrefix];
    
    // update UI for corresponding stream cells
    [self.outlineView reloadItem:cell.userInfo reloadChildren:YES];
}

-(void)rosterUserCell:(NCRosterUserCell *)cell didSelectToStopStreams:(NSArray *)streamsToStop
{
    [[NCStreamingController sharedInstance] stopFetchingStreams:streamsToStop
                                                       fromUser:cell.userInfo.username
                                                     withPrefix:cell.userInfo.hubPrefix];
    [self.outlineView reloadItem:cell.userInfo reloadChildren:YES];
}

@end

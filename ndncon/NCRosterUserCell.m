//
//  NCRosterUserCell.m
//  NdnCon
//
//  Created by Peter Gusev on 7/1/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import "NCRosterUserCell.h"
#import "NCStreamViewController.h"
#import "NCThreadViewController.h"
#import "NCVideoThreadViewController.h"
#import "NCStreamingController.h"
#import "NSDictionary+NCAdditions.h"
#import "NSArray+NCAdditions.h"
#import "NSObject+NCAdditions.h"

//******************************************************************************
@interface NCRosterUserCell ()

@property (assign) IBOutlet NSTextField *prefix;
@property (nonatomic) BOOL isHighlighted;
@property (nonatomic, readonly) BOOL canFetch;

@end

@implementation NCRosterUserCell

-(void)awakeFromNib
{
    [self.prefix.cell setLineBreakMode:NSLineBreakByTruncatingTail];
    [self subscribeForNotificationsAndSelectors:
        kNCFetchedUserRemovedNotification, @selector(onFetchedUserRemoved:),
     nil];
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    return self;
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
}

-(void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    NSRect bounds = self.bounds;
    
    if (self.isHighlighted)
    {
        [NSGraphicsContext saveGraphicsState];
        
        NSShadow *shadow = [[NSShadow alloc] init];
        
        [shadow setShadowBlurRadius:2.];
        [shadow setShadowColor:[NSColor grayColor]];
        [shadow set];
        
        if (!self.isExpanded){
            [shadow setShadowOffset:NSMakeSize(0, 1)];
            [[NSColor colorWithWhite:0.5 alpha:1.] set];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(bounds.size.width/2-7, 5.)
                                      toPoint:NSMakePoint(bounds.size.width/2, 2.)];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(bounds.size.width/2, 2.)
                                      toPoint:NSMakePoint(bounds.size.width/2+7, 5.)];
        }
        else
        {
            [shadow setShadowOffset:NSMakeSize(0, -1)];
            [[NSColor colorWithWhite:0.5 alpha:1.] set];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(bounds.size.width/2-7, 2.0)
                                      toPoint:NSMakePoint(bounds.size.width/2, 5.0)];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(bounds.size.width/2, 5.0)
                                      toPoint:NSMakePoint(bounds.size.width/2+7, 2.0)];
        }
        
        [NSGraphicsContext restoreGraphicsState];
    }
    
    if (!self.isExpanded)
    {
        [[NSColor colorWithWhite:0.8 alpha:1.] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0.0, 0.0)
                                  toPoint:NSMakePoint(bounds.size.width, 0.0)];
    }
}

-(void)setUserInfo:(NCActiveUserInfo *)userInfo
{
    _userInfo = userInfo;
    
    [self.textField setStringValue:userInfo.username];
    [self.prefix setStringValue:userInfo.sessionPrefix];
    
    [self updateUi];
}

-(void)setIsAudioSelected:(BOOL)isAudioSelected
{
    [self willChangeValueForKey:@"isAudioSelected"];
    [self willChangeValueForKey:@"canFetch"];
    _isAudioSelected = isAudioSelected;
    [self didChangeValueForKey:@"canFetch"];
    [self didChangeValueForKey:@"isAudioSelected"];
}

-(void)setIsVideoSelected:(BOOL)isVideoSelected
{
    [self willChangeValueForKey:@"isVideoSelected"];
    [self willChangeValueForKey:@"canFetch"];
    _isVideoSelected = isVideoSelected;
    [self didChangeValueForKey:@"canFetch"];
    [self didChangeValueForKey:@"isVideoSelected"];
}

-(BOOL)canFetch
{
    return self.isAudioSelected || self.isVideoSelected;
}

-(void)updateUi
{
    NSArray *currentlyFetchedStreams = [[NCStreamingController sharedInstance] getCurrentStreamsForUser:self.userInfo.username
                                                                                             withPrefix:self.userInfo.hubPrefix];
    
    if (currentlyFetchedStreams.count)
    {
        self.isFetching = YES;
        
        NSSet *fetchedStreamNames = [NSSet setWithArray:[currentlyFetchedStreams valueForKey:kNameKey]];
        NSSet *audioStreamNames = [NSSet setWithArray:[self.userInfo.sessionInfo.audioStreamsConfigurations valueForKey:kNameKey]];
        NSSet *videoStreamNames = [NSSet setWithArray:[self.userInfo.sessionInfo.videoStreamsConfigurations valueForKey:kNameKey]];
        
        self.isAudioSelected = ([audioStreamNames intersectsSet:fetchedStreamNames]);
        self.isVideoSelected = ([videoStreamNames intersectsSet:fetchedStreamNames]);
    }
    else
    {
        self.isFetching = NO;
        
        NSDictionary *userFetchOptions = [[NCPreferencesController sharedInstance]
                                          getFetchOptionsForUser:self.userInfo.username
                                          withPrefix:self.userInfo.sessionPrefix];
        self.isAudioSelected = [userFetchOptions[kUserFetchOptionFetchAudioKey] boolValue];
        self.isVideoSelected = [userFetchOptions[kUserFetchOptionFetchVideoKey] boolValue];
    }
}

#pragma mark - actions
-(IBAction)onAudioSelected:(id)sender
{
    // save user choice
    [[NCPreferencesController sharedInstance] addFetchOptions:@{kUserFetchOptionFetchAudioKey:@([sender state] == NSOnState)}
                                                      forUser:self.userInfo.username
                                                   withPrefix:self.userInfo.sessionPrefix];
    
    if (self.isFetching)
    {
        if (self.isAudioSelected)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(rosterUserCell:didSelectToFetchStreams:)])
            {
                [self.delegate rosterUserCell:self
                      didSelectToFetchStreams:[self.userInfo getDefaultFetchAudioThreads]];
            }
        }
        else
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(rosterUserCell:didSelectToStopStreams:)])
                [self.delegate rosterUserCell:self
                       didSelectToStopStreams:self.userInfo.sessionInfo.audioStreamsConfigurations];
            
            if (!(_isAudioSelected || _isVideoSelected))
                self.isFetching = NO;
        }
    }
}

-(IBAction)onVideoSelected:(id)sender
{
    // save user choice
    [[NCPreferencesController sharedInstance] addFetchOptions:@{kUserFetchOptionFetchVideoKey:@([sender state] == NSOnState)}
                                                      forUser:self.userInfo.username
                                                   withPrefix:self.userInfo.sessionPrefix];
    
    if (self.isFetching)
    {
        if (self.isVideoSelected)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(rosterUserCell:didSelectToFetchStreams:)])
            {
                [self.delegate rosterUserCell:self
                      didSelectToFetchStreams:[self.userInfo getDefaultFetchVideoThreads]];
            }
        }
        else
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(rosterUserCell:didSelectToStopStreams:)])
                [self.delegate rosterUserCell:self didSelectToStopStreams:self.userInfo.sessionInfo.videoStreamsConfigurations];
            
            if (!(_isAudioSelected || _isVideoSelected))
                self.isFetching = NO;
        }
    }
}

-(IBAction)onFetchClicked:(id)sender
{
    NSMutableArray *streamConfigurations = [NSMutableArray array];
    
    if (self.isFetching)
    {   
        if (self.isAudioSelected)
        {
            [streamConfigurations addObjectsFromArray:[self.userInfo getDefaultFetchAudioThreads]];
        }
        
        if (self.isVideoSelected)
        {
            [streamConfigurations addObjectsFromArray:[self.userInfo getDefaultFetchVideoThreads]];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(rosterUserCell:didSelectToFetchStreams:)])
            [self.delegate rosterUserCell:self didSelectToFetchStreams:streamConfigurations];
    }
    else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(rosterUserCell:didSelectToStopStreams:)])
            [self.delegate rosterUserCell:self didSelectToStopStreams:self.userInfo.streamConfigurations];
    }
    
    if (!(self.isAudioSelected || self.isVideoSelected))
        self.isFetching = NO;
}

#pragma mark - notifications
-(void)onFetchedUserRemoved:(NSNotification*)notification
{
    NCFetchedUser *fetchedUser = notification.object;
    
    if ([self.userInfo.username isEqualToString:fetchedUser.username] &&
        [self.userInfo.hubPrefix isEqualToString:fetchedUser.hubPrefix])
    {
        if (self.isFetching)
            self.isFetching = NO;
    }
}

@end

//******************************************************************************
@interface NCRosterStreamCell ()

@property (assign) IBOutlet NSTextField *streamHint;
@property (assign) IBOutlet NSButton *threadSelectButton;

@end

@implementation NCRosterStreamCell

-(void)awakeFromNib
{
    [self.streamHint.cell setLineBreakMode:NSLineBreakByTruncatingTail];
    [self subscribeForNotificationsAndSelectors:
     kNCFetchedStreamsAddedNotification, @selector(onFetchedStreamsAdded:),
     kNCFetchedStreamsRemovedNotification, @selector(onFetchedStreamsRemoved:),
     kNCFetchedUserRemovedNotification, @selector(onFetchedUserRemoved:),
     nil];
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    NSRect bounds = [self bounds];
    [[NSColor colorWithWhite:0.98 alpha:1.] set];
    NSRectFill(bounds);
    
    if (self.isFirstRow || self.isLastRow)
    {
        NSShadow *shadow = [[NSShadow alloc] init];
        
        [shadow setShadowBlurRadius:5.];
        [shadow setShadowOffset:NSMakeSize(0, 0)];
        [shadow setShadowColor:[NSColor blackColor]];
        [shadow set];
        
        if (self.isFirstRow)
            [NSBezierPath strokeLineFromPoint:NSMakePoint(0.0, bounds.size.height)
                                      toPoint:NSMakePoint(bounds.size.width, bounds.size.height)];
        if (self.isLastRow)
            [NSBezierPath strokeLineFromPoint:NSMakePoint(0.0, 0.0)
                                      toPoint:NSMakePoint(bounds.size.width, 0.0)];
    }
}

-(void)setStreamConfiguration:(NSDictionary *)streamConfiguration
{
    _streamConfiguration = streamConfiguration;
    
    [self.textField setStringValue:streamConfiguration[kNameKey]];
    [self.streamHint setStringValue:[self getStreamHint]];
    
    if ([self isAudioStream])
        self.imageView.image = [NSImage imageNamed:@"stream_audio"];
    else
        self.imageView.image = [NSImage imageNamed:@"stream_video"];
    
    self.threadSelectButton.hidden = [self.streamConfiguration[kThreadsArrayKey] count] <= 1;
    [self updateUi];
}

-(BOOL)isAudioStream
{
    return [self.userInfo.sessionInfo.audioStreamsConfigurations indexOfObject: self.streamConfiguration] != NSNotFound;
}

-(void)updateUi
{
    NSArray *currentlyFetchedStreams = [[NCStreamingController sharedInstance] getCurrentStreamsForUser:self.userInfo.username
                                                                                             withPrefix:self.userInfo.hubPrefix];
    
    if (currentlyFetchedStreams.count)
    {
        NSSet *fetchedStreamNames = [NSSet setWithArray:[currentlyFetchedStreams valueForKey:kNameKey]];
        NSSet *streamName = [NSSet setWithObject:self.streamConfiguration[kNameKey]];
        
        self.isFetching = [fetchedStreamNames intersectsSet:streamName];
        
        [self updateHint];
    }
    else
        self.isFetching = NO;
}

-(void)updateHint
{
    if (self.isFetching)
    {
        NSArray *currentlyFetchedStreams = [[NCStreamingController sharedInstance] getCurrentStreamsForUser:self.userInfo.username
                                                                                                 withPrefix:self.userInfo.hubPrefix];
        
        NSDictionary *stream = [currentlyFetchedStreams streamWithName:self.streamConfiguration[kNameKey]];
        
        [self.streamHint setStringValue:[stream[kThreadsArrayKey][0] mediaThreadFullHint]];
    }
    else
        [self.streamHint setStringValue:[self getStreamHint]];
}

-(NSString*)getStreamHint
{
    NSString *hint = @"";
    NSArray *threads = self.streamConfiguration[kThreadsArrayKey];
    
    if ([self isAudioStream])
    {
        if (threads.count > 1)
        {
        }
        else
        {
            hint = [[threads firstObject] mediaThreadShortHint];
        }
    }
    else
    {
        for (NSDictionary *threadConfiguration in threads)
        {
            hint = [NSString stringWithFormat:@"%@%@",
                    hint,
                    [threadConfiguration mediaThreadShortHint]];
            
            if ([threads indexOfObject:threadConfiguration] != threads.count-1)
                hint = [NSString stringWithFormat:@"%@, ", hint];
        }
    }
    
    return hint;
}

#pragma mark - actions

-(IBAction)onFetchClicked:(id)sender
{
    NSMutableDictionary *streamToFetch = [@{} mutableCopy];
    
    if (self.isFetching)
    {
        NSString *defaultThreadsKey = ([self isAudioStream])?kUserFetchOptionDefaultAudioThreadsKey:kUserFetchOptionDefaultVideoThreadsKey;
        NSDictionary *userFetchOptions = [[NCPreferencesController sharedInstance] getFetchOptionsForUser:self.userInfo.username withPrefix:self.userInfo.sessionPrefix];
        NSArray *defaultThreads = userFetchOptions[defaultThreadsKey];
        __block NSInteger threadIdxToFetch = 0;
        
        if (defaultThreads.count)
        {
            for (NSString *threadId in defaultThreads)
            {
                NSString *streamName = [threadId componentsSeparatedByString:@":"][0];
                NSString *threadName = [threadId componentsSeparatedByString:@":"][1];
                
                if ([streamName isEqualToString:self.streamConfiguration[kNameKey]])
                {
                    [self.streamConfiguration[kThreadsArrayKey] enumerateObjectsUsingBlock:^(NSDictionary *threadDict, NSUInteger idx, BOOL *stop) {
                        if ([threadDict[kNameKey] isEqualToString:threadName])
                        {
                            threadIdxToFetch = idx;
                            *stop = YES;
                        }
                    }];
                    break;
                }
            }
        }
        
        streamToFetch = [self.streamConfiguration mutableCopy];
        streamToFetch[kThreadsArrayKey] = @[self.streamConfiguration[kThreadsArrayKey][threadIdxToFetch]];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(rosterStreamCell:didSelectToFetchStream:)])
            [self.delegate rosterStreamCell:self didSelectToFetchStream:streamToFetch];
    }
    else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(rosterStreamCell:didSelectToStopStream:)])
            [self.delegate rosterStreamCell:self didSelectToStopStream:self.streamConfiguration];
    }
    
    [self updateHint];
}

-(IBAction)threadSelected:(id)sender
{
    NSInteger selectedIdx = ([(NSPopUpButton*)sender indexOfSelectedItem]-1);
    
    if (selectedIdx >= 0 && selectedIdx < [self.streamConfiguration[kThreadsArrayKey] count])
    {
        NSMutableDictionary *streamToFetch = [self.streamConfiguration mutableCopy];
        [streamToFetch removeObjectForKey:kThreadsArrayKey];
        
        NSDictionary *threadConfiguration = self.streamConfiguration[kThreadsArrayKey][selectedIdx];
        streamToFetch[kThreadsArrayKey] = @[threadConfiguration];
        
        self.isFetching = YES;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(rosterStreamCell:didSelectToFetchStream:)])
            [self.delegate rosterStreamCell:self didSelectToFetchStream:streamToFetch];
        
        [self.streamHint setStringValue:[streamToFetch[kThreadsArrayKey][0] mediaThreadFullHint]];
        
        // save choice
        NSString *defaultsThreadKey = ([self isAudioStream]?kUserFetchOptionDefaultAudioThreadsKey:kUserFetchOptionDefaultVideoThreadsKey);
        NSDictionary *userFetchOptions = [[NCPreferencesController sharedInstance] getFetchOptionsForUser:self.userInfo.username withPrefix:self.userInfo.sessionPrefix];
        NSArray *defaultThreads = userFetchOptions[defaultsThreadKey];
        
        // add selected thread as to default choice array
        NSMutableArray *newDefaultThreads = [NSMutableArray array];
        [defaultThreads enumerateObjectsUsingBlock:^(NSString *threadId, NSUInteger idx, BOOL *stop) {
            NSString *streamName = [threadId componentsSeparatedByString:@":"][0];
            if (![streamName isEqualToString:streamToFetch[kNameKey]])
                [newDefaultThreads addObject:threadId];
        }];
        
        NSString *threadId = [NSString stringWithFormat:@"%@:%@", self.streamConfiguration[kNameKey], threadConfiguration[kNameKey]];

        [newDefaultThreads addObject:threadId];
        [[NCPreferencesController sharedInstance] addFetchOptions:@{defaultsThreadKey:newDefaultThreads}
                                                          forUser:self.userInfo.username
                                                       withPrefix:self.userInfo.sessionPrefix];
    }
    
    [self updateHint];
}

#pragma mark - notifications
-(void)onFetchedUserRemoved:(NSNotification*)notification
{
    NCFetchedUser *fetchedUser = notification.object;
    
    if ([self.userInfo.username isEqualToString:fetchedUser.username] &&
        [self.userInfo.hubPrefix isEqualToString:fetchedUser.hubPrefix])
    {
        self.isFetching = NO;
    }
}

-(void)onFetchedStreamsRemoved:(NSNotification*)notification
{
    NCFetchedUser *fetchedUser = notification.object;
    
    if ([self.userInfo.username isEqualToString:fetchedUser.username] &&
        [self.userInfo.hubPrefix isEqualToString:fetchedUser.hubPrefix])
    {
        NSArray *streamConfigurations = notification.userInfo[kNCStreamConfigurationsKey];
        if ([streamConfigurations streamWithName:self.streamConfiguration[kNameKey]])
            self.isFetching = NO;
    }
}

-(void)onFetchedStreamsAdded:(NSNotification*)notification
{
    NCFetchedUser *fetchedUser = notification.object;
    
    if ([self.userInfo.username isEqualToString:fetchedUser.username] &&
        [self.userInfo.hubPrefix isEqualToString:fetchedUser.hubPrefix])
    {
        NSArray *streamConfigurations = notification.userInfo[kNCStreamConfigurationsKey];
        if ([streamConfigurations streamWithName:self.streamConfiguration[kNameKey]])
            self.isFetching = YES;
    }
}

@end

//******************************************************************************
@interface NCOutlineView()

@property (nonatomic, weak) NCRosterUserCell *highlightedCell;
@property (nonatomic, strong) NSMutableSet *expandedItems;

@end

@implementation NCOutlineView

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self)
    {
        _expandedItems = [[NSMutableSet alloc] init];
    }
    
    return self;
}

-(void)mouseDown:(NSEvent *)theEvent
{
    NSPoint pointInWindow = [theEvent locationInWindow];
    NSPoint pointInOutlineView = [self convertPoint:pointInWindow toView:nil];
    
    NSInteger rowIndex = [self rowAtPoint:pointInOutlineView];
    
    if ([theEvent clickCount] == 1 && rowIndex == -1)
        [self deselectAll:nil];
    
    else
    {
        NSTableRowView *rowView = [self rowViewAtRow:rowIndex makeIfNecessary:NO];
        
        if (rowView)
        {
            NSTableCellView *cellView = [rowView viewAtColumn:0];
            id item = [self itemAtRow:rowIndex];
            
            if ([self isExpandable:item])
            {
                if ([self isItemExpanded:item])
                {
                    [[self animator] collapseItem:item];
                    [self.expandedItems removeObject:item];
                }
                else
                {
                    [[self animator] expandItem:item];
                    [self.expandedItems addObject:item];
                }
                
                ((NCRosterUserCell*)cellView).isExpanded = [self isItemExpanded:item];
            }
        }
        else
            [super mouseDown:theEvent];
    }
    
    [super mouseDown:theEvent];
}

-(void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint pointInWindow = [theEvent locationInWindow];
    NSPoint pointInOutlineView = [self convertPoint:pointInWindow toView:nil];
    NSInteger rowIndex = [self rowAtPoint:pointInOutlineView];
    BOOL clear = NO;
    
    if (rowIndex >= 0)
    {
        NSTableRowView *rowView = [self rowViewAtRow:rowIndex makeIfNecessary:NO];
        NSTableCellView *cellView = [rowView viewAtColumn:0];
        
        if ([cellView isKindOfClass:[NCRosterUserCell class]])
        {
            if (self.highlightedCell != cellView)
            {
                [self.highlightedCell setIsHighlighted:NO];
                [self.highlightedCell setNeedsDisplay:YES];
                [(NCRosterUserCell*)cellView setIsHighlighted:YES];
                self.highlightedCell = (NCRosterUserCell*)cellView;
                [self.highlightedCell setNeedsDisplay:YES];
            }
        }
        else
            clear = YES;
    }
    else
        clear = YES;
    
    if (clear && self.highlightedCell)
    {
        [self.highlightedCell setIsHighlighted:NO];
        [self.highlightedCell setNeedsDisplay:YES];
        self.highlightedCell = nil;
    }
}

-(void)reloadData
{
    [super reloadData];
    
    for (id item in self.expandedItems)
    {
        [self expandItem:item];
    }
}

-(NSRect)frameOfOutlineCellAtRow:(NSInteger)row
{
    return NSZeroRect;
}

@end

//******************************************************************************
@interface NCToggleButton ()

@end

@implementation NCToggleButton

-(id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self)
    {
        [self setButtonType:NSToggleButton];
    }
    
    return self;
}

-(void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = self.bounds;
    
    [super drawRect:dirtyRect];
    
    if (self.state == NSOnState)
    {
        NSShadow *shadow = [[NSShadow alloc] init];
        
        [shadow setShadowBlurRadius:5.];
        [shadow setShadowOffset:NSMakeSize(0, 0)];
        [shadow setShadowColor:self.highlightColor];
        [shadow set];
        
        [self.highlightColor set];
        [NSBezierPath strokeRect:bounds];
    }
}

@end

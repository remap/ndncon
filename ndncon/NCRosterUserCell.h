//
//  NCRosterUserCell.h
//  NdnCon
//
//  Created by Peter Gusev on 7/1/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCDiscoveryLibraryController.h"

//******************************************************************************
@protocol NCRosterUserCellDelegate;

@interface NCRosterUserCell : NSTableCellView

@property (nonatomic, weak) id<NCRosterUserCellDelegate> delegate;

@property (weak, nonatomic) NCActiveUserInfo *userInfo;
@property (nonatomic) BOOL isExpanded;
@property (nonatomic) BOOL isFetching;
@property (nonatomic) BOOL isAudioSelected;
@property (nonatomic) BOOL isVideoSelected;

@end

@protocol NCRosterUserCellDelegate <NSObject>

@optional
-(void)rosterUserCell:(NCRosterUserCell*)cell didSelectToFetchStreams:(NSArray*)streamConfigurations;
-(void)rosterUserCellDidSelectToStopAllAudioStreams:(NCRosterUserCell *)cell;
-(void)rosterUserCellDidSelectToStopAllVideoStreams:(NCRosterUserCell *)cell;
-(void)rosterUserCell:(NCRosterUserCell *)cell didSelectToStopStreams:(NSArray*)streamsToStop;

@end

//******************************************************************************
@protocol NCRosterStreamCellDelegate;

@interface NCRosterStreamCell : NSTableCellView

@property (nonatomic, weak) id<NCRosterStreamCellDelegate> delegate;

@property (nonatomic) BOOL isFirstRow;
@property (nonatomic) BOOL isLastRow;
@property (nonatomic) BOOL isFetching;

@property (weak, nonatomic) NCActiveUserInfo *userInfo;
@property (weak, nonatomic) NSDictionary *streamConfiguration;

-(BOOL)isAudioStream;

@end

@protocol NCRosterStreamCellDelegate <NSObject>

@optional
-(void)rosterStreamCell:(NCRosterStreamCell*)cell didSelectToFetchStream:(NSDictionary*)streamConfiguration;
-(void)rosterStreamCell:(NCRosterStreamCell *)cell didSelectToStopStream:(NSDictionary *)streamConfiguration;

@end

//******************************************************************************
@interface NCOutlineView : NSOutlineView

@end

//******************************************************************************
@interface NCToggleButton : NSButton

@property (nonatomic) NSColor *highlightColor;

@end
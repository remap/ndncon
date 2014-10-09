//
//  NCStatisticsWindowController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/8/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NCStatisticsWindowControllerDelegate;

@interface NCStatisticsWindowController : NSWindowController
<NSWindowDelegate>

@property (nonatomic) id<NCStatisticsWindowControllerDelegate> delegate;

-(void)stopStatUpdate;

@end

@protocol NCStatisticsWindowControllerDelegate <NSObject>

@required
-(NSArray*)statisticsWindowControllerNeedParticipantsArray:(NCStatisticsWindowController*)wc;
-(void)statisticsWindowControllerWindowWillClose:(NCStatisticsWindowController*)wc;

@end
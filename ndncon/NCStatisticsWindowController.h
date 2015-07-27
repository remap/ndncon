//
//  NCStatisticsWindowController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/8/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NCStatisticsWindowControllerDelegate;

@interface NCStatisticsWindowController : NSViewController

@property (nonatomic) id<NCStatisticsWindowControllerDelegate> delegate;
@property (nonatomic) NSString *selectedStream;

-(void)startStatUpdateForStream:(NSString*)streamName
                           user:(NSString*)username
                     withPrefix:(NSString*)hubPrefix;
-(void)stopStatUpdate;

@end

@protocol NCStatisticsWindowControllerDelegate <NSObject>

@required
-(NSArray*)statisticsWindowControllerNeedParticipantsArray:(NCStatisticsWindowController*)wc;
-(void)statisticsWindowControllerWindowWillClose:(NCStatisticsWindowController*)wc;

@end
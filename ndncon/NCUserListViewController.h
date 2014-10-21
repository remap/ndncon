//
//  NCUserListViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCNdnRtcLibraryController.h"

extern NSString* const kNCSessionInfoKey;
extern NSString* const kNCHubPrefixKey;

//******************************************************************************
@interface NCSessionInfoContainer : NSObject
<NSTableViewDelegate, NSTableViewDataSource>

+(NCSessionInfoContainer*)containerWithSessionInfo:(void*)sessionInfo;

-(id)initWithSessionInfo:(void*)sessionInfo;
-(void*)sessionInfo;

-(NSArray*)audioStreamsConfigurations;
-(NSArray*)videoStreamsConfigurations;

@end

//******************************************************************************
@protocol NCUserListViewControllerDelegate;

@interface NCUserListViewController : NSObject

@property (nonatomic, weak) IBOutlet id<NCUserListViewControllerDelegate> delegate;

+(NCSessionStatus)sessionStatusForUser:(NSString*)user
                withPrefix:(NSString*)prefix;

-(void)clearSelection;
-(NSDictionary*)userInfoDictionaryForUser:(NSString*)userName
                               withPrefix:(NSString*)prefix;

@end

//******************************************************************************
@protocol NCUserListViewControllerDelegate <NSObject>

@optional
-(void)userListViewController:(NCUserListViewController*)userListViewController
                userWasChosen:(NSDictionary*)user;
-(void)userListViewControllerUserListUpdated:(NCUserListViewController*)userListViewController;

@end

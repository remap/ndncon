//
//  NCConferenceListViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Conference.h"

@protocol NCPopoverControllerDelegate;
@protocol NCConferenceListViewControllerDelegate;

//******************************************************************************
@interface NCConferenceListViewController : NSViewController
<NSTableViewDelegate, NSTableViewDataSource, NCPopoverControllerDelegate>

@property (nonatomic, weak) IBOutlet id<NCConferenceListViewControllerDelegate> delegate;

-(void)clearSelection;

@end

//******************************************************************************
@protocol NCConferenceListViewControllerDelegate <NSObject>

@optional
-(void)conferenceListController:(NCConferenceListViewController*)conferenceListController
               didAddConference:(Conference*)conference;
-(void)conferenceListController:(NCConferenceListViewController*)conferenceListController
            didSelectConference:(Conference*)conference;

@end
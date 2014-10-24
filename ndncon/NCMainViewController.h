//
//  NCMainViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCUserListViewController.h"
#import "NCConversationViewController.h"
#import "NCConversationInfoView.h"
#import "NCUserViewController.h"
#import "NCConferenceListViewController.h"

@interface NCMainViewController : NSViewController
<NCConversationViewControllerDelegate,
NCClickableViewDelegate,
NCUserListViewControllerDelegate,
NCUserViewControllerDelegate,
NCDragAndDropViewDelegate,
NCConferenceListViewControllerDelegate>

@property (nonatomic, weak) IBOutlet NCUserListViewController *userListViewController;
@property (nonatomic, strong) IBOutlet NSView *initialView;
@property (nonatomic, weak) IBOutlet NSView *currentView;
@property (nonatomic, readonly) NCConversationViewController *conversationViewController;

@end

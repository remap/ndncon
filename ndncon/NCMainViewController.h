//
//  NCMainViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCUserListViewController.h"

@interface NCMainViewController : NSViewController

@property (nonatomic, weak) IBOutlet NCUserListViewController *userListViewController;
@property (nonatomic, weak) IBOutlet NSView *initialView;
@property (nonatomic, weak) IBOutlet NSView *currentView;

@end

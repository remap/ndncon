//
//  NCConversationViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCStreamBrowserController.h"

@protocol NCConversationViewControllerDelegate;

@interface NCConversationViewController : NSViewController
<NCStreamBrowserControllerDelegate>

-(void)startPublishingWithConfiguration:(NSDictionary*)streamsConfiguration;

@end

@protocol NCConversationViewControllerDelegate <NSObject>

@optional
-(void)conversationViewControllerNeedsStreamConfiguration:(NCConversationViewController*)converstaionVc;

@end
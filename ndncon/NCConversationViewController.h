//
//  NCConversationViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCStackEditorViewController.h"

@protocol NCConversationViewControllerDelegate;

@interface NCConversationViewController : NSViewController
<NCStackEditorEntryDelegate>

-(void)startPublishingWithConfiguration:(NSDictionary*)streamsConfiguration;

@end

@protocol NCConversationViewControllerDelegate <NSObject>

@optional
-(void)conversationViewControllerNeedsStreamConfiguration:(NCConversationViewController*)converstaionVc;

@end
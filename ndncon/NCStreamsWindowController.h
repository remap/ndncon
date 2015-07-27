//
//  NCStreamsWindowController.h
//  NdnCon
//
//  Created by Peter Gusev on 7/9/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NCStreamBrowserController.h"
#import "NCUserStreamsController.h"
#import "NCActiveStreamViewer.h"
#import "NCChatViewController.h"

@interface NCStreamsWindowController : NSWindowController
<NCUserStreamsControllerDelegate, NCActiveStreamViewerDelegate,
NSSplitViewDelegate, NCChatViewControllerDelegate>

@end

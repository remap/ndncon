//
//  NCStreamsWindowController.h
//  NdnCon
//
//  Created by Peter Gusev on 7/9/15.
//  Copyright 2013-2015 Regents of the University of California
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

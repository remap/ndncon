//
//  NCRosterWindowController.h
//  NdnCon
//
//  Created by Peter Gusev on 4/27/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCPreferencesController.h"

@interface NCRosterWindowController : NSWindowController
<NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, readonly) NCPreferencesController *preferences;

@end

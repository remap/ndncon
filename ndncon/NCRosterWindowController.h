//
//  NCRosterWindowController.h
//  NdnCon
//
//  Created by Peter Gusev on 4/27/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCPreferencesController.h"
#import "NCRosterUserCell.h"

@interface NCRosterWindowController : NSWindowController
<NSOutlineViewDelegate, NSOutlineViewDataSource,
NCRosterUserCellDelegate, NCRosterStreamCellDelegate>

@property (nonatomic, readonly) NCPreferencesController *preferences;

@end

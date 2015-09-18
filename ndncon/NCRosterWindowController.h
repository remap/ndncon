//
//  NCRosterWindowController.h
//  NdnCon
//
//  Created by Peter Gusev on 4/27/15.
//  Copyright 2013-2015 Regents of the University of California
//

#import <Cocoa/Cocoa.h>
#import "NCPreferencesController.h"
#import "NCRosterUserCell.h"

@interface NCRosterWindowController : NSWindowController
<NSOutlineViewDelegate, NSOutlineViewDataSource,
NCRosterUserCellDelegate, NCRosterStreamCellDelegate>

@property (nonatomic, readonly) NCPreferencesController *preferences;

@end

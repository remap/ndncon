//
//  NCRosterWindowController.m
//  NdnCon
//
//  Created by Peter Gusev on 4/27/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import "NCRosterWindowController.h"

@interface NCRosterWindowController()

@property (weak) IBOutlet NSView *localContrainerView;
@property (weak) IBOutlet NSTableView *tableView;

@end

@implementation NCRosterWindowController

-(NCPreferencesController *)preferences
{
    return [NCPreferencesController sharedInstance];
}

@end

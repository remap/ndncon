//
//  NCAdvancedPreferencesViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "MASPreferencesViewController.h"
#import "NCPreferencesController.h"

@interface NCAdvancedPreferencesViewController : NSViewController
<MASPreferencesViewController, NSTableViewDelegate>

@property (nonatomic, readonly) NSArray *advancedSettings;
@property (nonatomic, readonly) NCPreferencesController *preferences;

@end

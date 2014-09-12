//
//  NCAdvancedPreferencesViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "MASPreferencesViewController.h"
#import "NCPreferencesController.h"

@interface NCAdvancedPreferencesViewController : NSViewController
<MASPreferencesViewController, NSTableViewDelegate>

@property (nonatomic, readonly) NSArray *advancedSettings;
@property (nonatomic, readonly) NCPreferencesController *preferences;

@end

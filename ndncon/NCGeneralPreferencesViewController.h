//
//  NCGeneralPreferencesViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "MASPreferencesViewController.h"
#import "NCPreferencesController.h"

@interface NCGeneralPreferencesViewController : NSViewController<MASPreferencesViewController>

@property (nonatomic, strong) NCPreferencesController *preferences;
@property (nonatomic, readonly) NSString *connectionStatus;

@end

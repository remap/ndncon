//
//  NCGeneralPreferencesViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "MASPreferencesViewController.h"
#import "NCPreferencesController.h"

@interface NCGeneralPreferencesViewController : NSViewController<MASPreferencesViewController>

@property (nonatomic, strong) NCPreferencesController *preferences;
@property (nonatomic, readonly) NSString *connectionStatus;

@end

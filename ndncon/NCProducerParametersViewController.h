//
//  NCProducerParametersViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Cocoa/Cocoa.h>
#import "NCPreferencesController.h"

@interface NCProducerParametersViewController : NSViewController

-(id)initWithPreferences:(NCPreferencesController*)preferences;

@property (nonatomic, strong) NCPreferencesController *preferences;

@end

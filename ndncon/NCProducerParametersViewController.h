//
//  NCProducerParametersViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCPreferencesController.h"

@interface NCProducerParametersViewController : NSViewController

-(id)initWithPreferences:(NCPreferencesController*)preferences;

@property (nonatomic, strong) NCPreferencesController *preferences;

@end

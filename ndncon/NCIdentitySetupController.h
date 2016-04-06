//
//  NCIdentitySetupController.h
//  NdnCon
//
//  Created by Peter Gusev on 3/15/16.
//  Copyright © 2016 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NCIdentitySetupDelegate;

@interface NCIdentitySetupController : NSWindowController

@property (nonatomic, weak) IBOutlet id<NCIdentitySetupDelegate> delegate;

-(void)setupInstanceIdentity;

@end

@protocol NCIdentitySetupDelegate<NSObject>

-(void)identitySetupCompletedWithIdentity:(NSString*)identity;
-(void)identitySetupCompletedWithInstanceIdentity:(NSString*)instanceIdentity;

@end
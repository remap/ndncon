//
//  NCThreadViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCStreamViewController.h"
#import "NCConfigurationObserver.h"

#define KEYPATH(s1, s2) ([NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(s1)), NSStringFromSelector(s2)])

#define KEYPATH2(s1, k2) ([NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(s1)), k2])
#define KEYPATH3(s1, k2, k3) ([NSString stringWithFormat:@"%@.%@.%@", NSStringFromSelector(@selector(s1)), k2, k3])

NSString* const kBitrateKey;

@interface NCThreadViewController : NSViewController

@property (nonatomic, weak) id<NCConfigurationObserverDelegate> delegate;

+(NSDictionary*)defaultConfiguration;

@property (nonatomic) NSString *threadName;
@property (nonatomic, weak) NCStreamViewController *stream;
@property (nonatomic, readonly) NSMutableDictionary *configuration;

-(id)initWithStream:(NCStreamViewController*)streamVc
            andName:(NSString*)threadName;

-(void)startObservingSelf;
-(void)stopObservingSelf;

@end

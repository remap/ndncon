//
//  NCConfigurationObserver.h
//  NdnCon
//
//  Created by Peter Gusev on 9/16/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NCConfigurationObserverDelegate <NSObject>

@optional
-(void)configurationDidChangeForObject:(id)object
                             atKeyPath:(NSString*)keyPath
                                change:(NSDictionary*)change;

@end

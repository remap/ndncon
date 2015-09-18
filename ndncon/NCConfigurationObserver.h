//
//  NCConfigurationObserver.h
//  NdnCon
//
//  Created by Peter Gusev on 9/16/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Foundation/Foundation.h>

@protocol NCConfigurationObserverDelegate <NSObject>

@optional
-(void)configurationDidChangeForObject:(id)object
                             atKeyPath:(NSString*)keyPath
                                change:(NSDictionary*)change;

@end

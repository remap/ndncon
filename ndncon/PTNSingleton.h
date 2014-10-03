//
//  PTNSingleton.h
//  PTNAdditions
//
//  Created by Peter Gusev on 3/28/14.
//  Copyright (c) 2014 peetonn inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Base class for singletons. 
 * Derived class should override createInstance method and (optionally) 
 * sharedInstance. Base class will ensure creation of just one copy of the 
 * derived class.
 * Example:
 *      ...
 *      @interface MySingleton : PTNSingleton
 *      +(MySingleton*)sharedInstance;
 *      @end
 *
 *      @implementation MySingleton
 *      +(MySingleton*)sharedInstance
 *      {
 *          return (MySingleton*)[super sharedInstance];
 *      }
 *
 *      +(PTNSingleton*)createInstance
 *      {
 *          return [[MySingleton alloc] init];
 *      }
 *      @end
 *      ...
 * Usage:
 *      ...
 *      [MySingleton sharedInstance];
 *      ...
 */
@interface PTNSingleton : NSObject

+(PTNSingleton*)sharedInstance;
+(PTNSingleton*)createInstance;

@end

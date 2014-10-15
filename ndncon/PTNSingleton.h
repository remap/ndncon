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
 * Derived class should override createInstance method, token method and
 * (optionally) sharedInstance method. Base class will ensure creation of just
 * one copy of the derived class.
 * Base class maintains static token for one singleton, therefore if you're
 * using several singletons derived from this class, you should ensure that
 * you provide different tokens for each of them (by overriding token method).
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
 *
 *      +(dispatch_once_t)token
 *      {
 *          static dispatch_once_t token;
 *          return token;
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

+(dispatch_once_t)token;

@end

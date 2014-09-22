//
//  NSArray+NCAdditions.h
//  NdnCon
//
//  Created by Peter Gusev on 9/15/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (NCAdditions)

-(NSMutableArray*)deepMutableCopy;
-(id)objectAtIndexOrNil:(NSUInteger)index;
/**
 * If the index >= 0 works as objectAtIndexOrNil
 * Otherwise - executes [self objectAtIndexOrNil: self.count+index] allowing to 
 * retrieve elements from the end of the array
 */
-(id)objectAtSignedIndexOrNil:(NSInteger)index;
@end

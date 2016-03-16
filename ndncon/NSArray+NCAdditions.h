//
//  NSArray+NCAdditions.h
//  NdnCon
//
//  Created by Peter Gusev on 9/15/14.
//  Copyright 2013-2015 Regents of the University of California.
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

-(NSArray *)arrayByRemovingObject:(id)object;

// media streams additions
-(NSDictionary*)streamWithName:(NSString*)streamName;
-(NSDictionary*)threadWithName:(NSString*)threadName;

@end

@interface NSMutableArray (NCCircularArray)

@property (nonatomic) unsigned int circularBufferSize;
@property (nonatomic) unsigned int currentIndex;

-(instancetype)initCircularArrayWithSize:(unsigned int)size;

-(void)push:(id)object;
-(float)average;

@end

//
//  NSScrollView+NCAdditions.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSScrollView (NCAdditions)

-(void)addStackView:(NSStackView*)stackView withOrientation:(NSUserInterfaceLayoutOrientation)orientation;

@end

//
//  NSScrollView+NCAdditions.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NSScrollView+NCAdditions.h"

@implementation NSScrollView (NCAdditions)

-(void)addStackView:(NSStackView *)stackView withOrientation:(NSUserInterfaceLayoutOrientation)orientation
{
    stackView.orientation = orientation;
    [stackView setClippingResistancePriority:NSLayoutPriorityDefaultLow
                              forOrientation:(orientation == NSUserInterfaceLayoutOrientationHorizontal)?NSLayoutConstraintOrientationHorizontal:NSLayoutConstraintOrientationVertical];
    

    [self setDocumentView:stackView];
    
    NSString *constraingFormat = (orientation == NSUserInterfaceLayoutOrientationHorizontal)?@"H:|[stackView]":@"H:|[stackView]|";
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: constraingFormat
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(stackView)]];
    
    
    constraingFormat = (orientation == NSUserInterfaceLayoutOrientationHorizontal)?@"V:|[stackView]|":@"V:|[stackView]";
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:constraingFormat
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(stackView)]];
}

@end

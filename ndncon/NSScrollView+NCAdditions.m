//
//  NSScrollView+NCAdditions.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NSScrollView+NCAdditions.h"

//******************************************************************************
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

//******************************************************************************
CGFloat centeredCoordinateUnitWithProposedContentViewBoundsDimensionAndDocumentViewFrameDimension
(CGFloat proposedContentViewBoundsDimension, CGFloat documentViewFrameDimension )
{
    CGFloat result = floor( (proposedContentViewBoundsDimension - documentViewFrameDimension) / -2.0F );
    return result;
}

@implementation NCClipView

- (NSRect)constrainBoundsRect:(NSRect)proposedClipViewBoundsRect {
    
    NSRect constrainedClipViewBoundsRect = [super constrainBoundsRect:proposedClipViewBoundsRect];
    
    // Early out if you want to use the default NSClipView behavior.
    if (self.centersDocumentView == NO) {
        return constrainedClipViewBoundsRect;
    }
    
    NSRect documentViewFrameRect = [self.documentView frame];
    
    // If proposed clip view bounds width is greater than document view frame width, center it horizontally.
    if (proposedClipViewBoundsRect.size.width >= documentViewFrameRect.size.width) {
        // Adjust the proposed origin.x
        constrainedClipViewBoundsRect.origin.x = centeredCoordinateUnitWithProposedContentViewBoundsDimensionAndDocumentViewFrameDimension(proposedClipViewBoundsRect.size.width, documentViewFrameRect.size.width);
    }
    
    // If proposed clip view bounds is hight is greater than document view frame height, center it vertically.
    if (proposedClipViewBoundsRect.size.height >= documentViewFrameRect.size.height) {
        
        // Adjust the proposed origin.y
        constrainedClipViewBoundsRect.origin.y = centeredCoordinateUnitWithProposedContentViewBoundsDimensionAndDocumentViewFrameDimension(proposedClipViewBoundsRect.size.height, documentViewFrameRect.size.height);
    }
    
    return constrainedClipViewBoundsRect;
}


@end
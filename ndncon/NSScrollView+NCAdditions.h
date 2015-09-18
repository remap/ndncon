//
//  NSScrollView+NCAdditions.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Cocoa/Cocoa.h>

//******************************************************************************
@interface NSScrollView (NCAdditions)

-(void)addStackView:(NSStackView*)stackView withOrientation:(NSUserInterfaceLayoutOrientation)orientation;

@end

//******************************************************************************
@interface NCClipView : NSClipView

@property (nonatomic) BOOL centersDocumentView;

@end

//
//  NCEmbeddedScrollView.h
//  NdnCon
//
//  Created by Peter Gusev on 9/16/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Cocoa/Cocoa.h>

@interface NCEmbeddedScrollView : NSScrollView

@property (nonatomic) NSNumber* ignoreHorizontalScroll;
@property (nonatomic) NSNumber* ignoreVerticalScroll;

@end

//
//  NCEmbeddedScrollView.h
//  NdnCon
//
//  Created by Peter Gusev on 9/16/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NCEmbeddedScrollView : NSScrollView

@property (nonatomic) NSNumber* ignoreHorizontalScroll;
@property (nonatomic) NSNumber* ignoreVerticalScroll;

@end

//
//  NCDropScrollview.h
//  NdnCon
//
//  Created by Peter Gusev on 10/21/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Cocoa/Cocoa.h>
#import "NSView+NCAdditions.h"

/**
 * This scroll view supports NdnCon drag&drop operations
 */
@interface NCDropScrollView : NSScrollView

@property (nonatomic, weak) IBOutlet id<NCDragAndDropViewDelegate> delegate;

@end

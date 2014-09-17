//
//  NCStreamsViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCStackEditorEntryViewController.h"

@interface NCStackEditorViewController : NSViewController<NSStackViewDelegate, NCStackEditorEntryDelegate>

@property (nonatomic, weak) id<NCStackEditorEntryDelegate> delegate;
@property (nonatomic, readonly) NSStackView *stackView;

-(NCStackEditorEntryViewController*)addViewEntry:(NSView*)view;
-(NCStackEditorEntryViewController*)addViewEntry:(NSView*)view withStyle:(NCStackEditorEntryStyle)style;

@end

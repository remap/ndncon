//
//  NCStreamsViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCStackEditorEntryViewController.h"

typedef BOOL(^NCStackEditorFilterBlock)(NCStackEditorEntryViewController *vc);

@interface NCStackEditorViewController : NSViewController<NSStackViewDelegate, NCStackEditorEntryDelegate>

@property (nonatomic, weak) id<NCStackEditorEntryDelegate> delegate;
@property (nonatomic, readonly) NSStackView *stackView;
@property (nonatomic) NSColor *backgroundColor;

-(void)initialize;
-(NCStackEditorEntryViewController *)addViewControllerEntry:(NSViewController*)viewController;
-(NCStackEditorEntryViewController *)addViewControllerEntry:(NSViewController*)viewController withStyle:(NCStackEditorEntryStyle)style;
-(void)removeAllEntries;
-(void)removeEntriesSatisfyingRule:(NCStackEditorFilterBlock)filterBlock;

-(void)highlightEntryWithcontroller:(NSViewController*)viewController;
-(void)removeEntryHighlight;

@end

@interface NCStackView : NSStackView

@end
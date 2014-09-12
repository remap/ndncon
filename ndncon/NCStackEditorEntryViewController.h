//
//  NCStackEditorViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NCStackEditorEntryDelegate;

@interface NCStackEditorEntryViewController : NSViewController

@property (nonatomic, weak) id<NCStackEditorEntryDelegate> delegate;
@property (nonatomic) NSString *caption;
@property (weak) IBOutlet NSView *contentView;

@end

@protocol NCStackEditorEntryDelegate <NSObject>

@optional
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController*)vc;
-(void)stackEditorEntryViewControllerUpdatedFrame:(NCStackEditorEntryViewController*)vc;

@end
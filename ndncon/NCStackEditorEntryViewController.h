//
//  NCStackEditorViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NCStackEditorEntryDelegate;

typedef enum : NSUInteger {
    StackEditorEntryStyleClassic,
    StackEditorEntryStyleModern
} NCStackEditorEntryStyle;

@interface NCStackEditorEntryViewController : NSViewController

@property (nonatomic, weak) id<NCStackEditorEntryDelegate> delegate;
@property (nonatomic) NSString *caption;
//@property (weak) IBOutlet NSView *contentView;
@property (weak) IBOutlet NSViewController *contentViewController;
@property (weak, readonly) IBOutlet NSTextField *captionLabel;
@property (nonatomic, readonly) NCStackEditorEntryStyle style;

-(id)initWithStyle:(NCStackEditorEntryStyle)style;
-(void)setHeaderSmall:(BOOL)isHeaderSmall;

@end

@protocol NCStackEditorEntryDelegate <NSObject>

@optional
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController*)vc;
-(void)stackEditorEntryViewControllerUpdatedFrame:(NCStackEditorEntryViewController*)vc;

@end

//
//  NCStreamPreviewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Cocoa/Cocoa.h>
#import "NCClickableView.h"

@protocol NCStreamPreviewControllerDelegate;

@interface NCStreamPreviewController : NSViewController
<NCClickableViewDelegate>

@property (nonatomic, weak) id<NCStreamPreviewControllerDelegate> delegate;
@property (nonatomic) NSString *streamName;
@property (nonatomic, weak) IBOutlet NSView *streamPreview;
@property (nonatomic, strong) id userData;
@property (nonatomic) BOOL isSelected;

-(void)initialize;

@end

@protocol NCStreamPreviewControllerDelegate <NSObject>

@optional
-(void)streamPreviewControllerWasClosed:(NCStreamPreviewController*)streamPreviewController;
-(void)streamPreviewControllerWasSelected:(NCStreamPreviewController*)streamPreviewController;

@end

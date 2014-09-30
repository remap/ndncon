//
//  NCStreamPreviewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
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
-(void)streamPreviewControllerWasSelected:(NCStreamPreviewController*)streamPreviewController;

@end

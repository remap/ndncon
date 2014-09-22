//
//  NCStreamViewerController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCStackEditorViewController.h"
#import "NCStreamPreviewController.h"

extern NSString* const kLocalUserNameKey;

@protocol NCStreamBrowserControllerDelegate;

@interface NCStreamBrowserController : NCStackEditorViewController
<NCStackEditorEntryDelegate>

@property (nonatomic, weak) id<NCStreamBrowserControllerDelegate> delegate;

-(NCStreamPreviewController*)addStreamWithConfiguration:(NSDictionary*)configuration
                                  andStreamPreviewClass:(Class)streamPreviewClass;

@end

@protocol NCStreamBrowserControllerDelegate <NSObject>

@optional
-(void)streamBrowserController:(NCStreamBrowserController*)browserController
               streamWasClosed:(NCStreamPreviewController*)previewController
                       forUser:(NSString*)userName;

@end

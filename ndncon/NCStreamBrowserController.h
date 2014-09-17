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

@protocol NCStreamBrowserControllerDelegate;

@interface NCStreamBrowserController : NCStackEditorViewController

-(void)addStreamWithConfiguration:(NSDictionary*)configuration
            andStreamPreviewClass:(Class)streamPreviewClass;

-(void)addStreamsFromArray:(NSArray*)streamArray
                   forUser:(NSString*)username;

@end

@protocol NCStreamBrowserControllerDelegate <NSObject>

@optional
-(void)streamBrowserController:(NCStreamBrowserController*)browserController
               streamWasClosed:(NCStreamPreviewController*)previewController
                       forUser:(NSString*)userName;

@end

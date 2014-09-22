//
//  NCStreamPreviewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NCStreamPreviewController : NSViewController

@property (nonatomic) NSString *streamName;
@property (nonatomic, weak) IBOutlet NSTextField *streamCaptionLabel;
@property (nonatomic, weak) IBOutlet NSView *streamPreview;
@property (nonatomic, strong) id userData;

-(void)initialize;

@end

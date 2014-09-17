//
//  NCStreamViewerController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamBrowserController.h"
#import "NCStreamViewController.h"

const NSString *kNoUserNameKey = @"noname";

@interface NCStreamBrowserController ()

@property (nonatomic) NSMutableDictionary *userPreviewControllers;

@end

@implementation NCStreamBrowserController

-(void)addStreamWithConfiguration:(NSDictionary *)configuration andStreamPreviewClass:(Class)streamPreviewClass
{
    NCStreamPreviewController *streamPreviewController = [[streamPreviewClass alloc] init];
    streamPreviewController.streamName = [configuration valueForKeyPath:kNameKey];
    
    NCStackEditorEntryViewController *vc = [self addViewEntry:streamPreviewController.view withStyle:StackEditorEntryStyleModern];
    [vc setHeaderSmall:YES];
    vc.caption = [configuration valueForKey:kNameKey];
    
    [self.userPreviewControllers setObject:streamPreviewController
                                    forKey:kNoUserNameKey];
}

@end

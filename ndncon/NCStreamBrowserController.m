//
//  NCStreamViewerController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamBrowserController.h"
#import "NCStreamViewController.h"

NSString* const kLocalUserNameKey = @"local";

@interface NCStreamBrowserController ()

@property (nonatomic) NSMutableDictionary *userPreviewControllers;

@end

@implementation NCStreamBrowserController

-(void)initialize
{
    [super initialize];
    self.userPreviewControllers = [[NSMutableDictionary alloc] init];
}

-(NCStreamPreviewController*)addStreamWithConfiguration:(NSDictionary *)configuration andStreamPreviewClass:(Class)streamPreviewClass
{
    NCStreamPreviewController *streamPreviewController = [[streamPreviewClass alloc] init];
    streamPreviewController.streamName = [configuration valueForKeyPath:kNameKey];
    
    NCStackEditorEntryViewController *vc = [self addViewEntry:streamPreviewController.view withStyle:StackEditorEntryStyleModern];
    [vc setHeaderSmall:YES];
    vc.caption = [configuration valueForKey:kNameKey];
    
    [self.userPreviewControllers setObject:streamPreviewController
                                    forKey:kLocalUserNameKey];
    return streamPreviewController;
}

// NCStackEditorEntryDelegate
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamBrowserController:streamWasClosed:forUser:)])
    {
        NCStreamPreviewController *streamPreviewController = nil;
        NSString *userName = nil;
        
        for (NSString *key in self.userPreviewControllers.allKeys)
            if ([(NSViewController*)[self.userPreviewControllers objectForKey:key] view] == vc.contentView)
            {
                streamPreviewController = [self.userPreviewControllers objectForKey:key];
                userName = key;
                break;
            }
        
        [self.delegate streamBrowserController:self
                               streamWasClosed:streamPreviewController
                                       forUser:userName];
    }
    
    [super stackEditorEntryViewControllerDidClosed:vc];
}

@end

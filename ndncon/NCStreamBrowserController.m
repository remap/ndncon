//
//  NCStreamViewerController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamBrowserController.h"
#import "NCStreamViewController.h"
#import "NSString+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"

NSString* const kLocalUserName = @"local";
NSString* const kUserNameKey = @"user";
NSString* const kStreamPrefixKey = @"streamPrefix";
NSString* const kPreviewControllerKey = @"previewController";

@interface NCStreamBrowserController ()

@property (nonatomic) NSMutableDictionary *userPreviewControllers;

@end

@implementation NCStreamBrowserController

-(void)initialize
{
    [super initialize];
    self.userPreviewControllers = [[NSMutableDictionary alloc] init];
}

-(NCStreamPreviewController*)addStreamWithConfiguration:(NSDictionary *)configuration
                                  andStreamPreviewClass:(Class)streamPreviewClass
                                         forStreamPrefix:(NSString*)streamPrefix
{
    NCStreamPreviewController *streamPreviewController = [[streamPreviewClass alloc] init];
    streamPreviewController.streamName = [configuration valueForKeyPath:kNameKey];
    
    NCStackEditorEntryViewController *vc = [self addViewControllerEntry:streamPreviewController
                                                              withStyle:StackEditorEntryStyleModern];
    [vc setHeaderSmall:YES];

    vc.caption = [NSString stringWithFormat:@"%@: %@",
                  [streamPrefix getNdnRtcUserName],
                  [configuration valueForKey:kNameKey]];
    
    self.userPreviewControllers[streamPrefix] = @{kUserNameKey:kLocalUserName,
                                                  kPreviewControllerKey:streamPreviewController};
    return streamPreviewController;
}

-(void)closeStreamsForController:(NCStreamPreviewController *)streamPreviewController
{
    [self removeEntriesSatisfyingRule:^BOOL(NCStackEditorEntryViewController *vc) {
        return (vc.contentViewController == streamPreviewController);
    }];
    
    [self.userPreviewControllers removeObjectForKey:streamPreviewController.userData[kStreamPrefixKey]];
}

-(void)closeAllStreams
{
    [super removeAllEntries];
    
    [self.userPreviewControllers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NCStreamPreviewController *vc = [obj valueForKeyPath:kPreviewControllerKey];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(streamBrowserController:willCloseStream:forUser:forPrefix:)])
            [self.delegate streamBrowserController:self
                                   willCloseStream:vc
                                           forUser:[obj valueForKeyPath:kUserNameKey]
                                         forPrefix:key];
    }];
}

// NCStackEditorEntryDelegate
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamBrowserController:streamWasClosed:forUser:forPrefix:)])
    {
        NCStreamPreviewController *streamPreviewController = nil;
        NSString *userName = nil;
        NSString *streamPrefix = nil;
        
        for (NSString *key in self.userPreviewControllers.allKeys)
        {
            NSDictionary *info = self.userPreviewControllers[key];
            
            if (info[kPreviewControllerKey] == vc.contentViewController)
            {
                streamPreviewController = [info objectForKey:kPreviewControllerKey];
                userName =  [info objectForKey:kUserNameKey];
                streamPrefix = key;
                break;
            }
        }
        
        [self.userPreviewControllers removeObjectForKey:streamPrefix];
        [self.delegate streamBrowserController:self
                               streamWasClosed:streamPreviewController
                                       forUser:userName
                                     forPrefix:streamPrefix];
    }
    
    [super stackEditorEntryViewControllerDidClosed:vc];
}

@end

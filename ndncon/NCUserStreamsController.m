//
//  NCUserStreamsController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NCUserStreamsController.h"
#import "NCStreamBrowserController.h"
#import "NSScrollView+NCAdditions.h"
#import "NSString+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"

@interface NCUserStreamsController ()

@property (nonatomic) NSMutableDictionary *activeUsers;

@end

@implementation NCUserStreamsController

-(void)initialize
{
    [super initialize];
    _activeUsers = [NSMutableDictionary dictionary];
}

-(void)awakeFromNib
{
}

-(void)viewDidLoad
{
    self.view.wantsLayer = YES;
//    self.view.layer.backgroundColor = [NSColor greenColor].CGColor;
    [self.stackView setSpacing:0.];
}

-(void)dealloc
{
    [self.activeUsers removeAllObjects];
    self.activeUsers = nil;
}

-(NCVideoPreviewController *)addStream:(NSDictionary *)streamConfiguration
                               forUser:(NSString *)username
                            withPrefix:(NSString *)prefix
{
    NCUserPreviewController *userPreviewController = self.activeUsers[[NSString userIdWithName:username andPrefix:prefix]];
    
    if (!userPreviewController)
    {
        userPreviewController = [[NCUserPreviewController alloc] init];

        [userPreviewController view];
        userPreviewController.delegate = self;
        userPreviewController.username = username;
        userPreviewController.prefix = prefix;
        self.activeUsers[[NSString userIdWithName:username andPrefix:prefix]] = userPreviewController;
        [self addUserPreviewEntry:userPreviewController];
    }
    
    NCVideoPreviewController *preview = [userPreviewController addPreviewForStream:streamConfiguration];
    
    [self.stackView updateConstraints];
    [self.stackView layout];
    
    return preview;
}

-(void)removeStream:(NSDictionary *)streamConfiguration
            forUser:(NSString *)username
         withPrefix:(NSString *)prefix
{
    NCUserPreviewController *previewController = self.activeUsers[[NSString userIdWithName:username andPrefix:prefix]];
    
    if (previewController)
    {
        [previewController removePreviewForStream:streamConfiguration];
        
        if ([previewController getAllStreams].count == 0)
        {
            [previewController close];
            [self removeUserPreviewEntry:previewController];
        }
    }
}

-(void)dropUser:(NSString *)username withPrefix:(NSString *)prefix
{
    NCUserPreviewController *previewController = self.activeUsers[[NSString userIdWithName:username andPrefix:prefix]];
    
    if (previewController)
        [previewController close];
}

-(void)addUserPreviewEntry:(NCUserPreviewController*)userPreviewController
{
    [self.stackView addView:userPreviewController.view inGravity:NSStackViewGravityBottom];
    [self.entryControllers addObject:userPreviewController];
}

-(void)removeUserPreviewEntry:(NCUserPreviewController*)userPreviewController
{
    [self.activeUsers removeObjectForKey:[NSString userIdWithName:userPreviewController.username
                                                        andPrefix:userPreviewController.prefix]];
    [self removeEntriesSatisfyingRule:^BOOL(NCStackEditorEntryViewController *vc) {
        return ((NCUserPreviewController*)vc == userPreviewController);
    }];
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

#pragma mark - NCUserPreviewControllerDelegate
-(void)userPreviewController:(NCUserPreviewController *)userPreviewController streamFilterChangedIsAudio:(BOOL)isAudioChanged
{
    if (isAudioChanged)
    {
        if (!userPreviewController.isAudioEnabled)
        {
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(userStreamsController:didDropStreams:forUser:withPrefix:)])
                [self.delegate userStreamsController:self
                                      didDropStreams:[userPreviewController getAudioStreams]
                                             forUser:userPreviewController.username
                                          withPrefix:userPreviewController.prefix];
        }
        else
        {
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(userStreamsController:needMoreStreamsIsAudio:forUser:withPrefix:)])
                [self.delegate userStreamsController:self
                              needMoreStreamsIsAudio:YES
                                             forUser:userPreviewController.username
                                          withPrefix:userPreviewController.prefix];
        }
    }
    else
    {
        if (!userPreviewController.isVideoEnabled)
        {
            if ([self.delegate respondsToSelector:@selector(userStreamsController:didDropStreams:forUser:withPrefix:)])
                [self.delegate userStreamsController:self
                                      didDropStreams:[userPreviewController getVideoStreams]
                                             forUser:userPreviewController.username
                                          withPrefix:userPreviewController.prefix];
        }
        else
        {
            if ([self.delegate respondsToSelector:@selector(userStreamsController:needMoreStreamsIsAudio:forUser:withPrefix:)])
                [self.delegate userStreamsController:self
                              needMoreStreamsIsAudio:NO
                                             forUser:userPreviewController.username
                                          withPrefix:userPreviewController.prefix];
        }
    }
}

-(void)userPreviewControllerWillClose:(NCUserPreviewController*)userPreviewController
                          withStreams:(NSArray*)streamConfigurations
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(userStreamsController:didDropUserWithName:andPrefix:withStreams:)])
    {
        [self.delegate userStreamsController:self
                         didDropUserWithName:userPreviewController.username
                                   andPrefix:userPreviewController.prefix
                                 withStreams:streamConfigurations];
    }
    
    [self removeUserPreviewEntry:userPreviewController];
}

-(void)userPreviewController:(NCUserPreviewController *)userPreviewController
             onStreamDropped:(NSDictionary *)streamConfiguration
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(userStreamsController:didDropStreams:forUser:withPrefix:)])
    {
        [self.delegate userStreamsController:self
                              didDropStreams:@[streamConfiguration]
                                     forUser:userPreviewController.username
                                  withPrefix:userPreviewController.prefix];
    }
}

@end

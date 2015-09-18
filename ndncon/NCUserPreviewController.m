//
//  NCUserPreviewController.m
//  NdnCon
//
//  Created by Peter Gusev on 7/9/15.
//  Copyright 2013-2015 Regents of the University of California
//

#import "NCUserPreviewController.h"
#import "NSDictionary+NCAdditions.h"
#import "NSView+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"
#import "NSObject+NCAdditions.h"

NSString* const kNCStreamPreviewSelectedNotification = @"NCStreamPreviewSelectedNotification";
NSString* const kNCStreamPreviewControllerKey = @"streamController";

@interface NCUserPreviewController ()

@property (weak) IBOutlet NCBlockDrawableView *captionView;
@property (weak) IBOutlet NSStackView *videoStackView;
@property (weak) IBOutlet NSTextField *usernameLabel;
@property (strong) IBOutlet NSTextField *infoLabel;
@property (nonatomic) NSTrackingArea *trackingArea;

@property (nonatomic) NSMutableDictionary *currentPreviewControllers;
@property (nonatomic) NSMutableDictionary *audioStreams;

@end

@implementation NCUserPreviewController

-(instancetype)init
{
    self = [self initWithNibName:@"NCUserPreview" bundle:nil];
    
    if (self)
    {
        _currentPreviewControllers = [NSMutableDictionary dictionary];
        _audioStreams = [NSMutableDictionary dictionary];
    }
    
    return self;
}

-(void)awakeFromNib
{
    
}

-(void)dealloc
{
    [self.currentPreviewControllers removeAllObjects];
    self.currentPreviewControllers = nil;
    self.infoLabel = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    __weak NCUserPreviewController *this = self;
    ((NCTrackableView*)self.view).updateTrackingAreasBlock = ^(NSView *view){
        [this updateTrackingAreas];
    };
    
    self.view.wantsLayer = YES;
//    self.view.layer.backgroundColor = [NSColor greenColor].CGColor;
    self.videoStackView.wantsLayer = YES;
//    self.videoStackView.layer.backgroundColor = [NSColor orangeColor].CGColor;

    self.infoLabel = [[NSTextField alloc] initWithFrame:self.view.bounds];
    self.infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.infoLabel setEditable:NO];
    [self.view addSubview:self.infoLabel
               positioned:NSWindowAbove
               relativeTo:self.videoStackView];
    
    NSTextField *infoLabel = self.infoLabel;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:infoLabel
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:infoLabel.superview
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.
                                                           constant:0.]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:infoLabel
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:infoLabel.superview
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.
                                                           constant:0.]];
    self.infoLabel.hidden = YES;
    [self.infoLabel setStringValue:@"no video"];
    [self.infoLabel setBordered:NO];
    [self.infoLabel setBackgroundColor:[NSColor clearColor]];
    
    [(NCBlockDrawableView*)self.view addDrawBlock:^(NSView *view, NSRect dirtyRect) {
        [[NSColor grayColor] setStroke];
        [NSBezierPath strokeRect:view.bounds];
    }];
    
    self.captionView.alphaValue = 0.;
    [self.captionView addDrawBlock:^(NSView *view, NSRect dirtyRect) {
        [[NSColor colorWithWhite:1. alpha:0.3] set];
        NSRectFill(view.bounds);
    }];
    
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.view.bounds
                                                     options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                       owner:self
                                                    userInfo:nil];
    [self.view addTrackingArea:self.trackingArea];

}

#pragma mark - public
-(NSArray *)getAllStreams
{
    NSMutableArray *streams = [NSMutableArray arrayWithArray:[self getVideoStreams]];
    
    [streams addObjectsFromArray:[self.audioStreams allValues]];
    
    return [streams copy];
}

-(NSArray *)getAudioStreams
{
    return [[self.audioStreams allValues] copy];
}

-(NSArray*)getVideoStreams
{
    NSMutableArray *streams = [NSMutableArray array];
    
    [self.currentPreviewControllers enumerateKeysAndObjectsUsingBlock:^(id key, NCVideoPreviewController *obj, BOOL *stop) {
        [streams addObject:obj.streamConfiguration];
    }];
    
    return [streams copy];
}

-(NCVideoPreviewController *)addPreviewForStream:(NSDictionary *)streamConfiguration
{
    NCVideoPreviewController *videoPreviewController = nil;
    
    if (![streamConfiguration isVideoStream])
    {
        self.isAudioEnabled = YES;
        self.audioStreams[streamConfiguration[kNameKey]] = streamConfiguration;
    }
    else
    {
        self.isVideoEnabled = YES;
        videoPreviewController = [[NCVideoPreviewController alloc] init];
        videoPreviewController.delegate = self;
        [self.videoStackView addView:videoPreviewController.view inGravity:NSStackViewGravityTop];
        videoPreviewController.streamConfiguration = streamConfiguration;
        self.currentPreviewControllers[streamConfiguration[kNameKey]] = videoPreviewController;
    }
    
    self.infoLabel.hidden = (self.currentPreviewControllers.count != 0);
    
    return videoPreviewController;
}

-(void)removePreviewForStream:(NSDictionary *)streamConfiguration
{
    if (![streamConfiguration isVideoStream])
    {
        if (self.audioStreams[streamConfiguration[kNameKey]])
        {
            self.isAudioEnabled = NO;
            [self.audioStreams removeObjectForKey:streamConfiguration[kNameKey]];
        }
    }
    else
    {
        NCVideoPreviewController *previewController = self.currentPreviewControllers[streamConfiguration[kNameKey]];
        if (previewController)
        {
            [previewController close];
            [self.videoStackView removeView:previewController.view];
            [self.currentPreviewControllers removeObjectForKey:streamConfiguration[kNameKey]];
            self.infoLabel.hidden = (self.currentPreviewControllers.count != 0);
            self.isVideoEnabled = (self.currentPreviewControllers.count != 0);
        }
    }
}

-(void)close
{
    [self.currentPreviewControllers enumerateKeysAndObjectsUsingBlock:^(id key, NCVideoPreviewController *vc, BOOL *stop) {
        [vc close];
        [self.videoStackView removeView:vc.view];
    }];
    [self.currentPreviewControllers removeAllObjects];
}

#pragma mark - NCStreamPreviewDelegate
-(void)streamPreviewControllerWasClosed:(NCStreamPreviewController *)streamPreviewController
{
    [self.videoStackView removeView:streamPreviewController.view];
    [self.currentPreviewControllers removeObjectForKey:streamPreviewController.streamName];
    self.isVideoEnabled = (self.currentPreviewControllers.count != 0);
    self.infoLabel.hidden = (self.currentPreviewControllers.count != 0);
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(userPreviewController:onStreamDropped:)])
    {
        [self.delegate userPreviewController:self onStreamDropped:[(NCVideoPreviewController*)streamPreviewController streamConfiguration]];
    }
    
    if ([self getAllStreams].count == 0)
    {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(userPreviewControllerWillClose:withStreams:)])
            [self.delegate userPreviewControllerWillClose:self withStreams:@[]];
    }
}

-(void)streamPreviewControllerWasSelected:(NCStreamPreviewController *)streamPreviewController
{
    if ([streamPreviewController isKindOfClass:[NCVideoPreviewController class]])
        [self notifyNowWithNotificationName:kNCStreamPreviewSelectedNotification andUserInfo:@{kNCStreamPreviewControllerKey: streamPreviewController}];
}

#pragma mark - private
-(void)updateTrackingAreas
{
    [self.view removeTrackingArea:self.trackingArea];
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.view.bounds
                                                     options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                       owner:self
                                                    userInfo:nil];
    [self.view addTrackingArea:self.trackingArea];
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3;
        self.captionView.animator.alphaValue = 1.;
    }
                        completionHandler:^{
                        }];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        if (self.isVideoEnabled)
        {
            context.duration = 0.3;
            self.captionView.animator.alphaValue = 0.;
        }
    }
                        completionHandler:^{
                        }];

}

#pragma mark - properties
-(void)setUsername:(NSString *)username
{
    _username = username;
    [self.usernameLabel setStringValue:self.username];
}

#pragma mark - actions
- (IBAction)onClose:(id)sender
{
    [self.currentPreviewControllers enumerateKeysAndObjectsUsingBlock:^(id key, NCVideoPreviewController *vc, BOOL *stop) {
        [vc close];
        [self.videoStackView removeView:vc.view];
    }];
    
    NSArray *allStreams = [self getAllStreams];
    [self.currentPreviewControllers removeAllObjects];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(userPreviewControllerWillClose:withStreams:)])
        [self.delegate userPreviewControllerWillClose:self
                                          withStreams:allStreams];
}

- (IBAction)onAudioSelected:(id)sender
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(userPreviewController:streamFilterChangedIsAudio:)])
    {
        [self.delegate userPreviewController:self
                  streamFilterChangedIsAudio:YES];
    }
}

- (IBAction)onVideoSelected:(id)sender
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(userPreviewController:streamFilterChangedIsAudio:)])
        [self.delegate userPreviewController:self
                  streamFilterChangedIsAudio:NO];
    
    if (!self.isVideoEnabled &&
        self.captionView.alphaValue == 0)
        self.captionView.alphaValue = 1.;
}

@end

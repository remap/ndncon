//
//  NCConversationViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCConversationViewController.h"
#import "NCStreamBrowserController.h"
#import "NSScrollView+NCAdditions.h"
#import "NCStreamPreviewController.h"
#import "NCPreferencesController.h"
#import "NCStreamViewController.h"
#import "NCAudioPreviewController.h"
#import "NCVideoPreviewController.h"

@interface NCConversationViewController ()

@property (weak) IBOutlet NSScrollView *localStreamsScrollView;
@property (weak) IBOutlet NSScrollView *remoteStreamsScrollView;
@property (weak) IBOutlet NSView *activeStreamContentView;

@property (nonatomic, strong) NCStreamBrowserController *localStreamViewer;
@property (nonatomic, strong) NCStreamBrowserController *remoteStreamViewer;

@end

@implementation NCConversationViewController

-(id)init
{
    self = [self initWithNibName:@"NCConverstaionView" bundle:nil];
    
    if (self)
        [self initialize];
    
    return self;
}

-(void)initialize
{
    self.localStreamViewer = [[NCStreamBrowserController alloc] init];
    self.localStreamViewer.delegate = self;
    
    self.remoteStreamViewer = [[NCStreamBrowserController alloc] init];
    self.remoteStreamViewer.delegate = self;
}

-(void)dealloc
{
    self.localStreamViewer = nil;
    self.remoteStreamViewer = nil;
}

-(void)awakeFromNib
{
    [self.localStreamsScrollView addStackView:self.localStreamViewer.stackView
                              withOrientation:NSUserInterfaceLayoutOrientationHorizontal];
    [self.remoteStreamsScrollView addStackView:self.remoteStreamViewer.stackView
                               withOrientation:NSUserInterfaceLayoutOrientationVertical];
}

- (IBAction)endConversation:(id)sender
{
    NSLog(@"end converstaion");
}

-(void)startPublishingWithConfiguration:(NSDictionary *)streamsConfiguration
{
    for (NSDictionary *audioConfiguration in [streamsConfiguration valueForKey:kAudioStreamsKey])
        [self startAudioStreamWithConfiguration: audioConfiguration];
    
    for (NSDictionary *videoConfiguration in [streamsConfiguration valueForKey:kVideoStreamsKey])
        [self startVideoStreamWithConfiguration: videoConfiguration];
}


// NCStackEditorEntryDelegate
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    
}

// private
-(void)startAudioStreamWithConfiguration:(NSDictionary*)streamConfiguration
{
//    [self startLibraryStreamWithConfiguration: ]
    [self.localStreamViewer addStreamWithConfiguration:streamConfiguration
                                 andStreamPreviewClass:[NCAudioPreviewController class]];
}

-(void)startVideoStreamWithConfiguration:(NSDictionary*)streamConfiguration
{
//    [self startLibraryStreamWithConfiguration: ]
    [self.localStreamViewer addStreamWithConfiguration:streamConfiguration
                                 andStreamPreviewClass:[NCVideoPreviewController class]];
}


@end

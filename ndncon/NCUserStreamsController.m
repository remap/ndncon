//
//  NCUserStreamsController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCUserStreamsController.h"
#import "NCStreamBrowserController.h"
#import "NSScrollView+NCAdditions.h"

@interface NCUserStreamsController ()

@property (weak) IBOutlet NSScrollView *audioStreamsScrollView;
@property (weak) IBOutlet NSScrollView *videoStreamsScrollView;

@property (nonatomic, strong) NCStreamBrowserController *audioStreamsBrowser;
@property (nonatomic, strong) NCStreamBrowserController *videoStreamsBrowser;

@end

@implementation NCUserStreamsController

-(id) init
{
    self = [self initWithNibName:@"NCUserStreamsView" bundle:nil];
    
    if (self)
        [self initialize];
    
    return self;
}

-(void)initialize
{
    self.audioStreamsBrowser = [[NCStreamBrowserController alloc] init];
    self.videoStreamsBrowser = [[NCStreamBrowserController alloc] init];
}

-(void)awakeFromNib
{
    [self.audioStreamsScrollView addStackView:self.audioStreamsBrowser.stackView
                              withOrientation:NSUserInterfaceLayoutOrientationVertical];
    [self.videoStreamsScrollView addStackView:self.videoStreamsBrowser.stackView
                              withOrientation:NSUserInterfaceLayoutOrientationVertical];
}

-(void)dealloc
{
    self.audioStreamsBrowser = nil;
    self.videoStreamsBrowser = nil;
}

@end

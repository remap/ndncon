//
//  NCStreamPreviewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamPreviewController.h"

@interface NCStreamPreviewController ()

@property (nonatomic, strong) NSImageView *selectedIconView;

@end

@implementation NCStreamPreviewController

-(id)init
{
    self = [super init];
    
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

- (void)dealloc
{
    self.view = nil;
    self.streamName = nil;
    self.userData = nil;
}

-(void)initialize
{
    self.view = [[NCClickableView alloc] init];
    ((NCClickableView*)self.view).delegate = self;
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor blackColor].CGColor;
    
    [self.view setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.selectedIconView = [[NSImageView alloc] init];
    self.selectedIconView.image = [NSImage imageNamed:@"stream_selected"];
    [self.selectedIconView setTranslatesAutoresizingMaskIntoConstraints:NO];
}

-(void)viewWasClicked:(NCClickableView *)view
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamPreviewControllerWasSelected:)])
        [self.delegate streamPreviewControllerWasSelected:self];
}

-(void)setIsSelected:(BOOL)isSelected
{
    _isSelected = isSelected;
    
    if (_isSelected)
    {
        NSImageView *selectedView = self.selectedIconView;
        [self.view addSubview:self.selectedIconView];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[selectedView]|"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(selectedView)]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[selectedView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:NSDictionaryOfVariableBindings(selectedView)]];
    }
    else
        [self.selectedIconView removeFromSuperview];
}

@end

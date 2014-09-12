//
//  NCStreamsViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStackEditorViewController.h"

@interface NCStackEditorViewController ()

@property (nonatomic, strong) NSMutableArray *entryControllers;

@end

@implementation NCStackEditorViewController

- (id)init
{
    return [self initWithNibName:@"NCStackEditorView" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        self.stackView.wantsLayer = YES;
        self.stackView.layer.backgroundColor = [NSColor scrollBarColor].CGColor;
        self.entryControllers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    self.entryControllers = nil;
}

-(NSStackView *)stackView
{
    return (NSStackView*)self.view;
}

-(void)addViewEntry:(NSView*)view
{
    NCStackEditorEntryViewController *vc =[[NCStackEditorEntryViewController alloc] init];
    vc.delegate = self;
    vc.contentView = view;
    
    [self.entryControllers addObject:vc];
    [self.stackView addView:vc.view inGravity:NSStackViewGravityTop];
}

// NSStackView delegate
-(void)stackView:(NSStackView *)stackView didReattachViews:(NSArray *)views
{
    NSLog(@"reattached views %@", views);
}

-(void)stackView:(NSStackView *)stackView willDetachViews:(NSArray *)views
{
    NSLog(@"will detach views: %@", views);
}

// NCStackEditorEntryDelegate
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    [self.stackView removeView:vc.view];
    [self.entryControllers removeObject:vc];
}

-(void)stackEditorEntryViewControllerUpdatedFrame:(NCStackEditorEntryViewController *)vc
{
    NSLog(@"updated frame");
}

@end

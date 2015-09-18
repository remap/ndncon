//
//  NCStreamsViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NCStackEditorViewController.h"

@interface NCStackEditorViewController ()

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
        [self initialize];
    }
    return self;
}

-(void)initialize
{
    self.stackView.wantsLayer = YES;
    self.entryControllers = [[NSMutableArray alloc] init];
    self.backgroundColor = [NSColor colorWithWhite:0.9 alpha:1.];
}

- (void)dealloc
{
    self.entryControllers = nil;
}

-(NSStackView *)stackView
{
    return (NSStackView*)self.view;
}

-(NCStackEditorEntryViewController*)addViewControllerEntry:(NSViewController*)viewController
{
    NCStackEditorEntryViewController *vc =[[NCStackEditorEntryViewController alloc] init];

    [self newViewEntry:vc forViewController:viewController];
    
    return vc;
}

-(NCStackEditorEntryViewController *)addViewControllerEntry:(NSViewController*)viewController withStyle:(NCStackEditorEntryStyle)style
{
    NCStackEditorEntryViewController *vc = [[NCStackEditorEntryViewController alloc] initWithStyle:style];
    
    [self newViewEntry:vc forViewController:viewController];
    
    return vc;
}

-(void)removeAllEntries
{
    for (NCStackEditorEntryViewController *vc in self.entryControllers)
    {
        [self.stackView removeView:vc.view];
    }
    
    [self.entryControllers removeAllObjects];
}

-(void)removeEntriesSatisfyingRule:(NCStackEditorFilterBlock)filterBlock
{
    NSMutableArray *forRemoval = [NSMutableArray array];
    
    for (NCStackEditorEntryViewController *vc in self.entryControllers)
        if (filterBlock(vc))
        {
            [self.stackView removeView:vc.view];
            [forRemoval addObject:vc];
        }
    
    [self.entryControllers removeObjectsInArray:forRemoval];
}

-(void)highlightEntryWithcontroller:(NSViewController*)viewController
{
    [self.entryControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([(NCStackEditorEntryViewController*)obj contentViewController] == viewController)
        {
            [(NCStackEditorEntryViewController*)obj setIsHighlighted:YES];
            *stop = YES;
        }
    }];
}

-(void)removeEntryHighlight
{
    [self.entryControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(NCStackEditorEntryViewController*)obj setIsHighlighted:NO];
    }];
}

-(void)setBackgroundColor:(NSColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    
    if (self.entryControllers)
        for (NCStackEditorEntryViewController *entry in self.entryControllers)
            entry.view.superview.layer.backgroundColor = _backgroundColor.CGColor;
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(stackEditorEntryViewControllerDidClosed:)])
        [self.delegate stackEditorEntryViewControllerDidClosed:vc];
}

-(void)stackEditorEntryViewControllerUpdatedFrame:(NCStackEditorEntryViewController *)vc
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stackEditorEntryViewControllerUpdatedFrame:)])
        [self.delegate stackEditorEntryViewControllerUpdatedFrame:vc];
}

// private
-(void)newViewEntry:(NCStackEditorEntryViewController*)entry forViewController:(NSViewController*)viewController
{
    entry.delegate = self;
    entry.contentViewController = viewController;
    
    [self.entryControllers addObject:entry];
    [self.stackView addView:entry.view inGravity:NSStackViewGravityTop];
    
    [entry.view.superview setWantsLayer:YES];
    entry.view.superview.layer.backgroundColor = self.backgroundColor.CGColor;
}

@end

@implementation NCStackView

-(BOOL)isFlipped
{
    return YES;
}

@end


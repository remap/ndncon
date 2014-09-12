//
//  NCStackEditorViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStackEditorEntryViewController.h"

@interface NCStackEditorEntryViewController ()
{
    NSView *_contentView;
}

@property (weak) IBOutlet NSTextField *captionLabel;
@property (weak) IBOutlet NSView *headerView;

@end

@implementation NCStackEditorEntryViewController

- (id)init
{
    return [self initWithNibName:@"NCStackEditorEntryView" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

-(void)awakeFromNib
{
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor yellowColor].CGColor;
}

-(void)setCaption:(NSString *)caption
{
    self.captionLabel.value = caption;
}

-(NSString *)caption
{
    return self.captionLabel.value;
}

-(NSView *)contentView
{
    return _contentView;
}
-(void)setContentView:(NSView *)view
{
    if (view != _contentView)
    {
        [self.contentView removeFromSuperview];
        _contentView = view;
        [self.view addSubview:self.contentView];
        
        // we want a white background to distinguish between the
        // header portion of this view controller containing the hide/show button
        //
        self.contentView.wantsLayer = YES;
        self.contentView.layer.backgroundColor = [[NSColor whiteColor] CGColor];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_contentView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:NSDictionaryOfVariableBindings(_contentView)]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_headerView][_contentView]"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:NSDictionaryOfVariableBindings(_headerView, _contentView)]];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_contentView]-(0@600)-|"
                                                                          options:0 metrics:nil
                                                                            views:NSDictionaryOfVariableBindings(_contentView)]];
    }
//    if ([self.contentView.subviews containsObject:view])
//        return;
//    
//    for (NSView *subview in self.contentView.subviews)
//        [subview removeFromSuperview];
//    
//    CGRect contentViewFrame = self.contentView.frame;
//    
//    if (CGRectGetWidth(contentViewFrame) != CGRectGetWidth(view.frame) ||
//        CGRectGetHeight(contentViewFrame) != CGRectGetHeight(view.frame))
//    {
//        contentViewFrame.size.width = view.frame.size.width;
//        contentViewFrame.size.height = view.frame.size.height;
//        
//        CGRect mainViewFrame = self.view.frame;
//        mainViewFrame.size.width = contentViewFrame.size.width;
//        mainViewFrame.size.height += CGRectGetHeight(contentViewFrame)-CGRectGetHeight(self.contentView.frame) ;
//        
//        self.contentView.frame = contentViewFrame;
//        self.view.frame = mainViewFrame;
//        
//        if (self.delegate && [self.delegate respondsToSelector:@selector(stackEditorEntryViewControllerUpdatedFrame:)])
//            [self.delegate stackEditorEntryViewControllerUpdatedFrame:self];
//    }
//    
//    [self.contentView addSubview:view];
}

- (IBAction)closeView:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stackEditorEntryViewControllerDidClosed:)])
        [self.delegate stackEditorEntryViewControllerDidClosed:self];
}

@end

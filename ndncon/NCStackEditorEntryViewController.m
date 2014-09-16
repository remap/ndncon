//
//  NCStackEditorViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStackEditorEntryViewController.h"
#import "NCEditorEntryView.h"

@interface NCStackEditorEntryViewController ()
{
    NSView *_contentView;
}

@property (weak) IBOutlet NSTextField *captionLabel;
@property (weak) IBOutlet NSView *headerView;
@property (weak) IBOutlet NSLayoutConstraint *headerHeightConstraint;
@property (weak) IBOutlet NSLayoutConstraint *captionBottomSpaceConstraint;

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

}

-(void)setCaption:(NSString *)caption
{
    [self.captionLabel setStringValue: caption];
}

-(NSString *)caption
{
    return self.captionLabel.stringValue;
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
                
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_contentView]-20-|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:NSDictionaryOfVariableBindings(_contentView)]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_headerView]-(0@750)-[_contentView]"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:NSDictionaryOfVariableBindings(_headerView, _contentView)]];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_contentView]-(20@600)-|"
                                                                          options:0 metrics:nil
                                                                            views:NSDictionaryOfVariableBindings(_contentView)]];
    }
}

- (IBAction)closeView:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stackEditorEntryViewControllerDidClosed:)])
        [self.delegate stackEditorEntryViewControllerDidClosed:self];
}

-(void)setHeaderSmall:(BOOL)isHeaderSmall
{
    CGFloat headerHeight = (isHeaderSmall) ? 33 : 39;
    self.headerHeightConstraint.constant = headerHeight;
    self.captionBottomSpaceConstraint.constant = (isHeaderSmall)?6:8;
    
    NSFont *captionFont = (isHeaderSmall)?[NSFont fontWithName:@"System Regular" size:11.] : [NSFont fontWithName:@"System Bold Regular" size:13.];
    
    [self.captionLabel setFont:captionFont];
    [(NCEditorEntryView*)self.view setHeaderHeight:headerHeight];
    self.view.needsDisplay = YES;
}

@end

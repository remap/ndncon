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
    NCStackEditorEntryStyle _style;
    NSViewController *_contentViewController;
}

@property (weak) IBOutlet NSTextField *captionLabel;
@property (weak) IBOutlet NCBlockDrawableView *headerView;
@property (weak) IBOutlet NSLayoutConstraint *headerHeightConstraint;
@property (weak) IBOutlet NSLayoutConstraint *captionBottomSpaceConstraint;
@property (weak) IBOutlet NSLayoutConstraint *captionLeadingSpaceConstraint;
@property (weak) IBOutlet NSLayoutConstraint *buttonTrailingSpaceConstraint;

@end

@implementation NCStackEditorEntryViewController

- (id)init
{
    return [self initWithNibName:@"NCStackEditorEntryView" bundle:nil];
}

-(id)initWithStyle:(NCStackEditorEntryStyle)style
{
    self = [self init];
    
    if (self)
    {
        _style = style;
    }
    
    return self;
}

-(void)awakeFromNib
{
    [self view];
    
    if (self.style == StackEditorEntryStyleClassic)
    {
        [(NCEditorEntryView*)self.view setHeaderStyle: EditorEntryViewHeaderStyleGloss];
        [(NCEditorEntryView*)self.view setRoundCorners:YES];
        [self.captionLabel setTextColor:[NSColor blackColor]];
    }
    else
    {
        [(NCEditorEntryView*)self.view setHeaderStyle: EditorEntryViewHeaderStyleNone];
        [(NCEditorEntryView*)self.view setRoundCorners:NO];
        [self.captionLabel setTextColor:[NSColor whiteColor]];
        
        CGFloat inset = [(NCEditorEntryView*)self.view shadowInset];
        [self.headerView addDrawBlock:^(NSView *view, NSRect dirtyRect) {
            NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
                                    [NSColor colorWithWhite:0. alpha:0.], 0.,
                                    [NSColor colorWithWhite:0. alpha:1.], 1.,
                                    nil];
            CGRect rect = CGRectMake(inset-1, 0,
                                     view.bounds.size.width-2*inset+2,
                                     view.bounds.size.height-inset);
            [gradient drawInRect:rect
                           angle:90.];
        }];
        
        self.captionLeadingSpaceConstraint.constant = 10.;
        self.buttonTrailingSpaceConstraint.constant = 10.;
    }
    
    [self.contentViewController awakeFromNib];
}

-(void)setCaption:(NSString *)caption
{
    [self.captionLabel setStringValue: caption];
}

-(NSString *)caption
{
    return self.captionLabel.stringValue;
}

-(NSViewController *)contentViewController
{
    return _contentViewController;
}
-(void)setContentViewController:(NSViewController *)contentViewController
{
    if (contentViewController != _contentViewController)
    {
        [self.contentViewController.view removeFromSuperview];
        _contentViewController = contentViewController;
        [self.view addSubview:self.contentViewController.view positioned:NSWindowBelow relativeTo:self.headerView];

        if (self.style == StackEditorEntryStyleClassic)
            [self applyClassicStyleConstraints];
        else
            if (self.style == StackEditorEntryStyleModern)
                [self applyModernStyleConstraints];
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

// private
-(void)applyClassicStyleConstraints
{
    NSView *contentView = self.contentViewController.view;
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[contentView]-20-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(contentView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_headerView]-(0@750)-[contentView]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(_headerView, contentView)]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[contentView]-(20@600)-|"
                                                                      options:0 metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(contentView)]];
}

-(void)applyModernStyleConstraints
{
    NSView *contentView = self.contentViewController.view;
    
    CGFloat inset = [(NCEditorEntryView*)self.view shadowInset];
    NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%f-[contentView]-%f-|", inset, inset];
    NSString *verticalConstraint = [NSString stringWithFormat:@"V:|-%f-[contentView]-%f-|", inset, inset];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horizontalConstraint
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(contentView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalConstraint
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(_headerView, contentView)]];
}

@end

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
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_headerView][_contentView]"
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

@end

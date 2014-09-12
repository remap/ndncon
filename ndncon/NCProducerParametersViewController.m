//
//  NCProducerParametersViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCProducerParametersViewController.h"
#import "NCStackEditorViewController.h"
#import "NCVideoStreamViewController.h"

@interface NCProducerParametersViewController ()

@property (strong) NCStackEditorViewController *stackEditorController;
@property (weak) IBOutlet NSScrollView *scrollView;

@property (strong) NSMutableArray *streamControllers;
@end

@implementation NCProducerParametersViewController

- (id)init
{
    return [self initWithNibName:@"NCProducerParametersView" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.stackEditorController = [[NCStackEditorViewController alloc] init];
    }
    return self;
}

-(void)awakeFromNib
{
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor redColor].CGColor;
    
    [self.scrollView setDocumentView:self.stackEditorController.view];

    NSStackView *stackEditorView = self.stackEditorController.stackView;
    
    [stackEditorView setClippingResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationVertical];
    
    [self.scrollView.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[stackEditorView]|"
                                                                                          options:0
                                                                                          metrics:nil
                                                                                             views:NSDictionaryOfVariableBindings(stackEditorView)]];


    [self.scrollView.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[stackEditorView]"
                                                                                            options:0
                                                                                            metrics:nil
                                                                                              views:NSDictionaryOfVariableBindings(stackEditorView)]];
}

- (IBAction)addStream:(id)sender
{
    NCVideoStreamViewController *videoStreamViewController = [[NCVideoStreamViewController alloc] init];
    
//    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
//    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[view(598)]"
//                                                                options:0
//                                                                metrics:nil
//                                                                  views:NSDictionaryOfVariableBindings(view)]];
//    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(200)]"
//                                                                options:0
//                                                                metrics:nil
//                                                                  views:NSDictionaryOfVariableBindings(view)]];
    
//    NSTextField *tf = [[NSTextField alloc] initWithFrame:CGRectMake(250, 90, 100, 20)];
//    [tf setStringValue: @"HELLO!"];
//    [view addSubview:tf];
    
    [self.stackEditorController addViewEntry:videoStreamViewController.view];
}

@end

@interface NCEditorClipView : NSClipView

@end

@implementation NCEditorClipView

-(BOOL)isFlipped
{
    return YES;
}

@end

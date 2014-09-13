//
//  NCProducerParametersViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCProducerParametersViewController.h"
#import "NCStreamEditorViewController.h"
#import "NCVideoStreamViewController.h"

@interface NCProducerParametersViewController ()

@property (strong) NCStreamEditorViewController *streamEditorController;
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
        self.streamEditorController = [[NCStreamEditorViewController alloc] init];
    }
    return self;
}

-(void)dealloc
{
    self.preferences = nil;
}

-(void)awakeFromNib
{
    [self.scrollView setDocumentView:self.streamEditorController.view];

    NSStackView *stackEditorView = self.streamEditorController.stackView;
    
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
    [self.streamEditorController addVideoStream:[NCVideoStreamViewController defaultVideoStreamConfiguration]];
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

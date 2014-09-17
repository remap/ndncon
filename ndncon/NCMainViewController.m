//
//  NCMainViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCMainViewController.h"
#import "NCConversationViewController.h"
#import "NCPreferencesController.h"

@interface NCMainViewController ()

@property (nonatomic, strong) NSDictionary *conversationConfiguration;
@property (nonatomic, strong) NCConversationViewController *converstaionViewController;


@end

@implementation NCMainViewController

-(id)init
{
    self = [super init];
    
    if (self)
        [self initialize];
    
    return self;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
        [self initialize];
    
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
        [self initialize];
    
    return self;
}

-(void)initialize
{
    
}

-(void)dealloc
{
    
}

-(void)awakeFromNib
{
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    self.view.layer.borderColor = [NSColor darkGrayColor].CGColor;
    self.view.layer.borderWidth = 1.f;
}

- (IBAction)startPublishing:(id)sender {
    self.conversationConfiguration = [NCPreferencesController sharedInstance].producerConfigurationCopy;
    self.converstaionViewController = [[NCConversationViewController alloc] init];
    
    [self loadCurrentView:self.converstaionViewController.view];
    [self.converstaionViewController startPublishingWithConfiguration:self.conversationConfiguration];
}

- (IBAction)startPublishingCustom:(id)sender {
    NSLog(@"customize...");
}

// private
-(void)loadCurrentView:(NSView *)currentView
{
    [self.currentView removeFromSuperview];
    self.currentView = currentView;
    
    [self.view addSubview:self.currentView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[currentView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(currentView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[currentView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(currentView)]];
}

@end

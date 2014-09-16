//
//  NCAdvancedPreferencesViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCAdvancedPreferencesViewController.h"
#import "NCGeneralParametersViewController.h"
#import "NCConsumerParametersViewController.h"
#import "NCProducerParametersViewController.h"

#import "AppDelegate.h"

#include <ndnrtc/simple-log.h>

NSString* const kGeneralParameters = @"General parameters";
NSString* const kConsumerParameters = @"Consumer parameters";
NSString* const kProducerParameters = @"Producer parameters";

@interface NCAdvancedPreferencesViewController ()

@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet NSView *contentView;
@property (weak) IBOutlet NSView *settingsView;

@property (nonatomic, strong) NSArray *advancedSettings;
@property (strong) IBOutlet NSArrayController *arrayController;

@end

@implementation NCAdvancedPreferencesViewController

-(id)init
{
    return [self initWithNibName:@"NCAdvancedPreferencesView" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        NCGeneralParametersViewController *generalParameteresViewController = [[NCGeneralParametersViewController alloc] init];
        NCConsumerParametersViewController *consumerParametersViewController = [[NCConsumerParametersViewController alloc] init];
        NCProducerParametersViewController *producerParametersViewController = [[NCProducerParametersViewController alloc] initWithPreferences:self.preferences];

        generalParameteresViewController.preferences = self.preferences;
        consumerParametersViewController.preferences = self.preferences;
        
        self.advancedSettings = @[
                                  @{@"name":kGeneralParameters, @"controller":generalParameteresViewController},
                                  @{@"name":kConsumerParameters, @"controller":consumerParametersViewController},
                                  @{@"name":kProducerParameters, @"controller":producerParametersViewController}
                                  ];
    }
    return self;
}

- (void)awakeFromNib
{
    [self loadView:[[self.advancedSettings firstObject] valueForKeyPath:@"controller.view"]];
}

-(void)dealloc
{
    self.advancedSettings = nil;
}

- (NSString *)identifier
{
    return @"AdvancedPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameAdvanced];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Advanced", @"");
}

- (NCPreferencesController*)preferences
{
    return [NCPreferencesController sharedInstance];
}

// NSTableView delegate
-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 30.;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    NSViewController *controller = [[self.advancedSettings objectAtIndex:tableView.selectedRow] valueForKeyPath:@"controller"];
    
    if (controller)
        [self loadView: controller.view];
}

-(void)loadView:(NSView*)aView
{
    // remove previous subviews from content view
    if (self.contentView.subviews)
        for (NSView *view in self.contentView.subviews)
             [view removeFromSuperview];
    
    [self.contentView addSubview:aView];
    
    [self.contentView addConstraints:[NSLayoutConstraint
                                      constraintsWithVisualFormat:@"H:|[aView]|"
                                      options:0 metrics:nil
                                      views:NSDictionaryOfVariableBindings(aView)]];
    [self.contentView addConstraints:[NSLayoutConstraint
                                      constraintsWithVisualFormat:@"V:|[aView]|"
                                      options:0
                                      metrics:nil
                                      views:NSDictionaryOfVariableBindings(aView)]];
    
//    // adjust custom view's size to the view's size
//    self.contentView.frame = aView.bounds;
//    [self.contentView addSubview:aView];
//    
//    // check is split view is smaller than required
//    if (CGRectGetHeight(self.splitView.frame) != CGRectGetHeight(self.contentView.frame) ||
//        CGRectGetWidth(self.splitView.frame) != CGRectGetWidth(self.contentView.frame)+CGRectGetWidth(self.settingsView.frame)+self.splitView.dividerThickness)
//    {
//        CGRect splitViewFrame = self.splitView.frame;
//        splitViewFrame = CGRectMake(0, 0,
//                                    CGRectGetWidth(self.settingsView.frame)+self.splitView.dividerThickness+CGRectGetWidth(self.contentView.frame),
//                                    CGRectGetHeight(self.contentView.frame));
//        self.splitView.frame = splitViewFrame;
//        
//        NSWindow *preferencesWindow = [(AppDelegate*)[NSApplication sharedApplication].delegate preferencesWindowController].window;
//        CGRect newWindowRect = [preferencesWindow frameRectForContentRect:splitViewFrame];
//        newWindowRect.origin = preferencesWindow.frame.origin;
//        newWindowRect.origin.y += CGRectGetHeight(preferencesWindow.frame)-CGRectGetHeight(newWindowRect);
//
//        [preferencesWindow setContentMinSize:splitViewFrame.size];
//        [preferencesWindow setFrame:newWindowRect display:YES animate:NO];
//    }
}

@end

@interface NCLogLevelValueTransformer : NSValueTransformer
@end

@implementation NCLogLevelValueTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

-(id)transformedValue:(id)value
{
    if (!value || ![value isKindOfClass:[NSNumber class]])
        return nil;
    
    int outputLevel = -1;
    
    switch ([value intValue]) {
        case ndnlog::NdnLoggerDetailLevelAll: // log level all
            outputLevel = 4;
            break;
        case ndnlog::NdnLoggerDetailLevelDebug: // log level debug
            outputLevel = 3;
            break;
        case ndnlog::NdnLoggerDetailLevelNone: // log level none
            outputLevel = 1;
            break;
        default: // log level default
            outputLevel = 2;
            break;
    }
    
    return @(outputLevel);
}

-(id)reverseTransformedValue:(id)value
{
    if (!value || ![value isKindOfClass:[NSNumber class]])
        return nil;
    
    int logLevel = -1;
    
    switch ([value intValue]) {
        case 1: // none
            logLevel = ndnlog::NdnLoggerDetailLevelNone;
            break;
        case 3: // debug
            logLevel = ndnlog::NdnLoggerDetailLevelDebug;
            break;
        case 4: // all
            logLevel = ndnlog::NdnLoggerDetailLevelAll;
            break;
        default:
            logLevel = ndnlog::NdnLoggerDetailLevelDefault;
            break;
    }
    
    return @(logLevel);
}

@end

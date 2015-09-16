//
//  NCAdvancedPreferencesViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCAdvancedPreferencesViewController.h"
#import "NCGeneralParametersViewController.h"
#import "NCProducerParametersViewController.h"
#import "NCDiscoveryParametersViewController.h"

#import "AppDelegate.h"

#include <ndnrtc/params.h>

NSString* const kGeneralParameters = @"Advanced settings";
NSString* const kProducerParameters = @"Media streams";
NSString* const kChatAndDiscoveryParameters = @"Chat and discovery";

@interface NCAdvancedPreferencesViewController ()

@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet NSView *contentView;
@property (weak) IBOutlet NSView *settingsView;
@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic, strong) NSArray *advancedSettings;
@property (strong) IBOutlet NSArrayController *arrayController;

@property (nonatomic, strong) NCProducerParametersViewController *producerController;

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
        generalParameteresViewController.preferences = self.preferences;
        NCDiscoveryParametersViewController *discoveryParametersViewController = [[NCDiscoveryParametersViewController alloc] init];
        discoveryParametersViewController.preferences = self.preferences;
        
        self.advancedSettings = @[
                                  @{@"name":kGeneralParameters, @"controller":generalParameteresViewController},
                                  @{@"name":kProducerParameters},
                                  @{@"name":kChatAndDiscoveryParameters, @"controller":discoveryParametersViewController}
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

- (NCPreferencesController*)preferences
{
    return [NCPreferencesController sharedInstance];
}

// MASPreferencesViewController
- (NSString *)identifier
{
    return @"AdvancedPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"media_icon"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Advanced", @"");
}

- (void)viewDidDisappear
{
    [self unloadProducerViews];
}

// override
-(BOOL)commitEditing
{
    [self unloadProducerViews];
    return [super commitEditing];
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
    {
        self.producerController = nil;
        [self loadView: controller.view];
    }
    else
        if ([[[self.advancedSettings objectAtIndex:tableView.selectedRow] valueForKeyPath:@"name"] isEqualToString:kProducerParameters])
    {
        self.producerController = [[NCProducerParametersViewController alloc] initWithPreferences:self.preferences];
        [self loadView:self.producerController.view];
    }
        
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
}

-(void)unloadProducerViews
{
    self.producerController = nil;
    [self loadView:[[[self.advancedSettings firstObject] valueForKeyPath:@"controller"] view]];
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
    [self.tableView selectRowIndexes:indexSet byExtendingSelection:NO];
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
            outputLevel = 5;
            break;
        case ndnlog::NdnLoggerDetailLevelDebug: // log level debug
            outputLevel = 4;
            break;
        case ndnlog::NdnLoggerLevelStat:
            outputLevel = 3;
            break;
        case ndnlog::NdnLoggerDetailLevelDefault:
            outputLevel = 2;
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
        case 2: // default
            logLevel = ndnlog::NdnLoggerDetailLevelDefault;
            break;
        case 3: // stat
            logLevel = ndnlog::NdnLoggerLevelStat;
            break;
        case 4: // debug
            logLevel = ndnlog::NdnLoggerDetailLevelDebug;
            break;
        case 5: // all
            logLevel = ndnlog::NdnLoggerDetailLevelAll;
            break;
        default:
            logLevel = ndnlog::NdnLoggerDetailLevelDefault;
            break;
    }
    
    return @(logLevel);
}

@end

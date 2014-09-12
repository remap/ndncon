//
//  NCGeneralPreferencesViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCGeneralPreferencesViewController.h"

@interface NCGeneralPreferencesViewController ()

@property (weak) IBOutlet NSTextField *daemonStatusLabel;

@end

@implementation NCGeneralPreferencesViewController

-(id)init
{
    return [self initWithNibName:@"NCGeneralPreferencesView" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"");
}

-(NCPreferencesController*)preferences
{
    return [NCPreferencesController sharedInstance];
}

@end

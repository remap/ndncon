//
//  NCMediaPreferencesViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCMediaPreferencesViewController.h"

@interface NCMediaPreferencesViewController ()

@end

@implementation NCMediaPreferencesViewController

-(id)init
{
    return [self initWithNibName:@"NCMediaPreferencesView" bundle:nil];
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
    return @"MediaPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"media_icon"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Audio/Video", @"");
}

@end

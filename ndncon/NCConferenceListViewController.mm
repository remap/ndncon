//
//  NCConferenceListViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCConferenceListViewController.h"
#import "NCDiscoveryLibraryController.h"

//******************************************************************************
@interface NCConferenceListCell : NSTableCellView

@property (nonatomic) IBOutlet NSTextField *conferenceNameLabel;
@property (nonatomic) IBOutlet NSTextField *conferenceDescriptionLabel;

@end

//******************************************************************************
@implementation NCConferenceListCell

-(void)dealloc
{
    self.conferenceNameLabel = nil;
    self.conferenceDescriptionLabel = nil;
}

@end

//******************************************************************************
@interface NCConferenceListViewController ()

@property (nonatomic, weak) IBOutlet NSPopover *popover;
@property (nonatomic) NSMutableArray *discoveredConferences;
@property (nonatomic) NSMutableArray *organizedConferences;
@property (weak) IBOutlet NSArrayController *localConferencesArrayController;
@property (weak) IBOutlet NSButton *createConferenceButton;

@end

//******************************************************************************
@implementation NCConferenceListViewController

#pragma mark - init & dealloc
-(id)init
{
    self = [super init];
    
    if (self)
    {
    }
    
    return self;
}

#pragma mark - public
- (IBAction)createConference:(id)sender {
    [self.popover showRelativeToRect:self.createConferenceButton.frame
                              ofView:self.createConferenceButton.superview
                       preferredEdge:NSMaxXEdge];
}


@end

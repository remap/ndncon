//
//  NCConferenceView.m
//  NdnCon
//
//  Created by Peter Gusev on 10/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCConferenceViewController.h"
#import "NSDate+NCAdditions.h"
#import "User.h"
#import "NSString+NCAdditions.h"
#import "User.h"
#import "AppDelegate.h"
#import "NSView+NCDragAndDropAbility.h"

//******************************************************************************
@interface NCConferenceViewController ()

@property (weak) IBOutlet NSTextField *conferenceNameTextField;
@property (weak) IBOutlet NSTextField *conferenceDescriptionTextField;
@property (weak) IBOutlet NSTableView *participantsTableView;

@property (nonatomic) NSString *startHour;
@property (nonatomic) NSString *startMinute;
@property (nonatomic) NSString *amPm;
@property (nonatomic) NSString *duration;
@property (nonatomic) NSArray *durationsArray;

@property (nonatomic, readonly) NSArray *orderedParticipants;
@property (weak) IBOutlet NSView *timeInfoView;
@property (weak) IBOutlet NSTextField *timeInfoLabel;
@property (weak) IBOutlet NSButton *publishButton;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *joinButton;

@property (nonatomic, readonly) NSManagedObjectContext *context;

@end


//******************************************************************************
@implementation NCConferenceViewController

-(id)init
{
    self = [self initWithNibName:@"NCConferenceView" bundle:nil];
    
    if (self)
    {
        self.durationsArray = @[@"30min",@"1hr", @"1.5hr", @"2hrs", @"3hrs", @"4hrs"];
    }
    
    return self;
}

-(void)awakeFromNib
{
    [self.participantsTableView registerForDraggedTypes:@[NSStringPboardType]];
    
    NSResponder *nextResponder = self.participantsTableView.nextResponder;
    [self.participantsTableView setNextResponder:self];
    [self setNextResponder:nextResponder];
}

-(void)setConference:(Conference *)conference
{
    if (_conference != conference)
    {
        _conference = conference;
        self.conferenceNameTextField.stringValue = conference.name;
        self.conferenceDescriptionTextField.stringValue = conference.conferenceDescription;
        self.startHour = [NSString stringWithFormat:@"%lu",
                          (unsigned long)conference.startDate.hour%12];
        self.startMinute = [NSString stringWithFormat:@"%.2lu",
                            (unsigned long)conference.startDate.minute];
        self.amPm = (([conference.startDate hour] > 11)?@"PM":@"AM");
        self.duration = [NCConferenceViewController stringRepresentationForConferenceDuration:conference.duration];
        self.timeInfoLabel.stringValue = [NSString stringWithFormat:@"%@:%@ %@ (%@)",
                                          self.startHour, self.startMinute, self.amPm, self.duration];
        [self.participantsTableView reloadData];
    }
}

-(void)setIsEditable:(BOOL)isEditable
{
    _isEditable = isEditable;
    
    [self.conferenceNameTextField setEditable:isEditable];
    [self.conferenceDescriptionTextField setEditable:isEditable];
    [self.timeInfoLabel setHidden:isEditable];
    [self.timeInfoView setHidden:!isEditable];
    [self.publishButton setHidden:!isEditable];
    
    if (isEditable)
        [self.cancelButton setHidden:NO];
    
    if (!isEditable)
    {
        //            [self.conferenceNameTextField sizeToFit];
        //            [self.conferenceNameTextField setNeedsDisplay];
        //            [self.conferenceNameTextField updateConstraints];
        // this is strange - this call actually updates autolayout
        // contstraints
//        [self.conferenceNameTextField mouseDown:nil];
    }
}

-(void)setIsOwner:(BOOL)isOwner
{
    _isOwner = isOwner;
    
    if (!isOwner)
        self.isEditable = NO;
    
    [self.cancelButton setHidden:!_isOwner];
}

- (IBAction)publishConference:(id)sender
{
    self.isEditable = !self.isEditable;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(conferenceViewControllerDidPublishConference:)])
        [self.delegate conferenceViewControllerDidPublishConference:self];
}

- (IBAction)cancelConference:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(conferenceViewControllerDidCancelConference:)])
        [self.delegate conferenceViewControllerDidCancelConference:self];
}

- (IBAction)joinConference:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(conferenceViewControllerDidJoinConference:)])
        [self.delegate conferenceViewControllerDidJoinConference:self];
}

- (IBAction)deleteSelectedEntry:(id)sender
{
    if (self.isEditable && self.isOwner)
    {
        User *user = [self.orderedParticipants objectAtIndex:self.participantsTableView.selectedRow];
        [self.conference removeParticipantsObject:user];
        [self.context save:NULL];
        [self.participantsTableView reloadData];
    }
}

# pragma mark - NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (self.isEditable)
        return (self.conference.participants.count)?self.conference.participants.count:1;
    
    return self.conference.participants.count;
}

# pragma mark - NSTableViewDelegate
-(BOOL)tableView:(NSTableView *)tableView
      acceptDrop:(id<NSDraggingInfo>)info
             row:(NSInteger)row
   dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSArray *nrtcUserUrlArray = [NSView validUrlsFromPasteBoard:[info draggingPasteboard]];
    
    [nrtcUserUrlArray enumerateObjectsUsingBlock:^(NSString *userUrl, NSUInteger idx, BOOL *stop) {
        User *user = [User userByName:[userUrl userNameFromNrtcUrlString] fromContext:self.context];
        [self.conference addParticipantsObject:user];
    }];
    
    [self.participantsTableView reloadData];
    
    return YES;
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    NSArray *nrtcUserUrlArray = [NSView validUrlsFromPasteBoard:[info draggingPasteboard]];
    
    if (nrtcUserUrlArray.count)
        return NSDragOperationCopy;
    
    return NSDragOperationNone;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cellView = nil;
    
    if (self.conference.participants.count)
    {
        User *participant = [self.orderedParticipants objectAtIndex:row];
        cellView = [self.participantsTableView makeViewWithIdentifier:@"ParticipantCell" owner:nil];
        cellView.textField.stringValue = participant.name;
    }
    else
    {
        cellView = [self.participantsTableView makeViewWithIdentifier:@"InfoCell" owner:nil];
        cellView.textField.stringValue = @"To add particiapnts to the conference, drag&drop users from the user list...";
    }
    
    return cellView;
}

#pragma mark - private
-(NSManagedObjectContext *)context
{
    return [(AppDelegate*)[NSApp delegate] managedObjectContext];
}

-(NSArray *)orderedParticipants
{
    return [self.conference.participants sortedArrayUsingDescriptors:
            @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
}

+(NSString*)stringRepresentationForConferenceDuration:(NSNumber*)durationInSeconds
{
    NSString *durationString = @"";
    double durationHours = round(durationInSeconds.doubleValue/3600*100)/100;
    
    if (durationHours < 1.)
        durationString = [NSString stringWithFormat:@"%.1fmin", 60*durationHours];
    else if (durationHours < 2.)
    {
        if (durationHours-1 > 0)
            durationString = [NSString stringWithFormat:@"%.1fhr", durationHours];
        else
            durationString = [NSString stringWithFormat:@"%.0fhr", durationHours];
    }
    else
        durationString = [NSString stringWithFormat:@"%.0fhrs", durationHours];
    
    return durationString;
}

@end

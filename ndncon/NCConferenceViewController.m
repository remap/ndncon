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
    }
}

-(void)setIsEditable:(BOOL)isEditable
{
    if (_isEditable != isEditable)
    {
        _isEditable = isEditable;

        if (isEditable)
        {
            [self.conferenceNameTextField setEditable:YES];
            [self.conferenceDescriptionTextField setEditable:YES];

        }
        else
        {
            
        }
    }
}

# pragma mark - NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.conference.participants.count;
}

# pragma mark - NSTableViewDelegate
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    User *participant = [self.orderedParticipants objectAtIndex:row];
    NSTableCellView *cellView = [self.participantsTableView makeViewWithIdentifier:@"ParticipantCell" owner:nil];
    
    cellView.textField.stringValue = participant.name;
    
    return cellView;
}

#pragma mark - private
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

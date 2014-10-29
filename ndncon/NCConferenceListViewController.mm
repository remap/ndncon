//
//  NCConferenceListViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/22/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCConferenceListViewController.h"
#import "NCDiscoveryLibraryController.h"
#import "NSDate+NCAdditions.h"
#import "Conference.h"
#import "ChatRoom.h"
#import "User.h"
#import "AppDelegate.h"
#import "NCChatViewController.h"
#import "NCConferenceViewController.h"
#import "NSObject+NCAdditions.h"

NSString* const kCellTypeKey = @"cellType";
NSString* const kCellDataKey = @"cellData";
NSString* const kCellTypeHeader = @"header";
NSString* const kCellTypeData = @"data";

NSString* const kFutureConferencesHeader = @"Upcoming";
NSString* const kCurrentConferencesHeader = @"Current";
NSString* const kPastConferencesHeader = @"Past";
NSString* const kNoConferences = @"no conferences";

//******************************************************************************
@interface NCPopoverController : NSViewController<NSPopoverDelegate>
{
    BOOL _enterHit;
}

@property (nonatomic, weak) IBOutlet id<NCPopoverControllerDelegate> delegate;

@property (weak) IBOutlet NSTextField *conferenceNameTextField;
@property (weak) IBOutlet NSTextField *conferenceDescriptionTextField;
@property (nonatomic) NSArray *hours;
@property (nonatomic) NSString *startHour;
@property (nonatomic) NSArray *minutes;
@property (nonatomic) NSString *startMinute;
@property (nonatomic) NSString *amPm;
@property (nonatomic, readonly) NSDate *startDate;
@property (nonatomic) NSArray *durations;
@property (nonatomic) NSString *duration;
@property (nonatomic) NSNumber *durationInSeconds;

@end

//******************************************************************************
@protocol NCPopoverControllerDelegate <NSObject>

@optional
-(void)popoverControllerDidFinish:(NCPopoverController*)popoverController;
-(void)popoverControllerDidCancel:(NCPopoverController*)popoverController;

@end

//******************************************************************************
@implementation NCPopoverController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.durations = @[@"30min",@"1hr", @"1.5hr", @"2hrs", @"3hrs", @"4hrs"];
    }
    
    return self;
}

#pragma mark - NSPopoverDelegate
-(void)popoverWillShow:(NSNotification *)notification
{
    _enterHit = NO;
    self.conferenceNameTextField.stringValue = @"";
    self.conferenceDescriptionTextField.stringValue = @"";
    NSUInteger hour = (([[NSDate date] hour]+1) != 12)?([[NSDate date] hour]+1)%12:12;
    self.startHour = [NSString stringWithFormat:@"%lu", hour];
    self.startMinute = @"00";
    self.duration = @"1hr";
    self.amPm = ([[NSDate date] hour]+1 > 11)?@"PM":@"AM";
}

-(void)popoverDidClose:(NSNotification *)notification
{
    if (!_enterHit &&
        self.delegate && [self.delegate respondsToSelector:@selector(popoverControllerDidCancel:)])
        [self.delegate popoverControllerDidCancel:self];
}

- (IBAction)didHitEnter:(id)sender {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(popoverControllerDidFinish:)] &&
        [self.delegate respondsToSelector:@selector(popoverControllerDidCancel:)])
    {
        _enterHit = YES;
        
        if ([self.conferenceNameTextField.stringValue length])
            [self.delegate popoverControllerDidFinish:self];
        else
            [self.delegate popoverControllerDidCancel:self];
    }
}

#pragma mark - private
-(NSDate *)startDate
{
    [NSTimeZone resetSystemTimeZone];
    
    NSTimeZone *currentTimeZone = [NSTimeZone systemTimeZone];
    NSDate *startDate = [NSDate dateWithNaturalLanguageString:
                         [NSString stringWithFormat:@"Today, %@:%@ %@ %@",
                         self.startHour, self.startMinute, self.amPm,
                         currentTimeZone.abbreviation]];
    return startDate;
}

-(NSNumber*)durationInSeconds
{
    
    switch ([self.durations indexOfObject:self.duration]) {
        case 0:
            return @(0.5*3600);
        case 2:
            return @(1.5*3600);
        case 3:
            return @(2*3600);
        case 4:
            return @(3*3600);
        case 5:
            return @(4*3600);
        case 1: // fall through
        default:
            return @(3600);
    }
}

@end

//******************************************************************************
@interface NCConferenceListCell : NSTableCellView

@property (nonatomic) IBOutlet NSTextField *conferenceNameLabel;
@property (nonatomic) IBOutlet NSTextField *conferenceDescriptionLabel;
@property (nonatomic) IBOutlet NSTextField *conferenceTimeInfoLabel;

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

@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic, readonly) NSManagedObjectContext *context;
@property (nonatomic, weak) IBOutlet NSPopover *popover;
@property (nonatomic) NSMutableArray *discoveredConferences;
@property (nonatomic) NSMutableArray *organizedConferences;
@property (weak) IBOutlet NSArrayController *localConferencesArrayController;
@property (weak) IBOutlet NSButton *createConferenceButton;

@property (nonatomic) NSArray *tableContents;

@property (nonatomic) NSArray *allConferences;
@property (nonatomic) NSArray *futureConferences;
@property (nonatomic) NSArray *currentConferences;
@property (nonatomic) NSArray *pastConferences;

-(void)prepareContents;

@end

//******************************************************************************
@implementation NCConferenceListViewController

#pragma mark - init & dealloc
-(id)init
{
    self = [super init];
    
    if (self)
    {
        [self subscribeForNotificationsAndSelectors:
         NCConferenceWithdrawedNotification, @selector(onConferenceWithdrawed:),
         NCConferenceDiscoveredNotification, @selector(onConferenceDiscovered:),
         nil];
    }
    
    return self;
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
}

-(void)awakeFromNib
{
    [self prepareContents];
    [self.tableView reloadData];
    
    NSResponder *nextResponder = self.tableView.nextResponder;
    [self.tableView setNextResponder:self];
    [self setNextResponder:nextResponder];
}

#pragma mark - public
- (IBAction)createConference:(id)sender {
    [self.popover showRelativeToRect:self.createConferenceButton.frame
                              ofView:self.createConferenceButton.superview
                       preferredEdge:NSMaxXEdge];
}

-(void)clearSelection
{
//    [self.tableView deselectAll:nil];
}

-(void)reloadData
{
    [self prepareContents];
    [self.tableView reloadData];
}

#pragma mark - NCPopoverControllerDelegate
-(void)popoverControllerDidCancel:(NCPopoverController *)popoverController
{
    
}

-(void)popoverControllerDidFinish:(NCPopoverController *)popoverController
{
    [self.popover performClose:self];
    Conference* conference = [Conference newConferenceWithName:popoverController.conferenceNameTextField.stringValue
                                                     inContext:self.context];

    conference.conferenceDescription = popoverController.conferenceDescriptionTextField.stringValue;
    conference.duration = popoverController.durationInSeconds;
    conference.startDate = popoverController.startDate;
    
    ChatRoom *chatRoom = [ChatRoom newChatRoomWithId:conference.name
                                           inContext:self.context];
    conference.chatRoom = chatRoom;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(conferenceListController:didAddConference:)])
        [self.delegate conferenceListController:self didAddConference:conference];
}

#pragma mark - NSTableViewDelegate
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    id data = [self.tableContents objectAtIndex:row];
    NSTableCellView *view = nil;
    
    if ([data isKindOfClass:[NSDictionary class]])
    {
        view = [self.tableView makeViewWithIdentifier:@"HeaderCell" owner:nil];
        
        if ([[data valueForKey:kCellTypeKey] isEqualToString:kCellTypeHeader])
        {
            [view setWantsLayer:YES];
            [view.layer setBackgroundColor:[NSColor colorWithRed:250./255. green:230./255. blue:180./255. alpha:1.].CGColor];
        }
        else
            [view.layer setBackgroundColor:[NSColor whiteColor].CGColor];

        view.textField.stringValue = [data valueForKey:kCellDataKey];
    }
    else
    {
        id<ConferenceEntityProtocol> conference = data;
        
        view = [self.tableView makeViewWithIdentifier:@"ConferenceCell" owner:nil];
        if ([data isKindOfClass:[NSDictionary class]])
            view.textField.stringValue = [NSString stringWithFormat:@"%@ (by %@)",
                                          conference.name,
                                          conference.organizer.name];
        else
            view.textField.stringValue = conference.name;
        ((NCConferenceListCell*)view).conferenceDescriptionLabel.stringValue = conference.conferenceDescription;

        NSDate *conferenceStartDate = conference.startDate;
        NSString *conferenceStartDateString = [NCChatMessageCell textRepresentationForDate:conferenceStartDate];
        NSNumber *conferenceDuration = conference.duration;
        
        ((NCConferenceListCell*)view).conferenceTimeInfoLabel.stringValue = [NSString stringWithFormat:@"%@ (%@)",
                                                                             conferenceStartDateString,
                                                                             [NCConferenceViewController stringRepresentationForConferenceDuration:conferenceDuration]];
    }
    
    return view;
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    id data = [self.tableContents objectAtIndex:row];
    
    if ([data isKindOfClass:[NSDictionary class]] &&
        [data objectForKey:kCellTypeKey])
        return 30.;
    
    return 60.;
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    id data = [self.tableContents objectAtIndex:row];
    
    return !([data isKindOfClass:[NSDictionary class]] && [data objectForKey:kCellTypeKey]);
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    id conference = [self.tableContents objectAtIndex:self.tableView.selectedRow];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(conferenceListController:didSelectConference:)])
        [self.delegate conferenceListController:self
                            didSelectConference:conference];
}

#pragma mark - NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.tableContents.count;
}

#pragma mark - private
-(void)onConferenceDiscovered:(NSNotification*)notification
{
    NSLog(@"New conference: %@", notification.userInfo);
    [self reloadData];
}

-(void)onConferenceWithdrawed:(NSNotification*)notification
{
    NSLog(@"Conference gone: %@", notification.userInfo);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(conferenceListController:remoteConferenceWithdrawed:)])
    {
        NSDictionary *conferenceDict = notification.userInfo;
        __block NCRemoteConference *remoteConference = nil;
        
        [self.tableContents enumerateObjectsUsingBlock:
         ^(id<ConferenceEntityProtocol> obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[NCRemoteConference class]] &&
                [[obj name] isEqualToString:[conferenceDict valueForKey:kConferenceNameKey]] &&
                [[obj organizer].name isEqualToString:[conferenceDict valueForKey:kConferenceOrganizerNameKey]] &&
                [[obj organizer].prefix isEqualToString:[conferenceDict valueForKey:kConferenceOrganizerPrefixKey]])
                remoteConference = obj;
        }];
        
        [self.delegate conferenceListController:self
                     remoteConferenceWithdrawed:remoteConference];
    }
    
    [self reloadData];
}

- (IBAction)deleteSelectedEntry:(id)sender
{
    id conference = [self.tableContents objectAtIndex:self.tableView.selectedRow];

    if ([conference isKindOfClass:[Conference class]])
    {
        if (![self.pastConferences containsObject:conference])
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(conferenceListController:wantsDeleteConference:)])
            {
                [self.delegate conferenceListController:self wantsDeleteConference:conference];
            }
        }
    }
}

-(NSManagedObjectContext *)context
{
    return [(AppDelegate*)[NSApp delegate] managedObjectContext];
}

-(void)prepareContents
{
    NSArray *myConferences = [Conference allConferencesFromContext:self.context];
    NSArray *remoteConferences = [[NCDiscoveryLibraryController sharedInstance] discoveredConferences];
    NSMutableArray *allConferences = [myConferences mutableCopy];
    
    [allConferences addObjectsFromArray:remoteConferences];
    [allConferences sortUsingDescriptors:@[[NSSortDescriptor
                                            sortDescriptorWithKey:NSStringFromSelector(@selector(startDate))
                                            ascending:NO]]];
    
    self.futureConferences = [allConferences filteredArrayUsingPredicate:
                                  [NSPredicate predicateWithBlock:^BOOL(id<ConferenceEntityProtocol> conference, NSDictionary *bindings)
    {
        NSDate *conferenceDate = conference.startDate;
        return ([conferenceDate compare:[NSDate date]] == NSOrderedDescending);
    }]];
    
    self.currentConferences = [allConferences filteredArrayUsingPredicate:
                                   [NSPredicate predicateWithBlock:^BOOL(id<ConferenceEntityProtocol> conference, NSDictionary *bindings)
    {
        NSDate *conferenceDate = conference.startDate;
        NSNumber *conferenceDuration = conference.duration;
        NSDate *conferenceEndDate = [conferenceDate dateByAddingTimeInterval:[conferenceDuration doubleValue]];
        
        return ([conferenceDate compare:[NSDate date]] == NSOrderedAscending) &&
        ([conferenceEndDate compare:[NSDate date]] == NSOrderedDescending);
    }]];
    
    self.pastConferences = [allConferences filteredArrayUsingPredicate:
                                [NSPredicate predicateWithBlock:^BOOL(Conference *conference, NSDictionary *bindings)
    {
        NSDate *conferenceDate = conference.startDate;
        NSNumber *conferenceDuration = conference.duration;
        NSDate *conferenceEndDate = [conferenceDate dateByAddingTimeInterval:[conferenceDuration doubleValue]];
        
        return ([conferenceEndDate compare:[NSDate date]] == NSOrderedAscending);
    }]];
    
    NSMutableArray *contents = [NSMutableArray array];
    {
        [contents addObject:@{kCellTypeKey:kCellTypeHeader,
                              kCellDataKey:[kFutureConferencesHeader uppercaseString]}];
        
        if (self.futureConferences.count)
            [contents addObjectsFromArray:self.futureConferences];
        else
            [contents addObject:@{kCellTypeKey:kCellTypeData,
                                  kCellDataKey:kNoConferences}];
    }
    {
        [contents addObject:@{kCellTypeKey: kCellTypeHeader,
                              kCellDataKey: [kCurrentConferencesHeader uppercaseString]}];
        
        if (self.currentConferences.count)
            [contents addObjectsFromArray:self.currentConferences];
        else
            [contents addObject:@{kCellTypeKey:kCellTypeData,
                                  kCellDataKey:kNoConferences}];
    }
    {
        [contents addObject:@{kCellTypeKey: kCellTypeHeader,
                              kCellDataKey: [kPastConferencesHeader uppercaseString]}];
        
        if (self.pastConferences.count)
            [contents addObjectsFromArray:self.pastConferences];
        else
            [contents addObject:@{kCellTypeKey:kCellTypeData,
                                  kCellDataKey:kNoConferences}];
    }
    
    self.tableContents = [NSArray arrayWithArray:contents];
}

@end

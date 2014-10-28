//
//  NCConferenceView.h
//  NdnCon
//
//  Created by Peter Gusev on 10/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Conference.h"

@protocol NCConferenceViewControllerDelegate;

@interface NCConferenceViewController : NSViewController
<NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) id<NCConferenceViewControllerDelegate> delegate;

@property (nonatomic) id<ConferenceEntityProtocol> conference;
@property (nonatomic) BOOL isEditable;
@property (nonatomic) BOOL isOwner;

+(NSString*)stringRepresentationForConferenceDuration:(NSNumber*)durationInSeconds;

@end


@protocol NCConferenceViewControllerDelegate <NSObject>

@optional
-(void)conferenceViewControllerDidCancelConference:(NCConferenceViewController*)conferenceViewController;
-(void)conferenceViewControllerDidPublishConference:(NCConferenceViewController*)conferenceViewController;
-(void)conferenceViewControllerDidJoinConference:(NCConferenceViewController*)conferenceViewController;


@end
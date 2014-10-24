//
//  NCConferenceView.h
//  NdnCon
//
//  Created by Peter Gusev on 10/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Conference.h"

@interface NCConferenceViewController : NSViewController
<NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic) Conference *conference;
@property (nonatomic) BOOL isEditable;

+(NSString*)stringRepresentationForConferenceDuration:(NSNumber*)durationInSeconds;

@end

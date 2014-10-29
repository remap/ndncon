//
//  NCChatViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/13/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NCChatMessageCellDelegate;

@interface NCChatViewController : NSViewController
<NSTableViewDataSource, NSTableViewDelegate, NCChatMessageCellDelegate>

@property (nonatomic) NSString *chatRoomId;
@property (weak) IBOutlet NSTextField *chatInfoTextField;

// chat room should be active only when both users are online
@property (nonatomic, setter=setActive:) BOOL isActive;

@end

@interface NCChatMessageCell : NSTableCellView

+(NSString*)textRepresentationForDate:(NSDate*)date;

@end

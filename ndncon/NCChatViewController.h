//
//  NCChatViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 10/13/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NCChatViewControllerDelegate;

//******************************************************************************
@interface NCChatViewController : NSViewController
<NSTableViewDataSource, NSTableViewDelegate>

@property (weak) id<NCChatViewControllerDelegate> delegate;
@property (nonatomic) NSString *chatRoomId;
@property (weak) IBOutlet NSTextField *chatInfoTextField;

// chat room should be active only when both users are online
@property (nonatomic, setter=setActive:) BOOL isActive;

-(void)newChatMessage:(NSNotification*)notification;

@end

//******************************************************************************
@interface NCChatMessageCell : NSTableCellView

+(NSString*)textRepresentationForDate:(NSDate*)date;

@end

//******************************************************************************
@protocol NCChatViewControllerDelegate <NSObject>

@optional
-(void)chatViewControllerDidFinishLoadingMessages:(NCChatViewController*)chatViewController;

@end

//
//  NCConversationInfoView.h
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    NCConversationInfoStatusOffline,
    NCConversationInfoStatusOnlineNotPublishing,
    NCConversationInfoStatusOnline,
} NCConversationInfoStatus;

@protocol NCConversationInfoViewDelegate;

@interface NCConversationInfoView : NSView

@property (nonatomic, weak) IBOutlet id<NCConversationInfoViewDelegate> delegate;
@property (nonatomic) NCConversationInfoStatus status;

@end


@protocol NCConversationInfoViewDelegate <NSObject>
@optional
-(void)converstaionInfoViewWasClicked:(NCConversationInfoView*)infoView;

@end
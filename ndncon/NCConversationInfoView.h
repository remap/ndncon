//
//  NCConversationInfoView.h
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCClickableView.h"

typedef enum : NSUInteger {
    NCConversationInfoStatusOffline,
    NCConversationInfoStatusOnlineNotPublishing,
    NCConversationInfoStatusOnline,
} NCConversationInfoStatus;

@protocol NCConversationInfoViewDelegate;

//******************************************************************************
@interface NCConversationInfoView : NCClickableView
<NSDraggingDestination>

@property (nonatomic, weak) id<NCConversationInfoViewDelegate, NCClickableViewDelegate> delegate;
@property (nonatomic) NCConversationInfoStatus status;

@end

//******************************************************************************
@protocol NCConversationInfoViewDelegate <NSObject>

@optional
-(BOOL)conversationInfoView:(NCConversationInfoView*)view
    shouldAcceptDraggedUrls:(NSArray*)nrtcUserUrlArray;
-(void)conversationInfoView:(NCConversationInfoView*)view
       didAcceptDraggedUrls:(NSArray*)nrtcUserUrlArray;

@end
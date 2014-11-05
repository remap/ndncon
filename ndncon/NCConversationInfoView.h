//
//  NCConversationInfoView.h
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCClickableView.h"
#import "NSView+NCDragAndDropAbility.h"

typedef enum : NSUInteger {
    NCConversationInfoStatusOffline,
    NCConversationInfoStatusOnlineNotPublishing,
    NCConversationInfoStatusOnline,
} NCConversationInfoStatus;

//******************************************************************************
@interface NCConversationInfoView : NCClickableView
<NSDraggingDestination>

@property (nonatomic, weak) id<NCDragAndDropViewDelegate, NCClickableViewDelegate> delegate;
@property (nonatomic) NCConversationInfoStatus status;
@property (nonatomic) BOOL selected;

@end

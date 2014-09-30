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

@interface NCConversationInfoView : NCClickableView

@property (nonatomic) NCConversationInfoStatus status;

@end

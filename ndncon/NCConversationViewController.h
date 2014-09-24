//
//  NCConversationViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCStreamBrowserController.h"
#import "NCNdnRtcLibraryController.h"

@protocol NCConversationViewControllerDelegate;

extern NSString* const kNCStreamsArrayKey;

@interface NCConversationViewController : NSViewController
<NCStreamBrowserControllerDelegate>

//+(NSString*)textStatusFromSessionStatus:(NCSessionStatus)sessionStatus;

@property (nonatomic, weak) id<NCConversationViewControllerDelegate> delegate;
@property (nonatomic, readonly) NCSessionStatus currentConversationStatus;

// participants array:
// [
//      {
//          kNCSessionPrefixKey: <session_prefix>
//          kNCSessionUserNameKey: <username>,
//          kNCStreamsArrayKey: [
//                                  <stream_prefix1>
//                                  <stream_prefix2>
//                                  ...
//                                  <stream_prefixN>
//                              ]
//      }
// ]
//
@property (nonatomic) NSArray *participants;

-(void)startPublishingWithConfiguration:(NSDictionary*)streamsConfiguration;

@end

@protocol NCConversationViewControllerDelegate <NSObject>

@optional
-(void)conversationViewControllerDidEndConversation:(NCConversationViewController*)converstaionVc;
-(void)conversationViewControllerNeedsStreamConfiguration:(NCConversationViewController*)converstaionVc;

@end
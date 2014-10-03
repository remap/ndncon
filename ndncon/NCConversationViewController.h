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
#import "NCStreamPreviewController.h"
#import "NCActiveStreamViewer.h"

@protocol NCConversationViewControllerDelegate;

@interface NCConversationViewController : NSViewController
<NCStreamBrowserControllerDelegate,
NCStreamPreviewControllerDelegate,
NCActiveStreamViewerDelegate>

//+(NSString*)textStatusFromSessionStatus:(NCSessionStatus)sessionStatus;

@property (nonatomic, weak) id<NCConversationViewControllerDelegate> delegate;
@property (nonatomic, readonly) NCSessionStatus currentConversationStatus;

// participants array:
// [
//      {
//          kNCSessionPrefixKey: <session_prefix>
//          kNCSessionUserNameKey: <username>,
//          kNCStreamsDicitonaryKey: {
//                                  <stream_prefix1> : <userInfo1>
//                                  <stream_prefix2> : <userInfo2>
//                                  ...
//                                  <stream_prefixN> : <userInfoN>
//                              }
//      }
// ]
//
@property (nonatomic) NSArray *participants;

-(void)startPublishingWithConfiguration:(NSDictionary*)streamsConfiguration;
/**
 * Start fetching from remote user
 * @param userInfo Dictionary with structure:
 *                  {
 *                      kNCSessionUserNameKey : <username>,
 *                      kNCHubPrefixKey : <hub_prefix>,
 *                      kNCSessionInfoKey : <session_info>,
 *                  }
 *
 */
-(void)startFetchingWithConfiguration:(NSDictionary*)userInfo;

@end

@protocol NCConversationViewControllerDelegate <NSObject>

@optional
-(void)conversationViewControllerDidEndConversation:(NCConversationViewController*)converstaionVc;
-(void)conversationViewControllerNeedsStreamConfiguration:(NCConversationViewController*)converstaionVc;

@end
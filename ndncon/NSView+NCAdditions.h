//
//  NSView+NCDragAndDropAbility.h
//  NdnCon
//
//  Created by Peter Gusev on 10/21/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NCDragAndDropViewDelegate;

//******************************************************************************
// This protocol dictates which methods and properties should be implemented if
// view wants to accept drag & drop operations
@protocol NCDragAndDropView <NSObject>

@required
@property (nonatomic, weak) id<NCDragAndDropViewDelegate> delegate;

@end

//******************************************************************************
// This category extends any view with NdnCon drag&drop ability
@interface NSView (NCDragAndDropAbility)
<NSDraggingDestination, NCDragAndDropView>

+(NSArray*)validUrlsFromPasteBoard:(NSPasteboard*)pasteboard;

@end

//******************************************************************************
// This protocol declares methods which should be implemented on view's delegate
// in order to fully support NdnCon drag&drop operations
@protocol NCDragAndDropViewDelegate <NSObject>

@optional
-(BOOL)dragAndDropView:(NSView*)view shouldAcceptDraggedUrls:(NSArray*)nrtcUserUrlArray;
-(void)dragAndDropView:(NSView*)view
  didAcceptDraggedUrls:(NSArray*)nrtcUserUrlArray;

@end

//******************************************************************************
// Trackable view - allows to specify block which will be called on
// updateTrackingAreas
typedef void(^NCUpdateTrackingAreas)(NSView *);

@interface NCTrackableView : NSView

@property (nonatomic, strong) NCUpdateTrackingAreas updateTrackingAreasBlock;

@end

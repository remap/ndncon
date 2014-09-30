//
//  NCClickableView.h
//  NdnCon
//
//  Created by Peter Gusev on 9/29/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NCClickableViewDelegate;

@interface NCClickableView : NSView

@property (nonatomic, weak) IBOutlet id<NCClickableViewDelegate> delegate;

@end

@protocol NCClickableViewDelegate <NSObject>

@optional
-(void)viewWasClicked:(NCClickableView*)view;

@end
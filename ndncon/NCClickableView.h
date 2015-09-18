//
//  NCClickableView.h
//  NdnCon
//
//  Created by Peter Gusev on 9/29/14.
//  Copyright 2013-2015 Regents of the University of California.
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
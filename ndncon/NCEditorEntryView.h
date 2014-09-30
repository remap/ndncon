//
//  NCEditorEntryView.h
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    EditorEntryViewHeaderStyleGloss = 1,
    EditorEntryViewHeaderStyleDark = 2,
    EditorEntryViewHeaderStyleNone = 3
} NCEditorEntryViewHeaderStyle;

@interface NCEditorEntryView : NSView

@property (nonatomic) CGFloat headerHeight;
@property (nonatomic) BOOL roundCorners;
@property (nonatomic) NCEditorEntryViewHeaderStyle headerStyle;
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) CGFloat shadowInset;

@end

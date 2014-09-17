//
//  NCStreamPreviewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamPreviewController.h"

@interface NCStreamPreviewController ()

@end

@implementation NCStreamPreviewController

-(id)init
{
    self = [super init];
    
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

-(void)initialize
{
    self.view = [[NSView alloc] init];
    [self.view setTranslatesAutoresizingMaskIntoConstraints:NO];    
}

-(void)setStreamName:(NSString *)streamCaption
{
    self.streamCaptionLabel.stringValue = streamCaption;
}

-(NSString *)streamName
{
    return self.streamCaptionLabel.stringValue;
}

@end

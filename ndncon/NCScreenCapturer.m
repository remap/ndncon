//
//  NCScreenCapturer.m
//  NdnCon
//
//  Created by Peter Gusev on 7/26/15.
//  Copyright 2013-2015 Regents of the University of California
//

#import "NCScreenCapturer.h"

@interface NCScreenCapturer ()

@property (nonatomic) AVCaptureScreenInput *screenInput;

@end

@implementation NCScreenCapturer

-(instancetype)initWithDisplayId:(CGDirectDisplayID)displayId
{
    self = [super init];
    
    if (self)
    {
        self.screenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:displayId];
        
        if (!self.screenInput)
            return nil;
        
        [self.session addInput:self.screenInput];
    }
    
    return self;
}

-(void)dealloc
{
    self.screenInput = nil;
}

@end

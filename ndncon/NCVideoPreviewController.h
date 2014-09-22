//
//  NCVideoPreviewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamPreviewController.h"
#import "NCCameraCapturer.h"

@interface NCVideoPreviewController : NCStreamPreviewController

-(void)setPreviewForCameraCapturer:(NCCameraCapturer*)cameraCapturer;

@end

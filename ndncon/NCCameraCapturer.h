//
//  NCCameraCapturer.h
//  NdnCon
//
//  Created by Peter Gusev on 9/19/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCBaseCapturer.h"

@interface NCCameraCapturer : NCBaseCapturer

-(instancetype)initWithDevice:(AVCaptureDevice*)device
          andFormat:(AVCaptureDeviceFormat*)format;

@end

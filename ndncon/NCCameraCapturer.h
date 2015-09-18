//
//  NCCameraCapturer.h
//  NdnCon
//
//  Created by Peter Gusev on 9/19/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Foundation/Foundation.h>
#import "NCBaseCapturer.h"

@interface NCCameraCapturer : NCBaseCapturer

-(instancetype)initWithDevice:(AVCaptureDevice*)device
          andFormat:(AVCaptureDeviceFormat*)format;

@end

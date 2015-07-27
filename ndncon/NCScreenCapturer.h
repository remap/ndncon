//
//  NCScreenCapturer.h
//  NdnCon
//
//  Created by Peter Gusev on 7/26/15.
//  Copyright (c) 2015 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCBaseCapturer.h"

@interface NCScreenCapturer : NCBaseCapturer

-(instancetype)initWithDisplayId:(CGDirectDisplayID)displayId;

@end

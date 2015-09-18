//
//  NCScreenCapturer.h
//  NdnCon
//
//  Created by Peter Gusev on 7/26/15.
//  Copyright 2013-2015 Regents of the University of California
//

#import <Foundation/Foundation.h>
#import "NCBaseCapturer.h"

@interface NCScreenCapturer : NCBaseCapturer

-(instancetype)initWithDisplayId:(CGDirectDisplayID)displayId;

@end

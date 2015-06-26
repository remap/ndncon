//
//  NCCameraCapturer.h
//  NdnCon
//
//  Created by Peter Gusev on 9/19/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol NCCameraCapturerDelegate;

@interface NCCameraCapturer : NSObject
<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic) id<NCCameraCapturerDelegate> delegate;
@property (nonatomic, readonly) AVCaptureSession *session;

-(id)initWithDevice:(AVCaptureDevice*)device
          andFormat:(AVCaptureDeviceFormat*)format;

-(void)startCapturing;
-(void)stopCapturing;

-(void)setNdnRtcExternalCapturer:(void*)externalCapturer;


@end

@protocol NCCameraCapturerDelegate <NSObject>

@required
//-(void)cameraCapturer:(NCCameraCapturer*)capturer didDeliveredArgbFrameData:(NSData*)frameData;
-(void)cameraCapturer:(NCCameraCapturer*)capturer didObtainedError:(NSError*)error;

@end
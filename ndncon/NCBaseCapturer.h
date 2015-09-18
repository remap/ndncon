//
//  NCBaseCapturer.h
//  NdnCon
//
//  Created by Peter Gusev on 7/26/15.
//  Copyright 2013-2015 Regents of the University of California
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol NCCapturerDelegate;

//******************************************************************************
@interface NCBaseCapturer : NSObject
<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, weak) id<NCCapturerDelegate> delegate;
@property (nonatomic, readonly) AVCaptureSession *session;

-(void)startCapturing;
-(void)stopCapturing;
-(void)setNdnRtcExternalCapturer:(void*)externalCapturer;
-(void)presentError:(NSError*)error;

@end

//******************************************************************************
@protocol NCCapturerDelegate <NSObject>

@required
-(void)capturer:(NCBaseCapturer*)capturer didObtainedError:(NSError*)error;

@end
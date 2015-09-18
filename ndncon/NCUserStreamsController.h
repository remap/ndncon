//
//  NCUserStreamsController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Cocoa/Cocoa.h>
#import "NCStackEditorViewController.h"
#import "NCVideoPreviewController.h"
#import "NCUserPreviewController.h"

@protocol NCUserStreamsControllerDelegate;

//******************************************************************************
@interface NCUserStreamsController : NCStackEditorViewController<NCUserPreviewControllerDelegate>

@property (weak) id<NCUserStreamsControllerDelegate> delegate;

-(NCVideoPreviewController*)addStream:(NSDictionary*)streamConfiguration
                              forUser:(NSString*)username
                           withPrefix:(NSString*)prefix;
-(void)removeStream:(NSDictionary*)streamConfiguration
            forUser:(NSString*)username
         withPrefix:(NSString*)prefix;
-(void)dropUser:(NSString*)username
     withPrefix:(NSString*)prefix;

@end

//******************************************************************************
@protocol NCUserStreamsControllerDelegate <NSObject>

@optional
-(void)userStreamsController:(NCUserStreamsController*)userStreamsController
         didDropUserWithName:(NSString*)username
                   andPrefix:(NSString*)prefix
                 withStreams:(NSArray*)streamConfigurations;

-(void)userStreamsController:(NCUserStreamsController*)userStreamsController
              didDropStreams:(NSArray*)streamConfigurations
                     forUser:(NSString*)username
                  withPrefix:(NSString*)prefix;

-(void)userStreamsController:(NCUserStreamsController*)userStreamsController
      needMoreStreamsIsAudio:(BOOL)isAudioRequired
                     forUser:(NSString*)username
                  withPrefix:(NSString*)prefix;

@end
//
//  NCProducerParametersViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCProducerParametersViewController.h"
#import "NCStreamEditorViewController.h"
#import "NCVideoStreamViewController.h"
#import "NCAudioStreamViewController.h"
#import "NSScrollView+NCAdditions.h"

@interface NCProducerParametersViewController ()

@property (strong) NCStreamEditorViewController *streamEditorController;
@property (weak) IBOutlet NSScrollView *scrollView;

@property (strong) NSMutableArray *streamControllers;
@end

@implementation NCProducerParametersViewController

- (id)init
{
    return [self initWithNibName:@"NCProducerParametersView" bundle:nil];
}

-(id)initWithPreferences:(NCPreferencesController *)preferences
{
    self = [self init];
    
    if (self)
    {
        self.preferences = preferences;
        self.streamEditorController =  [[NCStreamEditorViewController alloc] initWithPreferencesController:self.preferences];
    }
    
    return self;
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    return self;
}

-(void)dealloc
{
    self.preferences = nil;
    self.streamEditorController = nil;
}

-(void)awakeFromNib
{
    [self.scrollView addStackView:self.streamEditorController.stackView
                  withOrientation:NSUserInterfaceLayoutOrientationVertical];
    [self.streamEditorController setAudioStreams:self.preferences.audioStreams
                                 andVideoStreams:self.preferences.videoStreams];
}

- (IBAction)addAudioStream:(id)sender
{
    [self.streamEditorController addAudioStream:[NCAudioStreamViewController defaultConfguration]];
}

- (IBAction)addVideoStream:(id)sender
{
    [self.streamEditorController addVideoStream:[NCVideoStreamViewController defaultConfguration]];
}

@end

@interface NCEditorClipView : NSClipView

@end

@implementation NCEditorClipView

-(BOOL)isFlipped
{
    return YES;
}

@end

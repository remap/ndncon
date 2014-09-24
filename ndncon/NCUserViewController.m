//
//  NCUserViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCUserViewController.h"
#import "NCStreamEditorViewController.h"
#import "NCPreferencesController.h"
#import "NSScrollView+NCAdditions.h"
#import "NCUserStreamViewController.h"
#import "NSObject+NCAdditions.h"
#import "NCNdnRtcLibraryController.h"

@interface NCUserViewController ()

@property (weak) IBOutlet NSScrollView *scrollView;
@property (nonatomic) NCStreamEditorViewController *streamEditorController;

@end

@implementation NCUserViewController

-(id)init
{
    self = [super initWithNibName:@"NCUserView" bundle:nil];
    
    if (self)
    {
        self.streamEditorController = [[NCStreamEditorViewController alloc] initWithPreferencesController:[NCPreferencesController sharedInstance]];
        self.streamEditorController.videoStreamViewControllerClass = [NCVideoUserStreamViewController class];
        self.streamEditorController.audioStreamViewControllerClass = [NCAudioUserStreamViewController class];
        self.statusImage = [[NCNdnRtcLibraryController sharedInstance]
                            imageForSessionStatus:SessionStatusOffline];

        [self subscribeForNotificationsAndSelectors:
         NCSessionStatusUpdateNotification, @selector(onSessionStatusUpdate:),
         nil];
    }
    
    return self;
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
}

-(void)awakeFromNib
{
    [self.scrollView addStackView:self.streamEditorController.stackView
                  withOrientation:NSUserInterfaceLayoutOrientationVertical];
    [self.streamEditorController awakeFromNib];
    if (self.sessionInfo)
        [self updateStreams];
}

-(void)setUserInfo:(NSDictionary *)userInfo
{
    _userInfo = userInfo;
    self.statusImage = [[NCNdnRtcLibraryController sharedInstance]
                        imageForSessionStatus:[[_userInfo valueForKey:kNCSessionStatusKey] integerValue]];
}

-(void)setSessionInfo:(NCSessionInfoContainer *)sessionInfo
{
    if (![_sessionInfo isEqual:sessionInfo])
    {
        _sessionInfo = sessionInfo;
        [self updateStreams];
    }
}

// private
-(void)updateStreams
{
    [self.streamEditorController setAudioStreams:[NSMutableArray arrayWithArray: [self.sessionInfo audioStreamsConfigurations]]
                                 andVideoStreams:[NSMutableArray arrayWithArray:[self.sessionInfo videoStreamsConfigurations]]];
}

-(void)onSessionStatusUpdate:(NSNotification*)notification
{
    if ([[self.userInfo objectForKey:kNCSessionPrefixKey]
         isEqualTo:[notification.userInfo objectForKey:kNCSessionPrefixKey]])
    {
        self.userInfo = notification.userInfo;
        self.sessionInfo = [self.userInfo valueForKey:kNCSessionInfoKey];
    }
}

@end

@interface NCSessionStatusTransformer : NSValueTransformer
@end

@implementation NCSessionStatusTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

-(id)transformedValue:(id)value
{
    NCSessionStatus status = [value intValue];
    
    switch (status) {
        case SessionStatusOnlineNotPublishing:
            return @"online, not publishing";
        case SessionStatusOnlinePublishing:
            return @"publishing";
        default:
            return @"offline";
    }
}

@end

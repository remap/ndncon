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
#import "NCStreamViewerController.h"

@interface NCUserViewController ()

@property (weak) IBOutlet NSScrollView *scrollView;
//@property (nonatomic) NCStreamEditorViewController *streamEditorController;
@property (nonatomic) NCStreamViewerController *streamEditorController;
@property (weak) IBOutlet NSButton *fetchAllButton;

@end

@implementation NCUserViewController

-(id)init
{
    self = [super initWithNibName:@"NCUserView" bundle:nil];
    
    if (self)
    {
        self.streamEditorController = [[NCStreamViewerController alloc] init];
        self.statusImage = [[NCNdnRtcLibraryController sharedInstance]
                            imageForSessionStatus:SessionStatusOffline];

        [self subscribeForNotificationsAndSelectors:
         NCRemoteSessionStatusUpdateNotification, @selector(onSessionStatusUpdate:),
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

    NCSessionStatus status = [[self.userInfo valueForKey:kNCSessionStatusKey] integerValue];
    [self.fetchAllButton setEnabled:(status == SessionStatusOnlinePublishing)];
}

-(void)setUserInfo:(NSDictionary *)userInfo
{
    _userInfo = userInfo;
    self.streamEditorController.userName = [userInfo valueForKey:kNCSessionUsernameKey];
    self.streamEditorController.userPrefix = [userInfo valueForKey:kNCHubPrefixKey];
    
    NCSessionStatus status = [[_userInfo valueForKey:kNCSessionStatusKey] integerValue];
    
    self.statusImage = [[NCNdnRtcLibraryController sharedInstance]
                        imageForSessionStatus:status];
    [self.fetchAllButton setEnabled:(status == SessionStatusOnlinePublishing)];
}

-(void)setSessionInfo:(NCSessionInfoContainer *)sessionInfo
{
    if (![_sessionInfo isEqual:sessionInfo] &&
        !(sessionInfo == _sessionInfo))
    {
        _sessionInfo = sessionInfo;
        [self updateStreams];
    }
}

// private
- (IBAction)fetchAll:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(userViewControllerFetchStreamsClicked:)])
        [self.delegate userViewControllerFetchStreamsClicked:self];
}

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

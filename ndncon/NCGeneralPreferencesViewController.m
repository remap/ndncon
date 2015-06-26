//
//  NCGeneralPreferencesViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/9/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCGeneralPreferencesViewController.h"
#import "NSObject+NCAdditions.h"
#import "NCPreferencesController.h"
#import "NCNdnRtcLibraryController.h"

@interface NCGeneralPreferencesViewController ()

@property (weak) IBOutlet NSTextField *daemonStatusLabel;
@property (weak) IBOutlet NSTextField *connectionStatusLabel;

@end

@implementation NCGeneralPreferencesViewController

-(id)init
{
    return [self initWithNibName:@"NCGeneralPreferencesView" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self startObservingSelf];
        [self subscribeForNotificationsAndSelectors:
         NCLocalSessionStatusUpdateNotification, @selector(onLocalSessionStatusUpdate:),
         NCLocalSessionErrorNotification, @selector(onLocalSessionStatusUpdate:),
         nil];
    }
    return self;
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
    [self stopObservingSelf];
}

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"");
}

-(NCPreferencesController*)preferences
{
    return [NCPreferencesController sharedInstance];
}

-(NSString *)connectionStatus
{
    return [self stringFromSessionStatus:[NCNdnRtcLibraryController sharedInstance].sessionStatus];
}

// KVO
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([NCPreferencesController sharedInstance] == object)
    {
        // if session started - we should restart it now cause parameters
        // has changed
        if ([NCNdnRtcLibraryController sharedInstance].sessionStatus != SessionStatusOffline)
        {
            [[NCNdnRtcLibraryController sharedInstance] stopSession];
            [[NCNdnRtcLibraryController sharedInstance] startSession];
        }
    }
}

// private
-(void)onLocalSessionStatusUpdate:(NSNotification*)notification
{
    self.connectionStatusLabel.stringValue = [self stringFromSessionStatus:[[notification.userInfo valueForKey:kSessionStatusKey] integerValue]];
}

-(NSString*)stringFromSessionStatus:(NCSessionStatus)status
{
    switch (status) {
        case SessionStatusOnlineNotPublishing:
        case SessionStatusOnlinePublishing:
            return @"connected";
        case SessionStatusOffline:
        default:
            return @"disconnected";
    }
}

-(void)startObservingSelf
{
    [[NCPreferencesController sharedInstance]
     addObserver: self
     forKeyPaths:
     NSStringFromSelector(@selector(logLevel)),
     NSStringFromSelector(@selector(userName)),
     NSStringFromSelector(@selector(prefix)),
     NSStringFromSelector(@selector(daemonHost)),
     NSStringFromSelector(@selector(daemonPort)),
     nil];
}

-(void)stopObservingSelf
{
    [[NCPreferencesController sharedInstance]
     removeObserver: self
     forKeyPaths:
     NSStringFromSelector(@selector(logLevel)),
     NSStringFromSelector(@selector(userName)),
     NSStringFromSelector(@selector(prefix)),
     NSStringFromSelector(@selector(daemonHost)),
     NSStringFromSelector(@selector(daemonPort)),
     nil];
}

@end

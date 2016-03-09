//
//  AppDelegate.m
//  NdnCon
//
//  Created by Peter Gusev on 9/8/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#include <signal.h>

#import "AppDelegate.h"

#import "NCNdnRtcLibraryController.h"
#import "NCAdvancedPreferencesViewController.h"
#import "NCGeneralPreferencesViewController.h"
#import "NSObject+NCAdditions.h"
#import "NCErrorController.h"
#import "User.h"
#import "NCChatLibraryController.h"
#import "NCDiscoveryLibraryController.h"
#import "NCPreferencesController.h"
#import "NCStreamingController.h"
#import "NSDictionary+NCAdditions.h"
#import "NSArray+NCAdditions.h"
#import "NSString+NCAdditions.h"
#import "NCFaceSingleton.h"

NSString* const kNCDaemonConnectionStatusUpdate = @"kNCDaemonConnectionStatusUpdate";

//******************************************************************************
void signalHandler(int signal);

//******************************************************************************
@interface AppDelegate()

@property (weak) IBOutlet SUUpdater *sparkleUpdater;

@end

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

+(void)initialize
{
    signal(SIGPIPE, signalHandler);
    
    [NCPreferencesController sharedInstanceWithDefaultsFile:@"settings"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"f04e450096a94f9989a875d20d4b8662"];
    [[BITHockeyManager sharedHockeyManager].crashManager setAutoSubmitCrashReport:YES];
    [[BITHockeyManager sharedHockeyManager] setDelegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [BITHockeyManager sharedHockeyManager].crashManager.askUserDetails = NO;
    [BITHockeyManager sharedHockeyManager].feedbackManager.requireUserName = BITFeedbackUserDataElementOptional;
    [BITHockeyManager sharedHockeyManager].feedbackManager.requireUserEmail = BITFeedbackUserDataElementOptional;
    
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    BITSystemProfile *bsp = [BITSystemProfile sharedSystemProfile];
    [dnc addObserver:bsp selector:@selector(startUsage) name:NSApplicationDidBecomeActiveNotification object:nil];
    [dnc addObserver:bsp selector:@selector(stopUsage) name:NSApplicationWillTerminateNotification object:nil];
    
    self.sparkleUpdater.sendsSystemProfile = YES;
    
    [[NCPreferencesController sharedInstance] updateDefaults];
    [[NCPreferencesController sharedInstance] checkVersionParameters];
    
#ifdef DEBUG
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    NSLog(@"%@ v%@ (debug version)", [NCPreferencesController sharedInstance].appName, [NCPreferencesController sharedInstance].versionString);
#else
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    NSLog(@"%@ v%@", [NCPreferencesController sharedInstance].appName, [NCPreferencesController sharedInstance].versionString);
#endif
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *resetSettings = [defaults stringForKey:@"reset-settings"];
    
    if (resetSettings)
        [[NCPreferencesController sharedInstance] resetDefaults];
    
    if ([NCPreferencesController sharedInstance].isFirstLaunch)
    {
        NSLog(@"First launch indeed!");
        [NCPreferencesController sharedInstance].firstLaunch = NO;
        [NCPreferencesController sharedInstance].userName = [self generateUniqueUsername];
    }
    else
        NSLog(@"Not a first launch. We're friends already...");
    
    [self setupAutoFetch];
    [self setupAutoPublishParams];
    
    [self initConnection];
    [[NCUserDiscoveryController sharedInstance]
     addObserver:self
     forKeyPaths:NSStringFromSelector(@selector(isInitialized)), nil];
    [[NCChatroomDiscoveryController sharedInstance]
     addObserver:self
     forKeyPaths:NSStringFromSelector(@selector(isInitialized)), nil];
    [self subscribeForNotificationsAndSelectors:
     NCLocalSessionStatusUpdateNotification, @selector(onLocalSessionUpdate:),
     kNCFetchedStreamsAddedNotification, @selector(onFetchingActivityChanged:),
     kNCFetchedStreamsRemovedNotification, @selector(onFetchingActivityChanged:),
     kNCFetchedUserAddedNotification, @selector(onFetchingActivityChanged:),
     kNCFetchedUserRemovedNotification, @selector(onFetchingActivityChanged:),
     nil];
    
    [self setupAutoPublishStreams];
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "ucla.edu.NdnCon" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"ucla.edu.NdnCon"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NdnCon" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"NdnCon.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    // enable automatic data model migration
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType
                                   configuration:nil URL:url
                                         options:options error:&error])
    {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [self cleanup];
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![self commitManagedContext])
        return NSTerminateCancel;
    
    return NSTerminateNow;
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

-(IBAction)showPreferences:(id)sender
{
    if (self.preferencesWindowController != nil)
        self.preferencesWindowController = nil;
    
    if (self.preferencesWindowController == nil)
    {
        NSViewController *generalViewController = [[NCGeneralPreferencesViewController alloc] init];
        NSViewController *advancedViewController = [[NCAdvancedPreferencesViewController alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, advancedViewController, nil];
        
        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        self.preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
    }
    
    [self.preferencesWindowController showWindow:nil];
}

-(NCPreferencesController *)preferences
{
    return [NCPreferencesController sharedInstance];
}

-(BOOL)commitManagedContext
{
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NO;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return YES;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NO;
        }
    }
    
    return YES;
}

-(BOOL)isConnected
{
    return [NCUserDiscoveryController sharedInstance].isInitialized &&
    [NCChatroomDiscoveryController sharedInstance].isInitialized &&
    [NCNdnRtcLibraryController sharedInstance].sessionStatus != SessionStatusOffline;
}

-(BOOL)hasActivity
{
    return ([NCNdnRtcLibraryController sharedInstance].sessionStatus == SessionStatusOnlinePublishing) ||
    ([NCStreamingController sharedInstance].allFetchedStreams.count > 0);
}

//******************************************************************************
-(void)initConnection
{
    [[NCFaceSingleton sharedInstance] startProcessingEvents];
    [[NCNdnRtcLibraryController sharedInstance] startSession];
    [NCChatLibraryController sharedInstance];
    [NCUserDiscoveryController sharedInstance];
    [NCChatroomDiscoveryController sharedInstance];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary<NSString *,id> *)change
                      context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(isInitialized))])
    {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isConnected))];
        [self didChangeValueForKey:NSStringFromSelector(@selector(isConnected))];
        [self notifyNowWithNotificationName:kNCDaemonConnectionStatusUpdate
                                andUserInfo:nil];
    }
}

-(void)onLocalSessionUpdate:(NSNotification*)notification
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isConnected))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(isConnected))];
    [self willChangeValueForKey:NSStringFromSelector(@selector(hasActivity))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(hasActivity))];
}

-(void)onFetchingActivityChanged:(NSNotification*)notification
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(hasActivity))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(hasActivity))];
}

-(void)cleanup
{
    [[NCStreamingController sharedInstance] stopPublishingStreams:[[NCStreamingController sharedInstance] allPublishedStreams]];
    [[NCStreamingController sharedInstance] stopFetchingAllStreams];
    [[NCChatLibraryController sharedInstance] leaveAllChatRooms];
    [[NCNdnRtcLibraryController sharedInstance] stopSession];
    [[NCNdnRtcLibraryController sharedInstance] releaseLibrary];
}

-(void)setupAutoFetch
{
    @autoreleasepool
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *autoFetchPrefix = [defaults stringForKey:kAutoFetchPrefixCmdArg];
        NSString *autoFetchUser = [defaults stringForKey:kAutoFetchUserCmdArg];
        NSInteger autoFetchVideo = [defaults integerForKey:kAutoFetchVideoCmdArg];
        NSInteger autoFetchAudio = [defaults integerForKey:kAutoFetchAudioCmdArg];
        NSString *autoFetchStream = [defaults stringForKey:kAutoFetchStreamCmdArg];
        
        if (autoFetchPrefix && autoFetchUser &&
            (autoFetchAudio == 1 || autoFetchVideo == 1 || autoFetchStream))
        {
            NSLog(@"auto-fetch enabled for %@:%@ (audio %@, video %@, stream %@)",
                  autoFetchPrefix, autoFetchUser,
                  (autoFetchAudio?@"YES":@"NO"), (autoFetchVideo?@"YES":@"NO"),
                  (autoFetchStream?autoFetchStream:@"NO"));
            
            [self subscribeForNotificationsAndSelectors:
             NCUserUpdatedNotificaiton, @selector(onUserDiscoveryNotification:),
             NCUserDiscoveredNotification, @selector(onUserDiscoveryNotification:),
             NCUserWithdrawedNotification, @selector(onUserDiscoveryNotification:),
             nil];
        }
    }
}

-(void)setupAutoPublishParams
{
    @autoreleasepool {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *autoPublishPrefix = [defaults stringForKey:kAutoPublishPrefixCmdArg];
        NSString *autoPublishUser = [defaults stringForKey:kAutoPublishUserCmdArg];
        NSInteger autoPublishAudio = [defaults integerForKey:kAutoPublishAudioCmdArg];
        NSInteger autoPublishVideo = [defaults integerForKey:kAutoPublishVideoCmdArg];
        
        if (autoPublishPrefix && autoPublishUser &&
            (autoPublishAudio == 1 || autoPublishVideo == 1))
        {
            NSLog(@"auto-publishing enabled for %@:%@ (audio %@, video %@)",
                  autoPublishPrefix, autoPublishUser,
                  (autoPublishAudio?@"YES":@"NO"),
                  (autoPublishVideo?@"YES":@"NO"));
            
            [NCPreferencesController sharedInstance].prefix = autoPublishPrefix;
            [NCPreferencesController sharedInstance].userName = autoPublishUser;
        }
    }
}

-(void)setupAutoPublishStreams
{
    @autoreleasepool {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *autoPublishPrefix = [defaults stringForKey:kAutoPublishPrefixCmdArg];
        NSString *autoPublishUser = [defaults stringForKey:kAutoPublishUserCmdArg];
        NSInteger autoPublishAudio = [defaults integerForKey:kAutoPublishAudioCmdArg];
        NSInteger autoPublishVideo = [defaults integerForKey:kAutoPublishVideoCmdArg];
        
        if (autoPublishPrefix && autoPublishUser &&
            (autoPublishAudio == 1 || autoPublishVideo == 1))
        {
            if (autoPublishAudio)
                [[NCStreamingController sharedInstance] publishStreams:[NCPreferencesController sharedInstance].audioStreams];
            
            if (autoPublishVideo)
                [[NCStreamingController sharedInstance] publishStreams:[NCPreferencesController sharedInstance].videoStreams];
        }
    }
}

-(NSString*)generateUniqueUsername
{
    return [NSString stringWithFormat:@"jedi%d", (int)[[NSDate date] timeIntervalSince1970]];
}

-(void)onUserDiscoveryNotification:(NSNotification*)notification
{
    NSString *autoFetchPrefix = [[NSUserDefaults standardUserDefaults] stringForKey:kAutoFetchPrefixCmdArg];
    NSString *autoFetchUser = [[NSUserDefaults standardUserDefaults] stringForKey:kAutoFetchUserCmdArg];
    NSInteger autoFetchVideo = [[NSUserDefaults standardUserDefaults] integerForKey:kAutoFetchVideoCmdArg];
    NSInteger autoFetchAudio = [[NSUserDefaults standardUserDefaults] integerForKey:kAutoFetchAudioCmdArg];
    NSString *autoFetchStream = [[NSUserDefaults standardUserDefaults] stringForKey:kAutoFetchStreamCmdArg];
    
    if ([notification.name isEqualToString: NCUserUpdatedNotificaiton] ||
        [notification.name isEqualToString:NCUserDiscoveredNotification])
    {
        NCActiveUserInfo *userInfo = notification.userInfo[kUserInfoKey];
        
        if ([userInfo.hubPrefix isEqualToString:autoFetchPrefix] &&
            [userInfo.username isEqualToString:autoFetchUser])
        {
            NSLog(@"discovered auto-fetch user: %@:%@", userInfo.hubPrefix, userInfo.username);
            
            NSMutableArray *streamsToFetch = [NSMutableArray array];
            
            if ([userInfo.streamConfigurations streamWithName:autoFetchStream])
            {
                NSLog(@"will auto-fetch stream %@", autoFetchStream);
                [streamsToFetch addObject:[userInfo.streamConfigurations streamWithName:autoFetchStream]];
            }

            if (autoFetchAudio)
            {
                NSLog(@"will auto-fetch all audio streams");
                [streamsToFetch addObjectsFromArray:[userInfo getDefaultFetchAudioThreads]];
            }
            
            if (autoFetchVideo)
            {
                NSLog(@"will auto-fetch all video streams");
                [streamsToFetch addObjectsFromArray:[userInfo getDefaultFetchVideoThreads]];
            }
            
            NSLog(@"auto-fetch streams %@", streamsToFetch);
            [[NCStreamingController sharedInstance] fetchStreams:streamsToFetch
                                                        fromUser:userInfo.username
                                                      withPrefix:userInfo.hubPrefix];
        }
    }
}

- (IBAction)sendFeedback:(id)sender {
    [[BITHockeyManager sharedHockeyManager].feedbackManager showFeedbackWindow];
}

-(NSArray*)feedParametersForUpdater:(SUUpdater *)updater sendingSystemProfile:(BOOL)sendingProfile
{
    return [[BITSystemProfile sharedSystemProfile] systemUsageData];
}

# pragma mark - delegation BITHockeyManagerDelegate
-(NSString*)userIDForHockeyManager:(BITHockeyManager *)hockeyManager componentManager:(BITHockeyBaseManager *)componentManager
{
    return [NSString userIdWithName:[NCPreferencesController sharedInstance].userName
                          andPrefix:[NCPreferencesController sharedInstance].prefix];
}

-(NSString*)userNameForHockeyManager:(BITHockeyManager *)hockeyManager
                    componentManager:(BITHockeyBaseManager *)componentManager
{
    return [NCPreferencesController sharedInstance].userName;
}

@end

//******************************************************************************
void signalHandler(int signal)
{
    switch (signal) {
        case SIGPIPE:
            NSLog(@"SIGPIPE caught!!!");
            break;
        default:
            break;
    }
}


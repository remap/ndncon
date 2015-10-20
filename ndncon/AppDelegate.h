//
//  AppDelegate.h
//  NdnCon
//
//  Created by Peter Gusev on 9/8/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>
#import <HockeySDK/HockeySDK.h>

#import "MASPreferencesWindowController.h"
#import "NCPreferencesController.h"

@interface AppDelegate : NSObject
<NSApplicationDelegate, SUUpdaterDelegate, BITHockeyManagerDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) MASPreferencesWindowController* preferencesWindowController;
@property (nonatomic, readonly) NCPreferencesController *preferences;

- (IBAction)saveAction:(id)sender;
- (BOOL)commitManagedContext;

@end

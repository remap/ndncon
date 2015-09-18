//
//  NSObject+NCAdditions.h
//  NdnCon
//
//  Created by Peter Gusev on 9/16/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Foundation/Foundation.h>

@interface NSObject (NCAdditions)

/**
 * @name Instance methods
 */
/**
 * Generates notification into default notification queue with specified name with NSPostNow method
 * @param notificationName Name of notification
 * @param userInfo User's info dictionary
 */
-(void)notifyNowWithNotificationName:(NSString*)notificationName andUserInfo:(NSDictionary*)userInfo;

/**
 * Subscribe current instance for notifications. Notifications list should be eneded with nil
 * @param notification1 Name of first notification
 */
-(void)subscribeForNotificationsAndSelectors:(NSString*)notification1,...;

/**
 * Unsubscribe from notifications
 */
-(void)unsubscribeFromNotifications:(NSString*)notification1,...;

/**
 * Unsubscribe from notifications
 */
-(void)unsubscribeFromNotifications;

/**
 * Adds observer of object for specified key paths. Observer class need to implement  -(void)observeValueForKeyPath:ofObject:change:context: method in order to get updates. Change dictionary in this case will conatin old and new values.
 */
-(void)addObserver:(id)observer forKeyPaths:(NSString*)keyPath1,...;

/**
 * Removes observer of object for specified key paths
 */
-(void)removeObserver:(id)observer forKeyPaths:(NSString*)keyPath1,...;

@end

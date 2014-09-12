//
//  PTNStorage.h
//  PTNStorage
//
//  Created by Peter Gusev on 7/24/12.
//  Copyright (c) 2012 peetonn inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PTN_DEFAULT_PARAMS_FILE @"PTNDefaults"

/**
 * Class for storing all necessary parameters and defaults of application between launches
 */
@interface PTNStorage : NSObject {
    NSUserDefaults *_defaultParams;
    NSString *_storageFile;
}
/////////////////////////////////////////////////////////////////////////
/// @name Properties
/////////////////////////////////////////////////////////////////////////
/**
 * Dictionary of default settings loaded from file
 */
@property (nonatomic, readonly) NSDictionary *defaults;

/////////////////////////////////////////////////////////////////////////
/// @name Initialization
/////////////////////////////////////////////////////////////////////////
/**
 * Initializes an instance of PTNStorage with sepcified storage file. 
 * @param fname Name of storage file. If nil, PTN_DEFAULT_PARAMS_FILE is used
 */
- (id)initWithStorageFile:(NSString*)fname;

/////////////////////////////////////////////////////////////////////////
/// @name Instance methods
/////////////////////////////////////////////////////////////////////////
/**
 * Returns shared instance of PTNStorageController
 */
+(PTNStorage*)sharedInstance;
/**
 * Returns shared instance of PTNStorageController initialized with 
 * specified defaults file
 */
+(PTNStorage*)sharedInstanceWithDefaultsFile:(NSString*)defaultFile;
/**
 * This method should be overriden by subclasses in order to return 
 * instance of appropriate class.
 *
 * @details If your derive your class EXStorageController from 
 * PTNStorage controller, you override createInstance like follows:
 * +(PTNStorage*)createInstance {
 *      return [[EXStorage alloc] init];
 * }
 * this ensures that call [PTNStorageController sharedInstance] will 
 * return instance of EXStorage. For convenience, you can create 
 * sharedInstance method in your EXStorage like follows:
 * +(EXStorage*)sharedInstance
 * {
 *      return (EXStorage*)[super sharedInstance];
 * }
 */
+(PTNStorage*)createInstance;
/**
 * Dictionary of default settings loaded from file
 */
- (void)registerDefaults;
/**
 * Registers user defaults settings read from specified file
 */
- (void)registerDefaultsFromFile:(NSString*)fileName;
/**
 * Save current settings to file on disk
 */
- (void)saveParams;
/**
 * Restire default values from file
 */
- (void)resetDefaults;

/**
 * Saves setting
 * @param param Setting value
 * @param key Setting name
 */
- (void)saveParam:(id)param forKey:(NSString*)key;
/**
 * Saves setting
 * @param param Setting value
 * @param keyPath Key path for the setting
 */
-(void)saveParam:(id)param forKeyPath:(NSString *)keyPath;
/**
 * Saves int value
 * @param param Setting value
 * @param key Setting name
 */
- (void)saveInt:(int)param forKey:(NSString*)key;
/**
 * Saves float value
 * @param param Setting value
 * @param key Setting name
 */
- (void)saveFloat:(float)param forKey:(NSString*)key;
/**
 * Saves boolean
 * @param param Setting value
 * @param key Setting name
 */
- (void)saveBool:(bool)param forKey:(NSString*)key;
/**
 * Returns saved setting
 * @param key Name of setting in settings dictionary
 */
- (id)getParamWithName:(NSString*)key;
/**
 * Returns saved setting
 * @param keyPath Path to the setting in settings dictionary
 */
- (id)getParamWithPath:(NSString*)keyPath;
/**
 * Returns saved boolean
 */
- (BOOL)getBoolWithName:(NSString*)key;
/**
 * Returns saved string
 */
- (NSString*)getStringWithName:(NSString*)key;

/**
 * Indicates whether application was ended normally or crahsed
 * It gets checked on storage intialization, if flag is set to NO, PTNStorageAppCrashedNotification gets generated. Otherwise, this flag is set to NO. Upon correct app termination this flag is set to YES.
 * @return YES means application ended normally, NO means application crashed
 */
-(BOOL)wasAppEndedNormally;
/**
 * Sets application end flag when ther was no crash
 */
-(void)setAppEndedNormally:(BOOL)terminationFlag;

@end

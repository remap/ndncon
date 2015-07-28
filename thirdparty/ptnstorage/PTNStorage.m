//
//  ivStorageController.m
//  ivClient
//
//  Created by peetonn on 13/07/2011.
//  Copyright 2011 peetonn inc. All rights reserved.
//

#import "PTNStorage.h"

#define PTN_STORAGE_PLISTKEY_FINISHED_NORMALLY @"Did finished normally"

static PTNStorage *sharedStorage = nil;

@interface PTNStorage ()

@end

@implementation PTNStorage

#pragma mark - properties
-(NSDictionary*)defaults
{
    NSString *fname = (_storageFile)?_storageFile:PTN_DEFAULT_PARAMS_FILE;
    NSString *pathForPlistFile = [[NSBundle bundleForClass:[self class]] pathForResource:fname ofType:@"plist"];
    NSDictionary *params = [NSDictionary dictionaryWithContentsOfFile:pathForPlistFile];

    return params;
}

#pragma mark - initialization and memory management
-(void)initialize
{
    _defaultParams = [NSUserDefaults standardUserDefaults];
}
-(id)init
{
    if ((self = [super init]))
    {
        [self initialize];
    }
    return self;
}
- (id)initWithStorageFile:(NSString *)fname
{
    if ((self = [super init]))
    {
        [self initialize];
        if (fname)
            _storageFile = [fname copy];
        
        [self registerDefaults];    
    }
    return self;
}

#pragma mark - public methods
+(PTNStorage*)sharedInstance
{
    static PTNStorage *singleton = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [[self class] createInstance];
    });
    
    return singleton;
}
+(PTNStorage*)sharedInstanceWithDefaultsFile:(NSString *)defaultFile
{
    [self sharedInstance]->_storageFile = [defaultFile copy];
    [[self sharedInstance] registerDefaults];
    
    return [self sharedInstance];
}
+(PTNStorage*)createInstance
{
    return [[PTNStorage alloc] init];
}

// register application default parameters - saved in PTN_DEFAULT_PARAMS_FILE file
-(void)registerDefaults
{
    [self registerDefaultsFromFile:(_storageFile)?_storageFile:PTN_DEFAULT_PARAMS_FILE];
}
-(void)updateDefaults
{
    NSString *fileName = (_storageFile)?_storageFile:PTN_DEFAULT_PARAMS_FILE;
    NSString *pathForPlistFile = [[NSBundle bundleForClass:[self class]]
                                  pathForResource:fileName
                                  ofType:@"plist"];
    NSDictionary *params = [NSDictionary dictionaryWithContentsOfFile:pathForPlistFile];
    
    for (NSString *key in [params allKeys]){
        id parameter = [params objectForKey:key];
        NSDictionary *paramDictionary = [NSDictionary dictionaryWithObject:parameter
                                                                    forKey:key];
        if (![_defaultParams objectForKey:key])
            [_defaultParams registerDefaults:paramDictionary];
        else
        {
            id defaultParam = [_defaultParams objectForKey:key];
            
            if ([defaultParam isKindOfClass:[NSDictionary class]])
            {
                defaultParam = [PTNStorage populateDictionary:defaultParam
                              withMissingValuesFromDictionary:paramDictionary[key]];
                
                [_defaultParams removeObjectForKey:key];
                [_defaultParams registerDefaults:@{key:defaultParam}];
            }
        }
    }
    
    [self saveParams];
}
-(void)registerDefaultsFromFile:(NSString *)fileName
{
    NSString *pathForPlistFile = [[NSBundle bundleForClass:[self class]]
                                  pathForResource:fileName
                                  ofType:@"plist"];
    NSDictionary *params = [NSDictionary dictionaryWithContentsOfFile:pathForPlistFile];
    
    for (NSString *key in [params allKeys]){
        id parameter = [params objectForKey:key];
        NSDictionary *paramDictionary = [NSDictionary dictionaryWithObject:parameter
                                                                    forKey:key];
        [_defaultParams registerDefaults:paramDictionary];
    } // for
}

// save plist data dictionary to defaults file
-(void)saveParams
{
    [_defaultParams synchronize];
}

// clear parameters to defaults
-(void)resetDefaults
{
    NSDictionary *params = self.defaults;
    
    // remove all
    [[_defaultParams dictionaryRepresentation].allKeys enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop){
        [_defaultParams removeObjectForKey:key];
    }];
    
    // load from file
    for (NSString *key in [params allKeys])
        [_defaultParams setObject:[params objectForKey:key] forKey:key];
    
    [self saveParams];
}

- (id)getParamWithName:(NSString*)key
{
    return [_defaultParams objectForKey:key];
}

-(id)getParamWithPath:(NSString *)keyPath
{
    return [_defaultParams valueForKeyPath:keyPath];
}

-(void)saveParam:(id)param forKeyPath:(NSString *)keyPath
{
    // we now must split keyPath into separate components and rewrite each
    // component as a dicitonary
    NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
    id tmp = [[_defaultParams objectForKey:[keyPathComponents objectAtIndex:0]] mutableCopy];
    NSMutableArray *dictionaries = [NSMutableArray array];
    
    for (int i = 1; i < [keyPathComponents count] && [tmp isKindOfClass:[NSMutableDictionary class]]; i++)
    {
        [dictionaries addObject:tmp];
        id obj = [tmp objectForKey:[keyPathComponents objectAtIndex:i]];
        
        if ([obj conformsToProtocol:@protocol(NSMutableCopying)])
            tmp = [obj mutableCopy];
        else
            tmp = obj;
    }
    
    if ([dictionaries count])
    {
        for (int i = 1; i < [dictionaries count]; i++)
        {
            NSMutableDictionary *outerDict = [dictionaries objectAtIndex:i-1];
            NSMutableDictionary *innerDict = [dictionaries objectAtIndex:i];
            id innerDictKey = [keyPathComponents objectAtIndex:i];
            
            [outerDict setObject:innerDict forKey:innerDictKey];
        }
        
        [[dictionaries lastObject] setValue:param forKeyPath:[keyPathComponents lastObject]];
        
        [self saveParam:[dictionaries firstObject] forKey:[keyPathComponents firstObject]];
    }
    else
        [self saveParam:param forKey:[keyPathComponents firstObject]];
}

-(BOOL)getBoolWithName:(NSString *)key
{
    return [(NSNumber*)[self getParamWithName:key] boolValue];
}

-(NSString*)getStringWithName:(NSString *)key
{
    return (NSString*)[self getParamWithName:key];
}

-(void)saveParam:(id)param forKey:(NSString *)key
{
    [_defaultParams setObject:param forKey:key];
    [self saveParams];
}

- (void)saveInt:(int)param forKey:(NSString*)key
{
    [_defaultParams setInteger:param forKey:key];
    [self saveParams];
}

- (void)saveFloat:(float)param forKey:(NSString*)key
{
    [_defaultParams setFloat:param forKey:key];
    [self saveParams];
}

- (void)saveBool:(bool)param forKey:(NSString*)key
{
    [_defaultParams setBool:param forKey:key];
    [self saveParams];
}

-(BOOL)wasAppEndedNormally
{
    return [[self getParamWithName:PTN_STORAGE_PLISTKEY_FINISHED_NORMALLY] intValue];
}
-(void)setAppEndedNormally:(BOOL)terminationFlag
{
    [self saveBool:terminationFlag forKey:PTN_STORAGE_PLISTKEY_FINISHED_NORMALLY];
}

#pragma mark - private methods
+(NSDictionary*)populateDictionary:(NSDictionary*)dictFirst withMissingValuesFromDictionary:(NSDictionary*)dictSecond
{
    NSMutableDictionary *mutableFirst = [NSMutableDictionary dictionaryWithDictionary:dictSecond];
    
    for (id key in mutableFirst.allKeys)
    {
        if (dictFirst[key])
        {
            if ([dictFirst[key] isKindOfClass:[NSDictionary class]])
                mutableFirst[key] = [PTNStorage populateDictionary:dictFirst[key]
                                   withMissingValuesFromDictionary:mutableFirst[key]];
            else
                mutableFirst[key] = dictFirst[key];
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:mutableFirst];
}

@end

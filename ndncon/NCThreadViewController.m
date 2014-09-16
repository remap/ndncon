//
//  NCThreadViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/12/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCThreadViewController.h"
#import "NSObject+NCAdditions.h"

NSString* const kBitrateKey = @"Start bitrate";

@interface NCThreadViewController ()
{
    NSString *_threadName;
}

@end

@implementation NCThreadViewController

+(NSDictionary*)defaultConfiguration
{
    return nil;
}

-(id)initWithStream:(NCStreamViewController *)streamVc andName:(NSString *)threadName
{
    self = [self init];
    
    if (self)
    {
        self.stream = streamVc;
        _threadName = threadName;
    }
    
    return self;
}

-(void)dealloc
{
    [self stopObservingSelf];
}

-(void)awakeFromNib
{
    [self startObservingSelf];
}

-(NSString *)threadName
{
    return _threadName;
}

-(void)setThreadName:(NSString *)threadName
{
    [self.configuration setValue:threadName forKey:kNameKey];
    _threadName = threadName;
}

-(NSMutableDictionary *)configuration
{
    return [self getConfigurationFromStream];
}

-(void)startObservingSelf
{
    [self addObserver:self forKeyPaths:
     KEYPATH2(configuration, kNameKey),
     KEYPATH2(configuration, kBitrateKey),
     nil];
}

-(void)stopObservingSelf
{
    [self removeObserver:self forKeyPaths:
     KEYPATH2(configuration, kNameKey),
     KEYPATH2(configuration, kBitrateKey),
     nil];
}

// KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self == object)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(configurationDidChangeForObject:atKeyPath:change:)])
            [self.delegate configurationDidChangeForObject:self atKeyPath:keyPath change:change];
    }
}

// private
-(NSMutableDictionary*)getConfigurationFromStream
{
    NSArray *streamThreads = [self.stream.configuration valueForKeyPath:kThreadsArrayKey];
    
    for (NSMutableDictionary *threadDict in streamThreads)
    {
        if ([[threadDict objectForKey:kNameKey] isEqualToString:_threadName])
            return threadDict;
    }
    
    return nil;
}


@end

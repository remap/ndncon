//
//  NCReporter.m
//  NdnCon
//
//  Created by Peter Gusev on 3/13/15.
//  Copyright 2013-2015 Regents of the University of California
//

#import "NCReporter.h"
#import "NCPreferencesController.h"
#import "FTPManager.h"
#import "NSTimer+NCAdditions.h"

NSString* const kNCReportTimestampKey = @"time";
NSString* const kNCReportDataKey = @"report";
NSString* const kNCReportsServer = @"131.179.141.51";
NSString* const kNCReportsFolder = @"NdnCon-Reports";

@interface NCReporter ()

@property (nonatomic) NSMutableArray *reports;
@property (nonatomic) NSMutableArray *postponedReports;
@property (nonatomic) FMServer *ftpServer;
@property (nonatomic) FTPManager *ftpManager;
@property (nonatomic) NSTimer *timer;

@end

@implementation NCReporter

+(NCReporter *)sharedInstance
{
    return (NCReporter*)[super sharedInstance];
}

+(PTNSingleton *)createInstance
{
    return [[NCReporter alloc] init];
}

+(dispatch_once_t*)token
{
    static dispatch_once_t token;
    return &token;
}

#pragma mark - public
-(instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _reports = [[NSMutableArray alloc] init];
        _postponedReports = [[NSMutableArray alloc] init];
        _ftpServer = [FMServer serverWithDestination:kNCReportsServer
                                            username:@"ndnconftp"
                                            password:@"ndncon2015"];
        _ftpManager = [[FTPManager alloc] init];
        _ftpManager.delegate = self;
    }
    
    return self;
}

-(void)addStatReport:(NSString *)statReport
{
    [self.reports addObject:@{kNCReportTimestampKey:[NSDate date],
                              kNCReportDataKey:statReport}];
}

-(void)flush
{
    [self.reports removeAllObjects];
}

-(void)submit
{
    if ([NCPreferencesController sharedInstance].isReportingAllowed)
    {
        NSLog(@"submitting reports...");
        [self submitReports:self.reports];
    }
    else if (![NCPreferencesController sharedInstance].isReportingAsked)
    {
        [self askForReporting];
        [self.postponedReports addObjectsFromArray:self.reports];
    }
    
    [self flush];
}

#pragma mark = FTPManagerDelegate
-(void)ftpManagerDownloadProgressDidChange:(NSDictionary *)processInfo
{
    NSLog(@"ftp upload progress changed: %@", processInfo);
}

#pragma mark - private
-(void)askForReporting
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Statistics reporting"
                                     defaultButton:@"Yes"
                                   alternateButton:@"No"
                                       otherButton:nil
                         informativeTextWithFormat:@"Would you like to enable automatic log reporting after each call session?\nThese logs help us make NdnCon better!"];
    alert.showsSuppressionButton = YES;
    [alert.suppressionButton setTitle:@"Do not ask again"];
    [alert beginSheetModalForWindow:[NSApp mainWindow]
                  completionHandler:^(NSModalResponse returnCode) {
                      if (alert.suppressionButton.state == 1)
                          [NCPreferencesController sharedInstance].isReportingAsked = YES;
                      
                      if (returnCode == NSModalResponseOK)
                      {
                          [NCPreferencesController sharedInstance].isReportingAsked = YES;
                          [NCPreferencesController sharedInstance].isReportingAllowed = YES;
                          [self submitReports:self.postponedReports];
                          
                      }
                  }];
}

-(void)submitReports:(NSArray*)reports
{
#if 0
    NSMutableString *summary = [NSMutableString stringWithString:@""];
    
    for (NSDictionary *report in reports) {
        NSDate *timestamp = report[kNCReportTimestampKey];
        NSString *reportData = report[kNCReportDataKey];
        
        [summary appendFormat:@"*** %@", timestamp];
        [summary appendFormat:@"%@\n", reportData];
    }
    
    if (![summary isEqualToString:@""])
    {

        NSString *uploadFolder = [kNCReportsFolder stringByAppendingPathComponent: [NSString stringWithFormat:@"%@-%ld",
                                                                                 [NCPreferencesController sharedInstance].userName,
                                                                                 (long)[NSDate date].timeIntervalSince1970]];
        BOOL res = NO;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                     repeats:NO
                                                   fireBlock:^(NSTimer *timer) {
                                                       NSLog(@"here's your timer");
        }];
        
        res = [self.ftpManager createNewFolder:uploadFolder
                                           atServer:self.ftpServer];
        
        if (res)
        {
            self.ftpServer.destination = [kNCReportsServer stringByAppendingPathComponent: uploadFolder];
            
            for (NSDictionary *report in reports)
            {
                NSURL *reportURL = [NSURL URLWithString:report[kNCReportDataKey]];
                
                if ([self.ftpManager uploadFile:reportURL toServer:self.ftpServer])
                    NSLog(@"start uploading %@...", reportURL);
            }
        }
    }
#endif
}

@end

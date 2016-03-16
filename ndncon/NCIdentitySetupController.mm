//
//  NCIdentitySetupController.m
//  NdnCon
//
//  Created by Peter Gusev on 3/15/16.
//  Copyright © 2016 REMAP. All rights reserved.
//

#include <ndn-cpp/security/key-chain.hpp>

#import "NCIdentitySetupController.h"
#import "NCFaceSingleton.h"
#import "NSTimer+NCAdditions.h"
#import "NCErrorController.h"
#import "NSDate+NCAdditions.h"

typedef void (^NCProgressBlock)(NSString*);

using namespace ndn;
using namespace std;
using namespace boost;

@interface NCIdentitySetupController ()

@property (nonatomic) BOOL isSetupCompleted;

@property (nonatomic) NSTimer *fetchTimer;
@property (nonatomic) NSArray *identities;
@property (nonatomic) NSString *selectedIdentity;

@property (weak) IBOutlet NSPopUpButton *dropDownList;
@property (weak) IBOutlet NSButton *useIdentityButton;
@property (weak) IBOutlet NSTextField *progressLabel;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *descriptionLabel;
@property (weak) IBOutlet NSTextField *infoLabel;

@end

//******************************************************************************
@implementation NCIdentitySetupController

-(instancetype)init
{
    self = [super initWithWindowNibName:@"IdentitySetupWindow"];
    
    __weak NCIdentitySetupController *weakSelf = self;
    self.fetchTimer = [NSTimer scheduledTimerWithTimeInterval:3.
                                                      repeats:YES
                                                    fireBlock:^(NSTimer *timer) {
                                                        [weakSelf fetchIdentities];
                                                    }];
    [self fetchIdentities];
    self.isSetupCompleted = NO;
    
    return self;
}

-(void)fetchIdentities
{
    KeyChain* keyChain = [[NCFaceSingleton sharedInstance] getKeyChain];
    vector<Name> identities;
    
    keyChain->getIdentityManager()->getAllIdentities(identities, true);
    keyChain->getIdentityManager()->getAllIdentities(identities, false);
    
    NSMutableArray *identitiesArray = [[NSMutableArray alloc] init];
    
    for (auto i:identities)
        [identitiesArray addObject: [NSString stringWithCString:i.toUri().c_str() encoding:NSASCIIStringEncoding]];
    
    self.identities = [NSArray arrayWithArray: identitiesArray];

    if (!self.selectedIdentity)
        self.selectedIdentity = self.identities[0];
}

- (IBAction)setupIdentity:(id)sender
{
    if (!self.isSetupCompleted)
    {
        self.dropDownList.hidden = YES;
        self.useIdentityButton.enabled = NO;
        self.progressLabel.hidden = NO;
        [self.progressIndicator startAnimation:nil];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^(){
            [self setupIdentityWithProgressCallback:^(NSString *textHint){
                dispatch_async(dispatch_get_main_queue(), ^(){
                    [self.progressLabel setStringValue: textHint];
                });
            }];
        });
    }
    else
    {
        [self continueSetup];
    }
}

-(void)setupIdentityWithProgressCallback:(NCProgressBlock)progressCallback
{
    try
    {
        progressCallback(@"Creating ndncon identity...");
        
        Name signingIdentity = Name([self.selectedIdentity cStringUsingEncoding:NSASCIIStringEncoding]);
        Name ndnconIdentity(signingIdentity);
        
        if (signingIdentity[-1] != "ndncon")
        {
            ndnconIdentity.append("ndncon");
            
            progressCallback(@"Creating ndncon certificate...");
            KeyChain* keyChain = [[NCFaceSingleton sharedInstance] getKeyChain];
            
            progressCallback(@"Generating new key pair...");
            Name ndnconKeyName = keyChain->generateRSAKeyPairAsDefault(ndnconIdentity);
            Name signingCertName = keyChain->getIdentityManager()->getDefaultCertificateNameForIdentity(signingIdentity);
            
            progressCallback(@"Creating ndncon certificate...");
            vector<CertificateSubjectDescription> subjectDescriptions;
            NSDate *now = [NSDate date];
            shared_ptr<IdentityCertificate> ndnconCert =
            keyChain->getIdentityManager()->prepareUnsignedIdentityCertificate(ndnconKeyName, signingIdentity,
                                                                               [now timeIntervalSince1970]*1000,
                                                                               [[now dateByAddingYears:3] timeIntervalSince1970]*1000,
                                                                               subjectDescriptions);
            
            
            progressCallback(@"Signing ndncon certificate...");
            keyChain->sign(*ndnconCert, signingCertName);
            
            progressCallback(@"Installing ndncon certificate...");
            keyChain->installIdentityCertificate(*ndnconCert);
            keyChain->setDefaultCertificateForKey(*ndnconCert);
            
            progressCallback(@"ndncon identity setup succesfully completed");
        }
        else
        {
#warning implement some verification algorithm for the chosen identity
        }
        
        [self setupCompleted];
    }
    catch(std::runtime_error &e)
    {
        progressCallback([NSString stringWithFormat:@"Setup failed: %@",
                          [NSString stringWithCString:e.what()
                                             encoding:NSASCIIStringEncoding]]);
        [self setupFailed];
        [[NCErrorController sharedInstance] postErrorWithMessage:[NSString stringWithFormat:@"Identity setup failed: %@",
                                                                  [NSString stringWithCString:e.what()
                                                                                     encoding:NSASCIIStringEncoding]]];
    }
}

-(void)setupCompleted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.useIdentityButton.enabled = YES;
        [self.useIdentityButton setTitle:@"Continue"];
        [self.progressIndicator stopAnimation:nil];
        self.progressLabel.hidden = YES;
        self.descriptionLabel.hidden = YES;
        [self.infoLabel setStringValue:@"Your ndncon identity set up completed successfully!"];
        
        self.isSetupCompleted = YES;
        [self.fetchTimer invalidate];
    });
}

-(void)setupFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dropDownList.hidden = NO;
        self.useIdentityButton.enabled = YES;
        self.progressLabel.hidden = YES;
        [self.progressIndicator stopAnimation:nil];
    });
}

-(void)continueSetup
{
    // check for discoverability
    [self.delegate identitySetupCompletedWithIdentity: self.selectedIdentity];
}

@end

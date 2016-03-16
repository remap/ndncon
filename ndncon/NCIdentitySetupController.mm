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

typedef void (^NCProgressBlock)(NSString*);

using namespace ndn;
using namespace std;
using namespace boost;

@interface NCIdentitySetupController ()

@property (nonatomic) BOOL setupCompleted;

@property (nonatomic) NSTimer *fetchTimer;
@property (nonatomic) NSArray *identities;
@property (nonatomic) NSString *selectedIdentity;

@property (weak) IBOutlet NSPopUpButton *dropDownList;
@property (weak) IBOutlet NSButton *useIdentityButton;
@property (weak) IBOutlet NSTextField *progressLabel;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

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
    self.setupCompleted = NO;
    
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

-(void)setupIdentityWithProgressCallback:(NCProgressBlock)progressCallback
{
    if (self.setupCompleted)
    {
        
    }
    else
    {
        try
        {
            progressCallback(@"Creating ndncon identity...");
            
            Name signingIdentity = Name([self.selectedIdentity cStringUsingEncoding:NSASCIIStringEncoding]);
            Name ndnconIdentity(signingIdentity);
            
            ndnconIdentity.append("ndncon");
            
            progressCallback(@"Creating ndncon certificate...");
            //        KeyChain* keyChain = [[NCFaceSingleton sharedInstance] getKeyChain];
            
            progressCallback(@"Generating new key pair...");
            sleep(1);
            //        Name ndnconKeyName = keyChain->generateRSAKeyPairAsDefault(ndnconIdentity);
            //        Name signingCertName = keyChain->getIdentityManager()->getDefaultCertificateNameForIdentity(signingIdentity);
            //        shared_ptr<IdentityCertificate> signingCert = keyChain->getIdentityManager()->getCertificate(signingCertName);
            //        std::vector<CertificateSubjectDescription> subjectDescriptions;
            //        shared_ptr<IdentityCertificate> ndnconCert =
            //            keyChain->getIdentityManager()->prepareUnsignedIdentityCertificate(ndnconKeyName, signingIdentity,
            //                                                                           signingCert->getNotBefore(),
            //                                                                           signingCert->getNotAfter(),
            //                                                                           subjectDescriptions);
            
            
            progressCallback(@"Signing ndncon certificate...");
            //        keyChain->sign(*ndnconCert, signingCertName);
            sleep(0.5);
            progressCallback(@"Installing ndncon certificate...");
            //        keyChain->installIdentityCertificate(*ndnconCert);
            //        keyChain->setDefaultCertificateForKey(*ndnconCert);
            sleep(1);
            progressCallback(@"ndncon identity setup succesfully completed");
            [self setupCompleted];
        }
        catch(std::runtime_error &e)
        {
            progressCallback([NSString stringWithFormat:@"Setup failed: %@",
                              [NSString stringWithCString:e.what()
                                                 encoding:NSASCIIStringEncoding]]);
            [self setupFailed];
        }
    }
}

-(void)setupCompleted
{
    self.useIdentityButton.enabled = YES;
    [self.useIdentityButton setTitle:@"Continue"];
    [self.progressIndicator stopAnimation:nil];
    
    self.setupCompleted = YES;
    [self.fetchTimer invalidate];
}

-(void)setupFailed
{
    self.dropDownList.hidden = NO;
    self.useIdentityButton.enabled = YES;
    self.progressLabel.hidden = YES;
    [self.progressIndicator stopAnimation:nil];
}

@end

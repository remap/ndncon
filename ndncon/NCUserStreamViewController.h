//
//  NCUserStreamViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamViewController.h"
#import "NCThreadViewController.h"

@interface NCUserStreamViewController : NCStreamViewController

@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *userPrefix;

@end


@interface NCVideoUserStreamViewController : NCUserStreamViewController

@end

@interface NCAudioUserStreamViewController : NCUserStreamViewController

@end

@interface NCUserThreadViewController : NCThreadViewController

@end

@interface NCVideoUserThreadViewController : NCUserThreadViewController

@end

@interface NCAudioUserThreadViewController : NCUserThreadViewController

@end
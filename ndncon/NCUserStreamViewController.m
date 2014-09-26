//
//  NCUserStreamViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCUserStreamViewController.h"

@implementation NCUserStreamViewController

@end

@implementation NCVideoUserStreamViewController

-(id)init
{
    self = [super initWithNibName:@"NCUserVideoStreamView" bundle:nil];
    return self;
}

-(Class)threadViewControllerClass
{
    return [NCVideoUserThreadViewController class];
}

@end


@implementation NCAudioUserStreamViewController

-(id)init
{
    self = [super initWithNibName:@"NCUserAudioStreamView" bundle:nil];
    return self;
}

-(Class)threadViewControllerClass
{
    return [NCAudioUserThreadViewController class];
}

@end

@implementation  NCUserThreadViewController

@end

@implementation NCVideoUserThreadViewController

-(id)init
{
    self = [super initWithNibName:@"NCUserVideoThreadView" bundle:nil];
    return self;
}

@end

@implementation NCAudioUserThreadViewController

-(id)init
{
    self = [super initWithNibName:@"NCUserAudioThreadView" bundle:nil];
    return self;
}

@end
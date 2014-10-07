//
//  main.m
//  NdnCon
//
//  Created by Peter Gusev on 9/8/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[])
{
    int retVal = 0;
    
    @try
    {
        retVal = NSApplicationMain(argc, argv);
    }
    @catch (NSException *ex)
    {
        NSLog(@"Caught exception: %@ (description: %@) with callstack: \n%@",
                  [ex name], [ex description], [ex callStackSymbols]);
        
        // continue with system-wide exception handling
        @throw ex;
    }
    
    return retVal;
}

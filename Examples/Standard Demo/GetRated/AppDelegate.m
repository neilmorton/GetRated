//
//  AppDelegate.m
//  GetRated
//
//  Created by Neil Morton on 11/14/2017.
//  Copyright (c) 2017 Neil Morton. All rights reserved.
//

#import "AppDelegate.h"
#import <GetRated/getRated.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /* _optional_ */
    //enable preview mode - *** FOR TESTING ONLY ***
    [getRated sharedInstance].previewMode = YES;
    
    /* _required_ */
    //start GetRated - should be called AFTER any optional configuration options (above)
    [[getRated sharedInstance] start];
    
    return YES;
}

@end

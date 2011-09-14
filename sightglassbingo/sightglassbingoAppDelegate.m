//
//  sightglassbingoAppDelegate.m
//  sightglassbingo
//
//  Created by David Kasper on 8/22/11.
//  Copyright 2011 Yobongo. All rights reserved.
//

#import "sightglassbingoAppDelegate.h"

@implementation sightglassbingoAppDelegate


@synthesize window=_window, facebook;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    rootViewController = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:nil];
    rootViewController.view.frame = [[UIScreen mainScreen] bounds];
    [self.window addSubview:rootViewController.view];
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
    
    facebook = [[Facebook alloc] initWithAppId:@"273948095949056" andDelegate:self];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"] 
        && [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    return [facebook handleOpenURL:url]; 
}

- (void)fbDidLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    [rootViewController facebookShare];
}

-(void)fbDidLogout {
    NSLog(@"logged out");
}

-(void)fbDidNotLogin:(BOOL)cancelled {
    NSLog(@"did not login");
    [rootViewController showWonAlert];
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

@end

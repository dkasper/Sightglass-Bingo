//
//  sightglassbingoAppDelegate.h
//  sightglassbingo
//
//  Created by David Kasper on 8/22/11.
//  Copyright 2011 Yobongo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import "RootViewController.h"

@interface sightglassbingoAppDelegate : NSObject <UIApplicationDelegate, FBSessionDelegate> {
    RootViewController *rootViewController;
    Facebook *facebook;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) Facebook *facebook;

@end

//
//  RootViewController.h
//  sightglassbingo
//
//  Created by David Kasper on 8/22/11.
//  Copyright 2011 Yobongo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"

@interface RootViewController : UIViewController<FBDialogDelegate> {
    NSMutableArray *buttons;
    NSString *winShareText;
}

@property (nonatomic, retain) NSMutableArray *buttons;

@end

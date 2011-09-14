//
//  GameSquare.h
//  sightglassbingo
//
//  Created by David Kasper on 8/22/11.
//  Copyright 2011 Yobongo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GameSquare : UIView {
    UIButton *button;
    UIImageView *chip;
    BOOL selected;
    NSInteger x,y;
    NSString *text;
    id delegate;
}

-(id)initWithFrame:(CGRect)frame withX:(NSInteger)xVal withY:(NSInteger)yVal;

@property (assign) BOOL selected;
@property (nonatomic, retain) UIButton *button;
@property (nonatomic, retain) UIImageView *chip;
@property (nonatomic, retain) NSString *text;
@property (assign) NSInteger x,y;
@property id delegate;

@end

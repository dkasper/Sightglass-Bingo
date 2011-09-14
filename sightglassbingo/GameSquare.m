//
//  GameSquare.m
//  sightglassbingo
//
//  Created by David Kasper on 8/22/11.
//  Copyright 2011 Yobongo. All rights reserved.
//

#import "GameSquare.h"


@implementation GameSquare

@synthesize button, x, y, chip, delegate;

-(id)initWithFrame:(CGRect)frame withX:(NSInteger)xVal withY:(NSInteger)yVal {
    self = [super initWithFrame:frame];
    if(self) {
        self.x = xVal;
        self.y = yVal;
        
        self.chip = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width / 2 - 20, self.bounds.size.height / 2 - 20, 40, 40)];
        chip.image = [UIImage imageNamed:@"red_chip.png"];
        chip.hidden = YES;
        
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        button.titleLabel.numberOfLines = 0;
        button.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
        button.titleLabel.textAlignment = UITextAlignmentCenter;
        button.titleEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
        [button setTitle:text forState:UIControlStateNormal];
        [button addTarget:self action:@selector(toggleSelected:) forControlEvents:UIControlEventTouchUpInside];
        button.frame = self.bounds;
        [self addSubview:button];
        
        [self addSubview:chip];
        
        selected = NO;
    }
    return self;
}

-(void)toggleSelected:(id)sender {
    self.selected = !selected;
    if(selected && [delegate respondsToSelector:@selector(checkWin:)]) {
        [delegate checkWin:sender];
    }
}

-(BOOL)selected {
    return selected;
}

-(void)setSelected:(BOOL)val {
    selected = val;
    chip.hidden = !val;
}

-(void)setText:(NSString *)t {
    text = [t retain];
    [button setTitle:text forState:UIControlStateNormal];
}

-(NSString *)text {
    return text;
}

@end

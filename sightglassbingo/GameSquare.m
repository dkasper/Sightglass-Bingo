//
//  GameSquare.m
//  sightglassbingo
//
//  Created by David Kasper on 8/22/11.
//  Copyright 2011 David Kasper. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of
//  conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list
//  of conditions and the following disclaimer in the documentation and/or other materials
//  provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY David Kasper ''AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL David Kasper OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//                       SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//                                                                         NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of David Kasper.


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

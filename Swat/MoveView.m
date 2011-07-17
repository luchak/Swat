//
//  MyClass.m
//  SimpleGestureRecognizers
//
//  Created by Gabriel Adauto on 7/17/11.
//  Copyright 2011 Motion Math, Inc. All rights reserved.
//

#import "MoveView.h"


@implementation MoveView

@synthesize dx, dy;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) doMove {
	self.center = CGPointMake(self.center.x + dx, self.center.y + dy);
}

- (void)dealloc
{
    [super dealloc];
}

@end

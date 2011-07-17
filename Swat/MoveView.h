//
//  MyClass.h
//  SimpleGestureRecognizers
//
//  Created by Gabriel Adauto on 7/17/11.
//  Copyright 2011 Motion Math, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MoveView : UIView {
    
}

@property int dx;
@property int dy;

- (void) doMove;

@end

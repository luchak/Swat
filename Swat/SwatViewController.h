//
//  SwatViewController.h
//  Swat
//
//  Created by Matt Stanton on 7/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MoveView.h"


#define CREATION_INTERVAL		1.1
#define MIN_SIZE				50
#define MAX_SIZE				100
#define SCREEN_CROSSING_TIME	6.0
#define STEP_INTERVAL			0.085



@class AVCamCaptureManager;
@class AVCaptureVideoPreviewLayer;
@class FrameProcessor;

@interface SwatViewController : UIViewController {
    
	CGFloat DX, DY;
}

@property (nonatomic, retain) NSMutableArray *views;

- (void) catchMovement:(NSNotification *)notification;
- (void) createRandomlyEnteringUIView:(NSTimer *)timer;
- (void) movementTimer:(NSTimer *)timer;
- (void) viewAnimationDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context;


@property (nonatomic,retain) AVCamCaptureManager *captureManager;
@property (nonatomic,retain) IBOutlet UIView *videoPreviewView;
@property (nonatomic,retain) UIImageView *imageView;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic,retain) FrameProcessor *frameProcessor;

@end

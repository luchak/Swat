//
//  SwatViewController.h
//  Swat
//
//  Created by Matt Stanton on 7/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCamCaptureManager;
@class AVCaptureVideoPreviewLayer;
@class FrameProcessor;

@interface SwatViewController : UIViewController {
    
}

@property (nonatomic,retain) AVCamCaptureManager *captureManager;
@property (nonatomic,retain) IBOutlet UIView *videoPreviewView;
@property (nonatomic,retain) UIImageView *imageView;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic,retain) FrameProcessor *frameProcessor;

@end

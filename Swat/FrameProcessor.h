//
//  FrameProcessor.h
//  Swat
//
//  Created by Matt Stanton on 7/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <AVFoundation/AVFoundation.h>

@protocol FrameProcessorDelegate;

@interface FrameProcessor : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
    float left_accum;
    float right_accum;
    float total_accum;
    int suppress_counter;
}

@property (nonatomic,retain) UIImage *frameImage;
@property (nonatomic,retain) UIImage *oldTrackImage;
@property (nonatomic,retain) UIImage *newTrackImage;
@property (nonatomic,assign) id <FrameProcessorDelegate> delegate;

@end

@protocol FrameProcessorDelegate
@optional
- (void) frameImageDidChange:(UIImage *) image;
@end

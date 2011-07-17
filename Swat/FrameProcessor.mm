//
//  FrameProcessor.m
//  Swat
//
//  Created by Matt Stanton on 7/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FrameProcessor.h"

#import <algorithm>

@interface FrameProcessor (InternalMethods)
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (UIImage *) scaledAndRotatedImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (UIImage *) UIImageFromIplImage:(IplImage *)image;
- (UIImage *) opencvEdgeDetect:(UIImage *) uiImage;
- (UIImage *) drawOpticalFlowVectorsForOldImage:(UIImage *)oldImage newImage:(UIImage *)newImage;
@end

@implementation FrameProcessor

@synthesize frameImage;
@synthesize oldTrackImage;
@synthesize newTrackImage;
@synthesize delegate;

- (void) dealloc
{
    [frameImage release];
    [oldTrackImage release];
    [newTrackImage release];
    [super dealloc];
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput
         didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
         fromConnection:(AVCaptureConnection *)connection {
    [self setOldTrackImage:newTrackImage];
    UIImage* scaled_image = [self scaledAndRotatedImageFromSampleBuffer:sampleBuffer];
    [self setNewTrackImage:scaled_image];
    if (oldTrackImage && newTrackImage) {
        [self setFrameImage:[self drawOpticalFlowVectorsForOldImage:oldTrackImage newImage:newTrackImage]];
        [delegate frameImageDidChange:frameImage];
    }
}

@end

@implementation FrameProcessor (InternalMethods)

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer.
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    // Get the number of bytes per row for the pixel buffer.
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height.
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space.
    static CGColorSpaceRef colorSpace = NULL;
    if (colorSpace == NULL) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace == NULL) {
            // Handle the error appropriately.
            return nil;
        }
    }
    
    // Get the base address of the pixel buffer.
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    // Create a Quartz direct-access data provider that uses data we supply.
    CGDataProviderRef dataProvider =
    CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    // Create a bitmap image from data supplied by the data provider.
    CGImageRef cgImage =
    CGImageCreate(width, height, 8, 32, bytesPerRow,
                  colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                  dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    // Create and return an image object to represent the Quartz image.
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
}

- (UIImage *)scaledAndRotatedImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer.
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    // Get the number of bytes per row for the pixel buffer.
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height.
    size_t cv_width = CVPixelBufferGetWidth(imageBuffer);
    size_t cv_height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space.
    static CGColorSpaceRef colorSpace = NULL;
    if (colorSpace == NULL) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace == NULL) {
            // Handle the error appropriately.
            return nil;
        }
    }
    
    // Get the base address of the pixel buffer.
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    // Create a Quartz direct-access data provider that uses data we supply.
    CGDataProviderRef dataProvider =
    CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    // Create a bitmap image from data supplied by the data provider.
    CGImageRef cgImage =
    CGImageCreate(cv_width, cv_height, 8, 32, bytesPerRow,
                  colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                  dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    static int kMaxResolution = 160;
	
    CGFloat width = CGImageGetWidth(cgImage);
	CGFloat height = CGImageGetHeight(cgImage);
    CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width > kMaxResolution || height > kMaxResolution) {
		CGFloat ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = kMaxResolution;
			bounds.size.height = bounds.size.width / ratio;
		} else {
			bounds.size.height = kMaxResolution;
			bounds.size.width = bounds.size.height * ratio;
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	CGSize imageSize = CGSizeMake(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
	CGFloat boundHeight = bounds.size.height;
    bounds.size.height = bounds.size.width;
    bounds.size.width = boundHeight;
    transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
    transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
	
	UIGraphicsBeginImageContext(bounds.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
    //CGContextScaleCTM(context, -scaleRatio, scaleRatio);
    //CGContextTranslateCTM(context, -height, 0);
    CGContextScaleCTM(context, scaleRatio, -scaleRatio);
    CGContextTranslateCTM(context, 0, -height);
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), cgImage);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
    CGImageRelease(cgImage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
	return imageCopy;

}

// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
    // Getting CGImage from UIImage
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Creating temporal IplImage for drawing
    IplImage *iplimage = cvCreateImage(
                                       cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4
                                       );
    // Creating CGContext for temporal IplImage
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // Drawing CGImage to CGContext
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // Creating result IplImage
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

// NOTE You should convert color mode as RGB before passing to this function
- (UIImage *)UIImageFromIplImage:(IplImage *)image {
	//NSLog(@"IplImage (%d, %d) %d bits by %d channels, %d bytes/row %s", image->width, image->height, image->depth, image->nChannels, image->widthStep, image->channelSeq);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(image->width, image->height,
										image->depth, image->depth * image->nChannels, image->widthStep,
										colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
										provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *ret = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return ret;
}


- (UIImage *) opencvEdgeDetect:(UIImage *) uiImage {
	// NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    cvSetErrMode(CV_ErrModeParent);
    
    // Create grayscale IplImage from UIImage
    IplImage *img_color = [self CreateIplImageFromUIImage:uiImage];
    IplImage *img = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
    cvCvtColor(img_color, img, CV_BGR2GRAY);
    cvReleaseImage(&img_color);
    
    // Detect edge
    IplImage *img2 = cvCreateImage(cvGetSize(img), IPL_DEPTH_8U, 1);
    cvCanny(img, img2, 64, 128, 3);
    cvReleaseImage(&img);
    
    // Convert black and whilte to 24bit image then convert to UIImage to show
    IplImage *image = cvCreateImage(cvGetSize(img2), IPL_DEPTH_8U, 3);
    for(int y=0; y<img2->height; y++) {
        for(int x=0; x<img2->width; x++) {
            char *p = image->imageData + y * image->widthStep + x * 3;
            *p = *(p+1) = *(p+2) = img2->imageData[y * img2->widthStep + x];
        }
    }
    cvReleaseImage(&img2);
    uiImage = [self UIImageFromIplImage:image];
    cvReleaseImage(&image);

	// [pool release];
    
    return uiImage;
}

- (UIImage *) drawOpticalFlowVectorsForOldImage:(UIImage *)oldImage newImage:(UIImage *)newImage {
    IplImage *img_color = [self CreateIplImageFromUIImage:oldImage];
    IplImage *img_old = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
    cvCvtColor(img_color, img_old, CV_BGR2GRAY);
    cvReleaseImage(&img_color);
    
    img_color = [self CreateIplImageFromUIImage:newImage];
    IplImage *img_new = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
    cvCvtColor(img_color, img_new, CV_BGR2GRAY);
    
    CvSize image_size = cvGetSize(img_old);
    // Get the features for tracking
	IplImage* eig_image = cvCreateImage(image_size, IPL_DEPTH_32F, 1);
	IplImage* tmp_image = cvCreateImage(image_size, IPL_DEPTH_32F, 1);
    
    int MAX_CORNERS = 50;
	int corner_count = MAX_CORNERS;
	CvPoint2D32f* corners_old = new CvPoint2D32f[MAX_CORNERS];
    
    int win_size = 15;
	cvGoodFeaturesToTrack(img_old, eig_image, tmp_image, corners_old, &corner_count,
                          0.05, 5.0, 0, 3, 0, 0.01 );
    //cvFindCornerSubPix( img_old, corners_old, corner_count, cvSize( win_size, win_size ),
    //                   cvSize( -1, -1 ), cvTermCriteria( CV_TERMCRIT_ITER | CV_TERMCRIT_EPS, 20, 0.03 ) );
    
    //for (int i = 0; i < 10; ++i) {
    //    corners_old[i].x = 0.0;
    //    corners_old[i].y = image_size.height / 10.0;
    //    corners_old[10+i].x = image_size.width;
    //    corners_old[10+i].y = image_size.height / 10.0;
    //}
    
    char features_found[MAX_CORNERS];
	float feature_errors[MAX_CORNERS];
    
    CvSize pyr_sz = cvSize(img_old->width, img_new->height);
    
    IplImage* pyr_old = cvCreateImage( pyr_sz, IPL_DEPTH_32F, 1 );
	IplImage* pyr_new = cvCreateImage( pyr_sz, IPL_DEPTH_32F, 1 );
    
	CvPoint2D32f* corners_new = new CvPoint2D32f[ MAX_CORNERS ];
    
	cvCalcOpticalFlowPyrLK( img_old, img_new, pyr_old, pyr_new, corners_old, corners_new, corner_count, 
                           cvSize( win_size, win_size ), 5, features_found, feature_errors,
                           cvTermCriteria( CV_TERMCRIT_ITER | CV_TERMCRIT_EPS, 20, 0.3 ), 0 );
    
    for (int i = 0; i < corner_count; ++i) {
        if (features_found[i] == 0) {
            continue;
        }
        CvPoint p0 = cvPoint( cvRound( corners_old[i].x ), cvRound( corners_old[i].y ) );
		CvPoint p1 = cvPoint( cvRound( corners_new[i].x ), cvRound( corners_new[i].y ) );
		cvLine( img_color, p0, p1, CV_RGB(255,0,0), 2 );
    }
    
    IplImage *img_color_rgb = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 3);
    cvCvtColor(img_color, img_color_rgb, CV_BGR2RGB);
    UIImage* vectorImage = [self UIImageFromIplImage:img_color_rgb];

    cvReleaseImage(&img_color_rgb);
    cvReleaseImage(&img_color);
    cvReleaseImage(&eig_image);
    cvReleaseImage(&tmp_image);
    cvReleaseImage(&img_old);
    cvReleaseImage(&img_new);
    cvReleaseImage(&pyr_old);
    cvReleaseImage(&pyr_new);
    
    std::vector<float> dx(corner_count);
    for (int i = 0; i < corner_count; ++i) {
        dx[i] = corners_new[i].x - corners_old[i].x;
    }
    std::sort(dx.begin(), dx.end());
    
    float left = fabs(std::min(dx[0], 0.0f));
    float right = std::max(dx[dx.size() - 1], 0.0f);
    float net = -left + right;
    
    const int suppress_frames = 5;
    const float kGamma = 0.9;
    const float kThreshold = 1.0;
    const float kRatio = 2.0;
    float new_left_accum = left_accum * kGamma + left * (1.0 - kGamma);
    float new_right_accum = right_accum * kGamma + right * (1.0 - kGamma);
    float new_total_accum = total_accum * kGamma + net * (1.0 - kGamma);
    
    bool trig_left = false;
    bool trig_right = false;
    bool trig_total = false;
    if (suppress_counter == 0) {
        if (new_left_accum > kThreshold && left_accum <= kThreshold) {
            trig_left = true;
            new_left_accum = 0.0;
            suppress_counter = suppress_frames;
        }
        if (new_right_accum > kThreshold && right_accum <= kThreshold) {
            trig_right = true;
            new_right_accum = 0.0;
            suppress_counter = suppress_frames;
        }
        if (fabs(new_total_accum) > kThreshold && fabs(total_accum) <= kThreshold) {
            trig_total = true;
            new_total_accum = 0.0;
            suppress_counter = suppress_frames;
        }
    } else {
        suppress_counter -= 1;
    }
    
#if 0
    if (trig_left && (!trig_right || (new_left_accum > new_right_accum))) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SwatLeft" object:nil];
        NSLog(@"left!");
        NSLog(@"%f %f :: %f %f", left_accum, new_left_accum, right_accum, new_right_accum);
    } else if (trig_right && (!trig_left || (new_right_accum >= new_left_accum))) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SwatRight" object:nil];
        NSLog(@"right!");
        NSLog(@"%f %f :: %f %f", left_accum, new_left_accum, right_accum, new_right_accum);
    }
#endif
    if (trig_total && new_total_accum < 0.0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SwatLeft" object:nil];
        NSLog(@"left!");
        NSLog(@"%f %f", total_accum, new_total_accum);
    } else if (trig_total && new_total_accum > 0.0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SwatRight" object:nil];
        NSLog(@"right!");
        NSLog(@"%f %f", total_accum, new_total_accum);

    }
    
    left_accum = new_left_accum;
    right_accum = new_right_accum;
    
    delete[] corners_old;
    delete[] corners_new;
    
    return vectorImage;
}

@end

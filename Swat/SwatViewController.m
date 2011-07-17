//
//  SwatViewController.m
//  Swat
//
//  Created by Matt Stanton on 7/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SwatViewController.h"

#import "AVCamCaptureManager.h"
#import "FrameProcessor.h"

@interface SwatViewController (FrameProcessorDelegate) <FrameProcessorDelegate>
@end

@implementation SwatViewController

@synthesize captureManager;
@synthesize videoPreviewView;
@synthesize captureVideoPreviewLayer;
@synthesize frameProcessor;
@synthesize imageView;

- (void)dealloc
{
	[captureManager release];
    [videoPreviewView release];
	[captureVideoPreviewLayer release];
    [frameProcessor release];
    [imageView release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	if ([self captureManager] == nil) {
		AVCamCaptureManager *manager = [[AVCamCaptureManager alloc] init];
		[self setCaptureManager:manager];
		[manager release];
        
		if ([[self captureManager] setupSession]) {
            [self setFrameProcessor: [[FrameProcessor alloc] init]];
            [frameProcessor setDelegate:self];
            // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[[[self captureManager] session] startRunning];
			});
            
		}		
	}
    
    dispatch_queue_t queue = dispatch_queue_create("ImageProcessingQueue", NULL);
    [[captureManager videoDataOutput] setSampleBufferDelegate:frameProcessor queue:queue];
    dispatch_release(queue);
    
    [self setImageView: [[UIImageView alloc] initWithFrame: [self.view bounds]]];
    [self.view addSubview:imageView];
    
    
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

@implementation SwatViewController (FrameProcessorDelegate)

- (void) frameImageDidChange:(UIImage *) image
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [imageView setImage: image];
    });
}

@end

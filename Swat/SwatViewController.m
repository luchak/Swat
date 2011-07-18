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
@synthesize views;

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
    
    // OLD view
//    [self setImageView: [[UIImageView alloc] initWithFrame: [self.view bounds]]];
//    [self.view addSubview:imageView];
	
	
	self.views = [NSMutableArray array];
    
	
	// COMMENT THIS STUFF OUT IF YOU WANT TO SEE THE UNDER-THE-COVERS VIEW
	CGFloat timeMod = STEP_INTERVAL;
	DX = ([UIScreen mainScreen].bounds.size.width + 2.0 * MAX_SIZE) * timeMod * .1;
	DY = ([UIScreen mainScreen].bounds.size.height + 2.0 * MAX_SIZE) * timeMod * .1;
	
	// Make random UIViews come in from different directions
	[NSTimer scheduledTimerWithTimeInterval:CREATION_INTERVAL target:self 
								   selector:@selector(createRandomlyEnteringUIView:) userInfo:nil repeats:YES];
	[NSTimer scheduledTimerWithTimeInterval:STEP_INTERVAL target:self 
								   selector:@selector(movementTimer:) userInfo:nil repeats:YES];
	
	// Notification center
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catchMovement:) name:@"SwatLeft" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catchMovement:) name:@"SwatRight" object:nil];
	// END COMMENTING
    
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


#pragma mark -
#pragma mark Random UIViews coming in

// Returns a random integer between the min and max, inclusive 
- (int) getRandIntBetwMin:(int)min andMax:(int)max
{
	if(min >= max){
		return min;
	}
	else{
		return(min +  arc4random() % (1 + max - min));
	}
}


- (void) movementTimer:(NSTimer *)timer {
	for (MoveView *view in self.views) {
		[view doMove];
	}
}

- (void) createRandomlyEnteringUIView:(NSTimer *)timer {
	CGRect randFrame = CGRectMake(0, 0, [self getRandIntBetwMin:MIN_SIZE andMax:MAX_SIZE], [self getRandIntBetwMin:MIN_SIZE	andMax:MAX_SIZE]);
	
	MoveView *view = [[[MoveView alloc] initWithFrame:randFrame] autorelease];
	[self.view addSubview:view];
	[self.views addObject:view];
	view.backgroundColor = [UIColor colorWithRed:[self getRandIntBetwMin:0 andMax:100]/100.0 green:[self getRandIntBetwMin:0 andMax:100]/100.0 blue:[self getRandIntBetwMin:0 andMax:100]/100.0 alpha:[self getRandIntBetwMin:80 andMax:100]/100.0];
	
	CGFloat centerX, centerY, dX, dY;
	switch (arc4random() % 6) {
		case 0:	// from Left
			centerX = -MAX_SIZE;
			centerY = [self getRandIntBetwMin:MAX_SIZE andMax:[UIScreen mainScreen].bounds.size.height - MAX_SIZE];
			dX = DX;
			dY = 0;
			
			break;
			
		case 1:	// from Right
			centerX = [UIScreen mainScreen].bounds.size.width + MAX_SIZE;
			centerY = [self getRandIntBetwMin:MAX_SIZE andMax:[UIScreen mainScreen].bounds.size.height - MAX_SIZE];
			dX = -DX;
			dY = 0;
			break;
			
		case 2:	// from Up
			centerX = [self getRandIntBetwMin:MAX_SIZE andMax:[UIScreen mainScreen].bounds.size.width - MAX_SIZE];
			centerY = -MAX_SIZE;
			dX = 0;
			dY = DY;
			break;
			
		case 3:	// from Down
			centerX = [self getRandIntBetwMin:MAX_SIZE andMax:[UIScreen mainScreen].bounds.size.width - MAX_SIZE];
			centerY = [UIScreen mainScreen].bounds.size.height + MAX_SIZE;
			dX = 0;
			dY = -DY;
			break;
			
		case 4:	// from Up
			centerX = [self getRandIntBetwMin:MAX_SIZE andMax:[UIScreen mainScreen].bounds.size.width - MAX_SIZE];
			centerY = -MAX_SIZE;
			dX = 0;
			dY = DY;
			break;
			
		case 5:	// from Down
			centerX = [self getRandIntBetwMin:MAX_SIZE andMax:[UIScreen mainScreen].bounds.size.width - MAX_SIZE];
			centerY = [UIScreen mainScreen].bounds.size.height + MAX_SIZE;
			dX = 0;
			dY = -DY;
			break;
			
			
		default:
			break;
	}
	
	view.center = CGPointMake(centerX, centerY);
	view.dx = dX;
	view.dy = dY;
	NSLog(@"Create view: %@", view);
}

- (void) viewAnimationDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	UIView *view = context;
	
	[self.views removeObject:view];
	[view removeFromSuperview];
}

#pragma mark -
#pragma mark Responding to gestures

- (void)showImageWithText:(NSString *)string atPoint:(CGPoint)centerPoint {
	
    /*
     Set the appropriate image for the image view, move the image view to the given point, then dispay it by setting its alpha to 1.0.
     */
	NSString *imageName = [string stringByAppendingString:@".png"];
	imageView.image = [UIImage imageNamed:imageName];
	imageView.center = centerPoint;
	imageView.alpha = 1.0;	
}

- (void) moveViews: (CGPoint) location direction: (UISwipeGestureRecognizerDirection) direction  {
	if (direction == UISwipeGestureRecognizerDirectionLeft) {
        location.x -= 220.0;
    }
    else if (direction == UISwipeGestureRecognizerDirectionRight) {
        location.x += 220.0;
    }
    else if (direction == UISwipeGestureRecognizerDirectionUp) {
        location.y -= 220.0;
    }
    else if (direction == UISwipeGestureRecognizerDirectionDown) {
        location.y += 220.0;
    }
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.55];
	[UIView setAnimationBeginsFromCurrentState:YES];
	
	imageView.alpha = 0.0;
	imageView.center = location;
	[UIView commitAnimations];
	
	CGFloat targetX, targetY;
	NSMutableArray *removers = [NSMutableArray arrayWithCapacity:2];
	for (MoveView *view in self.views) {
//		if (CGRectContainsRect(self.view.frame, view.frame)) {
			switch (direction) {
				case UISwipeGestureRecognizerDirectionUp:
					targetX = view.center.x;
					targetY = -MAX_SIZE;
					view.dx = 0;
					view.dy = -DY * 1.3;
					break;
				case UISwipeGestureRecognizerDirectionDown:
					targetX = view.center.x;
					targetY = [UIScreen mainScreen].bounds.size.height + MAX_SIZE;
					view.dx = 0;
					view.dy = DY * 1.3;
					break;
				case UISwipeGestureRecognizerDirectionLeft:
					targetX = -MAX_SIZE;
					targetY = view.center.y;
					view.dx = -DX * 1.3;
					view.dy = 0;
					break;
				case UISwipeGestureRecognizerDirectionRight:
					targetX = view.center.y;
					targetY = [UIScreen mainScreen].bounds.size.width + MAX_SIZE;;
					view.dx = DX * 1.3;
					view.dy = 0;
					break;
					
				default:
					break;
			}
			
//		} else {
		if (!(CGRectIntersectsRect(self.view.frame, view.frame))) {
			[removers addObject:view];
		}
	}
	
	for (MoveView *mover in removers) {
		if (!CGRectIntersectsRect(self.view.frame, mover.frame)) {
			[self.views removeObject:mover];
			[mover removeFromSuperview];
		}
	}
	
}
/*
 In response to a swipe gesture, show the image view appropriately then move the image view in the direction of the swipe as it fades out.
 */
- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
	
	CGPoint location = [recognizer locationInView:self.view];
	[self showImageWithText:@"swipe" atPoint:location];
	NSLog(@"Handle swipe dir: %d for views: %d", recognizer.direction, [self.views count]);
	
    [self moveViews: location direction:recognizer.direction];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SwatLeft" object:nil];
	
}

- (void) catchMovement:(NSNotification *)notification {
	if ([[notification name] isEqualToString:@"SwatRight"]) {
		[self moveViews:self.view.center direction:UISwipeGestureRecognizerDirectionLeft];
	} else if ([[notification name] isEqualToString:@"SwatLeft"]) {
		[self moveViews:self.view.center direction:UISwipeGestureRecognizerDirectionRight];
	}
}

/*
 In response to a rotation gesture, show the image view at the rotation given by the recognizer, then make it fade out in place while rotating back to horizontal.
 */
- (void)handleRotationFrom:(UIRotationGestureRecognizer *)recognizer {
	
	CGPoint location = [recognizer locationInView:self.view];
    
    CGAffineTransform transform = CGAffineTransformMakeRotation([recognizer rotation]);
    imageView.transform = transform;
	[self showImageWithText:@"rotation" atPoint:location];
    
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.65];
	imageView.alpha = 0.0;
    imageView.transform = CGAffineTransformIdentity;
	[UIView commitAnimations];
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

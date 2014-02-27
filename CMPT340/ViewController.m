//
//  ViewController.m
//  CMPT340
//
//  Created by Steven He on 2/17/14.
//  Copyright (c) 2014 Steven He. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize chart,startSession,heartRate,errorFingerCover;

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"%f",prevHue);
	// Do any additional setup after loading the view, typically from a nib.
    session = [[AVCaptureSession alloc] init];
	heartRate.text = @"test";
    //errorFingerCover.hidden = TRUE;
    [errorFingerCover setHidden:TRUE];
	// create a preview layer to show the output from the camera
	//	AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
	//	previewLayer.frame = previewView.frame;
	//	[previewView.layer addSublayer:previewLayer];
	
	// Get the default camera device
	AVCaptureDevice* camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if([camera isTorchModeSupported:AVCaptureTorchModeOn]) {
		[camera lockForConfiguration:nil];
        camera.activeVideoMaxFrameDuration =CMTimeMake(1, 10);
        camera.activeVideoMinFrameDuration=CMTimeMake(1, 10);
		camera.torchMode=AVCaptureTorchModeOn;
		//	camera.exposureMode=AVCaptureExposureModeLocked;
		[camera unlockForConfiguration];
	}
    
    // Create a AVCaptureInput with the camera device
	NSError *error=nil;
	AVCaptureInput* cameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:&error];
	if (cameraInput == nil) {
		NSLog(@"Error to create camera capture:%@",error);
	}
	
	// Set the output
	AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	
	// create a queue to run the capture on
	dispatch_queue_t captureQueue=dispatch_queue_create("catpureQueue", NULL);
	
	// setup our delegate
	[videoOutput setSampleBufferDelegate:self queue:captureQueue];
	
	// configure the pixel format
	videoOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                 nil];
	//videoOutput.minFrameDuration=CMTimeMake(1, 10);
	// and the size of the frames we want
	[session setSessionPreset:AVCaptureSessionPresetLow];
	
	// Add the input and output
	[session addInput:cameraInput];
	[session addOutput:videoOutput];
	
	// Start the session
	//[session startRunning];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

void RGBtoHSV( float r, float g, float b, float *h, float *s, float *v ) {
	float min, max, delta;
	min = MIN( r, MIN(g, b ));
	max = MAX( r, MAX(g, b ));
	*v = max;
	delta = max - min;
	if( max != 0 )
		*s = delta / max;
	else {
		// r = g = b = 0
		*s = 0;
		*h = -1;
		return;
	}
	if( r == max )
		*h = ( g - b ) / delta;
	else if( g == max )
		*h=2+(b-r)/delta;
	else
		*h=4+(r-g)/delta;
	*h *= 60;
	if( *h < 0 )
		*h += 360;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	static int count=0;
	count++;
	// only run if we're not already processing an image
	// this is the image buffer
	CVImageBufferRef cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer);
	// Lock the image buffer
	CVPixelBufferLockBaseAddress(cvimgRef,0);
	// access the data
	int width=CVPixelBufferGetWidth(cvimgRef);
	int height=CVPixelBufferGetHeight(cvimgRef);
	// get the raw image bytes
	uint8_t *buf=(uint8_t *) CVPixelBufferGetBaseAddress(cvimgRef);
	size_t bprow=CVPixelBufferGetBytesPerRow(cvimgRef);
	float r=0,g=0,b=0;
	for(int y=0; y<height; y++) {
		for(int x=0; x<width*4; x+=4) {
			b+=buf[x];
			g+=buf[x+1];
			r+=buf[x+2];
			//			a+=buf[x+3];
		}
		buf+=bprow;
	}
	r/=255*(float) (width*height);
	g/=255*(float) (width*height);
	b/=255*(float) (width*height);
    
	float h,s,v;
	
	RGBtoHSV(r, g, b, &h, &s, &v);
	//NSLog(@"%f",h);
    if (h>200){
        if(errorFingerCover.hidden==FALSE)
        {
            [errorFingerCover setHidden:TRUE];
        }
	// simple highpass and lowpass filter - do not use this for anything important, it's rubbish...
	static float lastH=0;
	float highPassValue=h-lastH;
	lastH=h;
	float lastHighPassValue=0;
	float lowPassValue=(lastHighPassValue+highPassValue)/2;
	lastHighPassValue=highPassValue;
    
	// send the point to the chart to be displayed
	//NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    [self detectPitch:lowPassValue];
	[chart performSelectorOnMainThread:@selector(addPoint:) withObject:[NSNumber numberWithFloat:lowPassValue] waitUntilDone:NO];
    }
    else{
        //display error message
        if(errorFingerCover.hidden==TRUE)
            [errorFingerCover setHidden:FALSE];
    }
//	[pool release];
}

-(IBAction)changeState:(id)sender{
    if(startSession.isOn){
        [session startRunning];
    }
    else{
        [pitches removeAllObjects];
        [session stopRunning];
    }
}

-(void)detectPitch:(float)hue{
    //if(prevHue==0)
    //{
    //    prevHue= [[NSNumber numberWithInteger:-1] floatValue];
    //}
    if(pitches==NULL)
    {
        pitches = [[NSMutableArray alloc]init];
    }
    float avg = 0;
    float sum = 0;
    for(int i =0; i< [pitches count];i++)
    {
        sum += [[pitches objectAtIndex:i] floatValue];
    }
    if([pitches count]>0)
        avg= sum/[pitches count];
    if(hue>avg&&prevHue>hue) //prevHue is pitch
    {
        
        [pitches addObject:[NSNumber numberWithFloat:prevHue]];
        
    }
    prevHue = hue;
}


@end

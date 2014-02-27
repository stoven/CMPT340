//
//  ViewController.h
//  CMPT340
//
//  Created by Steven He on 2/17/14.
//  Copyright (c) 2014 Steven He. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SimpleChart.h"

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *session;
    SimpleChart *chart;
    UISwitch *startSession;
    UILabel *errorFingerCover;
    UILabel *heartRate;
    NSTimer *sessionTimer;
    NSTimer *pitchIntervalTimer;
    NSMutableArray *pitches;
    float prevHue;
}

@property (nonatomic, retain) IBOutlet SimpleChart *chart;
@property (nonatomic, retain) IBOutlet UISwitch *startSession;
@property (nonatomic, retain) IBOutlet UILabel *heartRate;
@property (nonatomic, retain) IBOutlet UILabel *errorFingerCover;
-(IBAction)changeState:(id)sender;

@end

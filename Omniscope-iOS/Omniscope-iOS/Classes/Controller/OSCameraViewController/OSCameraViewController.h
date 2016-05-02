//
//  OSCameraViewController.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import "OSCameraImageTargetsEAGLView.h"
#import "OSApplicationSession.h"
#import "DataSet.h"

#import <CTAssetsPickerController/CTAssetsPickerController.h>

@interface OSCameraViewController : UIViewController <OSApplicationControl, CTAssetsPickerControllerDelegate> {
    QCAR::DataSet*  dataSetCurrent;
    QCAR::DataSet*  dataSetPhoto;

    BOOL continuousAutofocusEnabled;
}

@property (nonatomic, retain) IBOutlet OSCameraImageTargetsEAGLView *cameraView;

@property (nonatomic, strong) OSCameraImageTargetsEAGLView* eaglView;
@property (nonatomic, strong) UITapGestureRecognizer * tapGestureRecognizer;
@property (nonatomic, strong) OSApplicationSession * vapp;

@property (nonatomic, assign) BOOL flashEnabled;
@property (nonatomic, assign) BOOL frontCameraEnabled;

@property (nonatomic, retain) UIButton *frontBackButton;
@property (nonatomic, retain) UIImageView *galleryImageView;

- (IBAction)galleryButtonAction:(id)sender;
- (IBAction)captureButtonAction:(id)sender;
- (IBAction)frontBackButtonAction:(id)sender;

@end
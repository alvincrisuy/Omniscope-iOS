//
//  OSCameraViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSCameraViewController.h"
#import "QCAR.h"
#import "TrackerManager.h"
#import "ObjectTracker.h"
#import "Trackable.h"
#import "DataSet.h"
#import "CameraDevice.h"
#import "OSAppDelegate.h"

#import "OSCameraAboutPopupView.h"
#import "OSRootViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>


@interface OSCameraViewController ()

@end

@implementation OSCameraViewController
@synthesize tapGestureRecognizer, vapp, eaglView;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:NSStringFromClass([OSCameraViewController class]) bundle:nibBundleOrNil]) {
        // Custom initialization
        
        NSLog(@"ENTER");
    }
    
    return self;
}

- (CGRect)getCurrentARViewFrame {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect viewFrame = screenBounds;
    
    // If this device has a retina display, scale the view bounds
    // for the AR (OpenGL) view
    if (YES == vapp.isRetinaDisplay) {
        viewFrame.size.width *= 2.0;
        viewFrame.size.height *= 2.0;
    }
    return viewFrame;
}

- (void)autofocus:(UITapGestureRecognizer *)sender {
    [self performSelector:@selector(cameraPerformAutoFocus) withObject:nil afterDelay:.4];
}

- (void)cameraPerformAutoFocus {
    QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_TRIGGERAUTO);
}

- (void)doubleTapGestureAction:(UITapGestureRecognizer*)theGesture {
    NSLog(@"Double Tapped");
    
    OSCameraAboutPopupView *aboutPopupView = [OSCameraAboutPopupView viewFromNib];
    aboutPopupView.delegate = self;
    [aboutPopupView show];
}

- (void)showLoadingAnimation {
    CGRect indicatorBounds;
    CGRect mainBounds = [[UIScreen mainScreen] bounds];
    int smallerBoundsSize = MIN(mainBounds.size.width, mainBounds.size.height);
    int largerBoundsSize = MAX(mainBounds.size.width, mainBounds.size.height);
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown ) {
        indicatorBounds = CGRectMake(smallerBoundsSize / 2 - 12,
                                     largerBoundsSize / 2 - 12, 24, 24);
    }
    else {
        indicatorBounds = CGRectMake(largerBoundsSize / 2 - 12,
                                     smallerBoundsSize / 2 - 12, 24, 24);
    }
    
    UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc]
                                                 initWithFrame:indicatorBounds];
    
    loadingIndicator.tag  = 1;
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [self.cameraView addSubview:loadingIndicator];
    [loadingIndicator startAnimating];
}

//- (void)loadView {
//    
//    self.frontCameraEnabled = NO;
//    self.flashEnabled = NO;
//    
//    [[OSRootViewController sharedController].navigationController setNavigationBarHidden:YES animated:NO];
//    
//    vapp = [[OSApplicationSession alloc] initWithDelegate:self];
//    
//    CGRect viewFrame = [self getCurrentARViewFrame];
//    
//    self.cameraView = [[OSCameraImageTargetsEAGLView alloc] initWithFrame:viewFrame appSession:vapp];
//    [self setView:self.cameraView];
//    
//    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.cameraView.layer;
//    eaglLayer.opaque = TRUE;
//    
//    eaglLayer.drawableProperties = @{
//                                     kEAGLDrawablePropertyRetainedBacking: [NSNumber numberWithBool:YES],
//                                     kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8,
//                                     };
//    
//    CGRect screenRect = [[UIScreen mainScreen] bounds];
//    CGFloat captureButtonX = (screenRect.size.width / 2.0f) - 50/2;
//    CGFloat captureButtonY = (screenRect.size.height - 50.0f * 1.5f);
//    
//    UIButton *captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [captureButton addTarget:self
//                      action:@selector(captureButtonAction:)
//            forControlEvents:UIControlEventTouchUpInside];
//    [captureButton setImage:[UIImage imageNamed:@"capture150"] forState:UIControlStateNormal];
//    captureButton.frame = CGRectMake(captureButtonX, captureButtonY, 50.0, 50.0);
//    [self.view addSubview:captureButton];
//    
//    //    CGFloat galleryButtonX = 50.0f/2.0f;
//    //    CGFloat galleryButtonY = (screenRect.size.height - 50.0f * 1.5f);
//    //
//    //    UIButton *galleryButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    //    [galleryButton addTarget:self
//    //                      action:@selector(galleryButtonAction:)
//    //            forControlEvents:UIControlEventTouchUpInside];
//    //    [galleryButton setImage:[UIImage imageNamed:@"art"] forState:UIControlStateNormal];
//    //    galleryButton.frame = CGRectMake(galleryButtonX, galleryButtonY, 50.0, 50.0);
//    //    [self.view addSubview:galleryButton];
//    
//    CGFloat frontBackButtonX = screenRect.size.width - 50.0f * 1.5f;
//    CGFloat frontBackButtonY = (screenRect.size.height - 50.0f * 1.5f);
//    
//    UIButton *frontBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [frontBackButton addTarget:self
//                        action:@selector(frontBackButtonAction:)
//              forControlEvents:UIControlEventTouchUpInside];
//    [frontBackButton setImage:[UIImage imageNamed:@"arrows-1"] forState:UIControlStateNormal];
//    frontBackButton.frame = CGRectMake(frontBackButtonX, frontBackButtonY, 50.0, 50.0);
//    [self.view addSubview:frontBackButton];
//    
//    OSAppDelegate *appDelegate = (OSAppDelegate*)[[UIApplication sharedApplication] delegate];
//    appDelegate.glResourceHandler = self.cameraView;
//    
//    // double tap used to also trigger the menu
//    /*UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doubleTapGestureAction:)];
//     doubleTap.numberOfTapsRequired = 2;
//     [self.cameraView addGestureRecognizer:doubleTap];
//     
//     // a single tap will trigger a single autofocus operation
//     tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];
//     if (doubleTap != NULL) {
//     [tapGestureRecognizer requireGestureRecognizerToFail:doubleTap];
//     }
//     
//     [[NSNotificationCenter defaultCenter] addObserver:self
//     selector:@selector(dismissARViewController)
//     name:@"kDismissARViewController"
//     object:nil]; */
//    
//    // we use the iOS notification to pause/resume the AR when the application goes (or come back from) background
//    [[NSNotificationCenter defaultCenter]
//     addObserver:self
//     selector:@selector(pauseAR)
//     name:UIApplicationWillResignActiveNotification
//     object:nil];
//    
//    [[NSNotificationCenter defaultCenter]
//     addObserver:self
//     selector:@selector(resumeAR)
//     name:UIApplicationDidBecomeActiveNotification
//     object:nil];
//    
//    // initialize AR
//    [vapp initAR:QCAR::GL_20 orientation:[[UIApplication sharedApplication] statusBarOrientation]];
//    
//    // show loading animation while AR is being initialized
//    [self showLoadingAnimation];
//    
//
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.frontCameraEnabled = NO;
    self.flashEnabled = NO;
    
    [[OSRootViewController sharedController].navigationController setNavigationBarHidden:YES animated:NO];
    
    vapp = [[OSApplicationSession alloc] initWithDelegate:self];
    
    CGRect viewFrame = [self getCurrentARViewFrame];
    
    self.cameraView = [[OSCameraImageTargetsEAGLView alloc] initWithFrame:viewFrame appSession:vapp];
    [self setView:self.cameraView];
    
    OSAppDelegate *appDelegate = (OSAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = self.cameraView;
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.cameraView.layer;
    eaglLayer.opaque = TRUE;    
    
    eaglLayer.drawableProperties = @{
                                     kEAGLDrawablePropertyRetainedBacking: [NSNumber numberWithBool:YES],
                                     kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8,
                                     };
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat captureButtonX = (screenRect.size.width / 2.0f) - 50/2;
    CGFloat captureButtonY = (screenRect.size.height - 50.0f * 1.5f);
    
    UIButton *captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [captureButton addTarget:self
               action:@selector(captureButtonAction:)
     forControlEvents:UIControlEventTouchUpInside];
    [captureButton setImage:[UIImage imageNamed:@"capture150"] forState:UIControlStateNormal];
    captureButton.frame = CGRectMake(captureButtonX, captureButtonY, 50.0, 50.0);
    [self.view addSubview:captureButton];
    
//    CGFloat galleryButtonX = 50.0f/2.0f;
//    CGFloat galleryButtonY = (screenRect.size.height - 50.0f * 1.5f);
//    
//    UIButton *galleryButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [galleryButton addTarget:self
//                      action:@selector(galleryButtonAction:)
//            forControlEvents:UIControlEventTouchUpInside];
//    [galleryButton setImage:[UIImage imageNamed:@"art"] forState:UIControlStateNormal];
//    galleryButton.frame = CGRectMake(galleryButtonX, galleryButtonY, 50.0, 50.0);
//    [self.view addSubview:galleryButton];
    
    CGFloat frontBackButtonX = screenRect.size.width - 50.0f * 1.5f;
    CGFloat frontBackButtonY = (screenRect.size.height - 50.0f * 1.5f);
    
    UIButton *frontBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [frontBackButton addTarget:self
                      action:@selector(frontBackButtonAction:)
            forControlEvents:UIControlEventTouchUpInside];
    [frontBackButton setImage:[UIImage imageNamed:@"arrows-1"] forState:UIControlStateNormal];
    frontBackButton.frame = CGRectMake(frontBackButtonX, frontBackButtonY, 50.0, 50.0);
    [self.view addSubview:frontBackButton];
    
    
    // double tap used to also trigger the menu
    /*UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doubleTapGestureAction:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.cameraView addGestureRecognizer:doubleTap];
    
    // a single tap will trigger a single autofocus operation
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];
    if (doubleTap != NULL) {
        [tapGestureRecognizer requireGestureRecognizerToFail:doubleTap];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissARViewController)
                                                 name:@"kDismissARViewController"
                                               object:nil]; */
    
    // we use the iOS notification to pause/resume the AR when the application goes (or come back from) background
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(pauseAR)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(resumeAR)
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
    
    // initialize AR
    [vapp initAR:QCAR::GL_20 orientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    // show loading animation while AR is being initialized
    [self showLoadingAnimation];
    


}

- (void)dismissARViewController {
    
}

- (void) onQCARUpdate: (QCAR::State *) state {
    [self activateDataSet:dataSetPhoto];
}

- (void)pauseAR {
    NSError * error = nil;
    if (![vapp pauseAR:&error]) {
        NSLog(@"Error pausing AR:%@", [error description]);
    }
}

- (void)resumeAR {
    NSError * error = nil;
    if(! [vapp resumeAR:&error]) {
        NSLog(@"Error resuming AR:%@", [error description]);
    }
    // on resume, we reset the flash
    QCAR::CameraDevice::getInstance().setFlashTorchMode(false);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)galleryButtonAction:(id)sender {
    NSLog(@"gallery");
    
    // request authorization status
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // init picker
            CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
            
            // set delegate
            picker.delegate = self;
            
            
            
            // Optionally present picker as a form sheet on iPad
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                picker.modalPresentationStyle = UIModalPresentationFormSheet;
            
            // present picker
//            [self presentViewController:picker animated:YES completion:nil];
            
            [[OSRootViewController sharedController].contentNavigationController presentViewController:picker animated:YES completion:^{
                
            }];
        });
    }];
}

- (IBAction)captureButtonAction:(id)sender {
    NSLog(@"capture");
    
    UIImage *outputImage = nil;
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGRect s = CGRectMake(0, 0, 320.0f * scale, 480.0f * scale);
    uint8_t *buffer = (uint8_t *) malloc(s.size.width * s.size.height * 4);

    glReadPixels(0, 0, s.size.width, s.size.height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, buffer, s.size.width * s.size.height * 4, NULL);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef iref = CGImageCreate(s.size.width, s.size.height, 8, 32, s.size.width * 4, colorSpaceRef, kCGBitmapByteOrderDefault, ref, NULL, true, kCGRenderingIntentDefault);
    
    size_t width = CGImageGetWidth(iref);
    size_t height = CGImageGetHeight(iref);
    size_t length = width * height * 4;
    uint32_t *pixels = (uint32_t *)malloc(length);
    
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * 4,
                                                 CGImageGetColorSpace(iref), kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformMakeTranslation(0.0f, height);
    transform = CGAffineTransformScale(transform, 1.0, -1.0);
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
    CGImageRef outputRef = CGBitmapContextCreateImage(context);
    
    outputImage = [UIImage imageWithCGImage: outputRef];
    
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(ref);
    CGImageRelease(iref);
    CGContextRelease(context);
    CGImageRelease(outputRef);
    free(pixels);
    free(buffer);
    
    UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil);
    
}

- (IBAction)frontBackButtonAction:(id)sender {
    NSLog(@"frontback");

    NSError * error = nil;
    if ([vapp stopCamera:&error]) {
        if (self.frontCameraEnabled) {
            bool result = [vapp startAR:QCAR::CameraDevice::CAMERA_BACK error:&error];
            self.frontCameraEnabled = !result;
            
        } else {
            bool result = [vapp startAR:QCAR::CameraDevice::CAMERA_FRONT error:&error];
            self.frontCameraEnabled = result;
            if (self.frontCameraEnabled) {
                // Switch Flash toggle OFF, in case it was previously ON,
                // as the front camera does not support flash
                self.flashEnabled = NO;
            }
            
        }
    }
}

- (bool)doDeinitTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    trackerManager.deinitTracker(QCAR::ObjectTracker::getClassType());
    return YES;
}

- (bool)doStopTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ObjectTracker::getClassType());
    
    if (NULL != tracker) {
        tracker->stop();
        NSLog(@"INFO: successfully stopped tracker");
        return YES;
    } else {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return NO;
    }
}

- (bool)doLoadTrackersData {
    dataSetPhoto = [self loadObjectTrackerDataSet:@"PhotoDetection.xml"];
    
    return YES;
}

- (QCAR::DataSet *)loadObjectTrackerDataSet:(NSString*)dataFile {
    NSLog(@"loadObjectTrackerDataSet (%@)", dataFile);
    QCAR::DataSet * dataSet = NULL;
    
    // Get the QCAR tracker manager image tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ObjectTracker* objectTracker = static_cast<QCAR::ObjectTracker*>(trackerManager.getTracker(QCAR::ObjectTracker::getClassType()));
    
    if (NULL == objectTracker) {
        NSLog(@"ERROR: failed to get the ObjectTracker from the tracker manager");
        return NULL;
    } else {
        dataSet = objectTracker->createDataSet();
        
        if (NULL != dataSet) {
            NSLog(@"INFO: successfully loaded data set");
            
            // Load the data set from the app's resources location
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], QCAR::STORAGE_APPRESOURCE)) {
                NSLog(@"ERROR: failed to load data set");
                objectTracker->destroyDataSet(dataSet);
                dataSet = NULL;
            }
        }
        else {
            NSLog(@"ERROR: failed to create data set");
        }
    }
    
    return dataSet;
}

- (bool)doInitTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* trackerBase = trackerManager.initTracker(QCAR::ObjectTracker::getClassType());
    if (trackerBase == NULL) {
        NSLog(@"Failed to initialize ObjectTracker.");
        return false;
    }
    return true;
}

- (bool)doUnloadTrackersData {
    [self deactivateDataSet: dataSetCurrent];
    dataSetCurrent = nil;
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ObjectTracker* objectTracker = static_cast<QCAR::ObjectTracker*>(trackerManager.getTracker(QCAR::ObjectTracker::getClassType()));
    
    // Destroy the data sets:
    if (!objectTracker->destroyDataSet(dataSetPhoto)) {
        NSLog(@"Failed to destroy data set Tarmac.");
    }
    
    NSLog(@"datasets destroyed");
    return YES;
}

- (BOOL)activateDataSet:(QCAR::DataSet *)theDataSet
{
    // if we've previously recorded an activation, deactivate it
    if (dataSetCurrent != nil)
    {
        [self deactivateDataSet:dataSetCurrent];
    }
    BOOL success = NO;
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ObjectTracker* objectTracker = static_cast<QCAR::ObjectTracker*>(trackerManager.getTracker(QCAR::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL) {
        NSLog(@"Failed to load tracking data set because the ObjectTracker has not been initialized.");
    }
    else
    {
        // Activate the data set:
        if (!objectTracker->activateDataSet(theDataSet))
        {
            NSLog(@"Failed to activate data set.");
        }
        else
        {
//            NSLog(@"Successfully activated data set.");
            dataSetCurrent = theDataSet;
            success = YES;
        }
    }
    
    return success;
}

- (BOOL)deactivateDataSet:(QCAR::DataSet *)theDataSet {
    if ((dataSetCurrent == nil) || (theDataSet != dataSetCurrent)) {
        NSLog(@"Invalid request to deactivate data set.");
        return NO;
    }
    
    BOOL success = NO;
    
    // we deactivate the enhanced tracking
    [self setExtendedTrackingForDataSet:theDataSet start:NO];
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ObjectTracker* objectTracker = static_cast<QCAR::ObjectTracker*>(trackerManager.getTracker(QCAR::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL) {
        NSLog(@"Failed to unload tracking data set because the ObjectTracker has not been initialized.");
    } else {
        // Activate the data set:
        if (!objectTracker->deactivateDataSet(theDataSet)) {
            NSLog(@"Failed to deactivate data set.");
        } else {
            success = YES;
        }
    }
    
    dataSetCurrent = nil;
    
    return success;
}

- (BOOL)setExtendedTrackingForDataSet:(QCAR::DataSet *)theDataSet start:(BOOL) start {
    BOOL result = YES;
    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++) {
        QCAR::Trackable* trackable = theDataSet->getTrackable(tIdx);
        if (start) {
            if (!trackable->startExtendedTracking())
            {
                NSLog(@"Failed to start extended tracking on: %s", trackable->getName());
                result = false;
            }
        } else {
            if (!trackable->stopExtendedTracking())
            {
                NSLog(@"Failed to stop extended tracking on: %s", trackable->getName());
                result = false;
            }
        }
    }
    return result;
}

- (void)onInitARDone:(NSError *)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{

        UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[self.cameraView viewWithTag:1];
        [loadingIndicator removeFromSuperview];

    });

    if (error == nil) {
        NSError * error = nil;
        [vapp startAR:QCAR::CameraDevice::CAMERA_BACK error:&error];
        
        // by default, we try to set the continuous auto focus mode
        continuousAutofocusEnabled = QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        
    } else {
        NSLog(@"Error initializing AR:%@", [error description]);
        dispatch_async( dispatch_get_main_queue(), ^{
            
        });
    }
}

- (bool)doStartTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ObjectTracker::getClassType());
    if(tracker == 0) {
        return false;
    }
    tracker->start();
    return true;
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    // assets contains PHAsset objects.
    
    NSLog(@"ENTER assetsPickerController");
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end

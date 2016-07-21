//
//  OSCameraViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSCameraViewController.h"
#import "Vuforia.h"
#import "TrackerManager.h"
#import "ObjectTracker.h"
#import "Trackable.h"
#import "DataSet.h"
#import "CameraDevice.h"
#import "OSAppDelegate.h"

#import "OSRootViewController.h"
#import "OSAboutViewController.h"
#import "OSGalleryViewController.h"
#import "OSWelcomeView.h"
#import "OSRootTableViewCell.h"

#import "UIDevice+DeviceType.h"
#import "NSString+DeviceType.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "CustomAlbum.h"

NSString *const CSAlbum = @"Omniscope";
//NSString *const CSAssetIdentifier = @"assetIdentifier";
//NSString *const CSAlbumIdentifier = @"albumIdentifier";

#define OS_PI 3.14159265358979

@interface OSCameraViewController ()

//@property (nonatomic, retain) NSString *albumId;
@property (nonatomic, retain) NSString *recentImg;

@end

@implementation OSCameraViewController
@synthesize tapGestureRecognizer, vapp, eaglView;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:[NSStringFromClass([OSCameraViewController class]) concatenateClassToDeviceType] bundle:nibBundleOrNil]) {
        // Custom initialization
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
    Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_TRIGGERAUTO);
}

- (void)doubleTapGestureAction:(UITapGestureRecognizer*)theGesture {
    
    OSAboutViewController *aboutViewController = [OSRootViewController sharedController].aboutViewController;
    
    [[OSRootViewController sharedController].contentNavigationController presentViewController:aboutViewController animated:YES completion:^{
        
    }];
}

- (void)createAlbum {
    [CustomAlbum makeAlbumWithTitle:CSAlbum onSuccess:^(NSString *AlbumId) {
//        self.albumId = AlbumId;
     } onError:^(NSError *error) {
        NSLog(@"problem in creating album");
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // show loading animation while AR is being initialized
    [self showLoadingAnimation];
    
    [[OSRootViewController sharedController] showTabView];
    [OSRootViewController sharedController].delegate = self;
    
    self.frontCameraEnabled = NO;
    self.flashEnabled       = NO;
    self.gridEnabled        = NO;
    
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
    
//    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    [NSNumber numberWithBool:FALSE],
//                                    kEAGLDrawablePropertyRetainedBacking,
//                                    kEAGLColorFormatRGBA8,
//                                    kEAGLDrawablePropertyColorFormat,
//                                    nil];

    
    // a single tap will trigger a single autofocus operation
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissARViewController)
                                                 name:@"kDismissARViewController"
                                               object:nil];
    
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
    [vapp initAR:Vuforia::GL_20 orientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    
    [self gridLines];
}

- (void)gridLines {
    
    self.gridLinesView = [OSGridLinesView viewFromNib];
    self.gridLinesView.alpha = 0.0f;
    [self.cameraView addSubview:self.gridLinesView];
    
}

- (void)showLoadingAnimation {
//    CGRect indicatorBounds;
//    CGRect mainBounds = [[UIScreen mainScreen] bounds];
//    int smallerBoundsSize = MIN(mainBounds.size.width, mainBounds.size.height);
//    int largerBoundsSize = MAX(mainBounds.size.width, mainBounds.size.height);
//    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
//    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown ) {
//        indicatorBounds = CGRectMake(smallerBoundsSize / 2 - 12,
//                                     largerBoundsSize / 2 - 12, 24, 24);
//    } else {
//        indicatorBounds = CGRectMake(largerBoundsSize / 2 - 12,
//                                     smallerBoundsSize / 2 - 12, 24, 24);
//    }
    
    //    UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc]
    //                                                 initWithFrame:indicatorBounds];
    //
    //    loadingIndicator.tag  = 1;
    //    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    //    [self.cameraView addSubview:loadingIndicator];
    //    [loadingIndicator startAnimating];
    
    OSWelcomeView *welcomeView = [OSWelcomeView viewFromNib];
    welcomeView.tag = 1;
    [self.cameraView addSubview:welcomeView];
    
    [OSRootViewController sharedController].tabView.alpha = 0.0f;
}


- (void)createButtons {
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
//    CGFloat captureButtonX = (screenRect.size.width / 2.0f) - 75/2;
//    CGFloat captureButtonY = (screenRect.size.height - 75.0f * 1.5f);
//    
//    // Capture Button
//    self.captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [self.captureButton addTarget:self
//                           action:@selector(captureButtonAction:)
//                 forControlEvents:UIControlEventTouchUpInside];
//    [self.captureButton setImage:[UIImage imageNamed:@"capture150"] forState:UIControlStateNormal];
//    [self.captureButton setImage:[UIImage imageNamed:@"capture150selected"] forState:UIControlStateSelected];
//    [self.captureButton setImage:[UIImage imageNamed:@"capture150selected"] forState:UIControlStateFocused];
//    [self.captureButton setImage:[UIImage imageNamed:@"capture150selected"] forState:UIControlStateHighlighted];
//    self.captureButton.frame = CGRectMake(captureButtonX, captureButtonY, 75.0f, 75.0f);
//    self.captureButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
//    self.captureButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
//    
//    [self.view addSubview:self.captureButton];
    
    
    // Gallery Button
    CGFloat galleryButtonX = screenRect.size.width/4.0f - (60.0f / 1.5f);
    CGFloat galleryButtonY = (screenRect.size.height - 65.0f * 1.5f);
    
    [self createAlbum];
    
    self.galleryImageView = [[UIImageView alloc] initWithFrame:CGRectMake(galleryButtonX, galleryButtonY, 45, 45)];
    self.galleryImageView.layer.cornerRadius = 2.0f;
    self.galleryImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.galleryImageView.clipsToBounds = YES;
    [self.view addSubview:self.galleryImageView];
    
    PHAssetCollection *collection = [CustomAlbum getMyAlbumWithName:CSAlbum];
    [CustomAlbum getImageWithCollection:collection onSuccess:^(UIImage *image) {
        self.galleryImageView.image = image;
        
        UIButton *galleryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [galleryButton addTarget:self
                          action:@selector(galleryButtonAction:)
                forControlEvents:UIControlEventTouchUpInside];
        galleryButton.frame = CGRectMake(galleryButtonX, galleryButtonY, 45.0, 45.0);
        [self.view addSubview:galleryButton];
        
    } onError:^(NSError *error) {
        NSLog(@"Not Found!");
    }];
    
//    // Front Back Button
//    CGFloat frontBackButtonX = screenRect.size.width/2.0f + screenRect.size.width/4.0f;
//    CGFloat frontBackButtonY = (screenRect.size.height - 60.0f * 1.5f);
//    
//    self.frontBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [self.frontBackButton addTarget:self
//                             action:@selector(frontBackButtonAction:)
//                   forControlEvents:UIControlEventTouchUpInside];
//    [self.frontBackButton setImage:[UIImage imageNamed:@"arrows-1"] forState:UIControlStateNormal];
//    self.frontBackButton.frame = CGRectMake(frontBackButtonX, frontBackButtonY, 30.0, 30.0);
//    self.frontBackButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
//    self.frontBackButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
//    self.frontBackButton.alpha = 0.5f;
//    
//    [self.view addSubview:self.frontBackButton];
}

- (void)orientationChanged:(NSNotification *)note {
    UIDevice * device = note.object;
    OSRootTableViewCell *rowCell0 = [[OSRootViewController sharedController].sideBarTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    OSRootTableViewCell *rowCell1 = [[OSRootViewController sharedController].sideBarTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    OSRootTableViewCell *rowCell2 = [[OSRootViewController sharedController].sideBarTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    OSRootTableViewCell *rowCell3 = [[OSRootViewController sharedController].sideBarTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    
    switch(device.orientation) {
        case UIDeviceOrientationPortrait:
            NSLog(@"portrait");
        {
            [UIView animateWithDuration:0.3 animations:^{
                [OSRootViewController sharedController].galleryTabButton.transform  = CGAffineTransformMakeRotation(0);
                [OSRootViewController sharedController].captureTabButton.transform  = CGAffineTransformMakeRotation(0);
                rowCell0.rowButton0.transform = CGAffineTransformMakeRotation(0);
                rowCell1.rowButton1.transform = CGAffineTransformMakeRotation(0);
                rowCell2.rowButton2.transform = CGAffineTransformMakeRotation(0);
                rowCell3.rowButton3.transform = CGAffineTransformMakeRotation(0);
            }];
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"upside down");
        {
            [UIView animateWithDuration:0.3 animations:^{
                [OSRootViewController sharedController].galleryTabButton.transform  = CGAffineTransformMakeRotation(-OS_PI);
                [OSRootViewController sharedController].captureTabButton.transform  = CGAffineTransformMakeRotation(-OS_PI);
                rowCell0.rowButton0.transform = CGAffineTransformMakeRotation(-OS_PI);
                rowCell1.rowButton1.transform = CGAffineTransformMakeRotation(-OS_PI);
                rowCell2.rowButton2.transform = CGAffineTransformMakeRotation(-OS_PI);
                rowCell3.rowButton3.transform = CGAffineTransformMakeRotation(-OS_PI);
            }];
        }
            
            break;
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"landscape left");
        {
            [UIView animateWithDuration:0.3 animations:^{
                [OSRootViewController sharedController].galleryTabButton.transform  = CGAffineTransformMakeRotation(OS_PI/2);
                [OSRootViewController sharedController].captureTabButton.transform  = CGAffineTransformMakeRotation(OS_PI/2);
                rowCell0.rowButton0.transform = CGAffineTransformMakeRotation(OS_PI/2);
                rowCell1.rowButton1.transform = CGAffineTransformMakeRotation(OS_PI/2);
                rowCell2.rowButton2.transform = CGAffineTransformMakeRotation(OS_PI/2);
                rowCell3.rowButton3.transform = CGAffineTransformMakeRotation(OS_PI/2);
            }];
        }
            break;
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"landscape right");
        {
            [UIView animateWithDuration:0.3 animations:^{
                [OSRootViewController sharedController].galleryTabButton.transform  = CGAffineTransformMakeRotation(-OS_PI/2);
                [OSRootViewController sharedController].captureTabButton.transform  = CGAffineTransformMakeRotation(-OS_PI/2);
                rowCell0.rowButton0.transform = CGAffineTransformMakeRotation(-OS_PI/2);
                rowCell1.rowButton1.transform = CGAffineTransformMakeRotation(-OS_PI/2);
                rowCell2.rowButton2.transform = CGAffineTransformMakeRotation(-OS_PI/2);
                rowCell3.rowButton3.transform = CGAffineTransformMakeRotation(-OS_PI/2);
            }];
        }
            break;
        case UIDeviceOrientationFaceUp:
            NSLog(@"faceup");
            break;
        case UIDeviceOrientationFaceDown:
            NSLog(@"facedown");
            break;
        default:
            break;
    };
}

- (void)dismissARViewController {
    
}

- (void)onVuforiaUpdate:(Vuforia::State *)state {
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
    Vuforia::CameraDevice::getInstance().setFlashTorchMode(false);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)galleryButtonAction:(id)sender {
    NSLog(@"gallery");
    
//    OSGalleryViewController *galleryViewController = [OSRootViewController sharedController].galleryViewController;
//    
//    [[OSRootViewController sharedController].contentNavigationController presentViewController:galleryViewController animated:YES completion:^{
//        
//    }];
}

- (bool)doDeinitTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    trackerManager.deinitTracker(Vuforia::ObjectTracker::getClassType());
    return YES;
}

- (bool)doStopTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    
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

- (Vuforia::DataSet *)loadObjectTrackerDataSet:(NSString*)dataFile {
    NSLog(@"loadObjectTrackerDataSet (%@)", dataFile);
    Vuforia::DataSet * dataSet = NULL;
    
    // Get the Vuforia tracker manager image tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (NULL == objectTracker) {
        NSLog(@"ERROR: failed to get the ObjectTracker from the tracker manager");
        return NULL;
    } else {
        dataSet = objectTracker->createDataSet();
        
        if (NULL != dataSet) {
            NSLog(@"INFO: successfully loaded data set");
            
            Vuforia::setHint(Vuforia::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, 5);
            
            // Load the data set from the app's resources location
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], Vuforia::STORAGE_APPRESOURCE)) {
                
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
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* trackerBase = trackerManager.initTracker(Vuforia::ObjectTracker::getClassType());
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
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    // Destroy the data sets:
    if (!objectTracker->destroyDataSet(dataSetPhoto)) {
        NSLog(@"Failed to destroy data set Tarmac.");
    }
    
    NSLog(@"datasets destroyed");
    return YES;
}

- (BOOL)activateDataSet:(Vuforia::DataSet *)theDataSet {
    // if we've previously recorded an activation, deactivate it
    if (dataSetCurrent != nil) {
        [self deactivateDataSet:dataSetCurrent];
    }
    
    BOOL success = NO;
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL) {
        NSLog(@"Failed to load tracking data set because the ObjectTracker has not been initialized.");
    } else {
        // Activate the data set:
        if (!objectTracker->activateDataSet(theDataSet)) {
            NSLog(@"Failed to activate data set.");
        } else {
//            NSLog(@"Successfully activated data set.");
            dataSetCurrent = theDataSet;
            success = YES;
        }
    }
    
    return success;
}

- (BOOL)deactivateDataSet:(Vuforia::DataSet *)theDataSet {
    if ((dataSetCurrent == nil) || (theDataSet != dataSetCurrent)) {
        NSLog(@"Invalid request to deactivate data set.");
        return NO;
    }
    
    BOOL success = NO;
    
    // we deactivate the enhanced tracking
    [self setExtendedTrackingForDataSet:theDataSet start:NO];
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
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

- (BOOL)setExtendedTrackingForDataSet:(Vuforia::DataSet *)theDataSet start:(BOOL) start {
    BOOL result = YES;
    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++) {
        Vuforia::Trackable* trackable = theDataSet->getTrackable(tIdx);
        if (start) {
            if (!trackable->startExtendedTracking()) {
                NSLog(@"Failed to start extended tracking on: %s", trackable->getName());
                result = false;
            }
        } else {
            if (!trackable->stopExtendedTracking()) {
                NSLog(@"Failed to stop extended tracking on: %s", trackable->getName());
                result = false;
            }
        }
    }
    return result;
}

- (void)onInitARDone:(NSError *)error {
    
    if (error == nil) {
        NSError * error = nil;
        [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];
        
        // by default, we try to set the continuous auto focus mode
        continuousAutofocusEnabled = Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //        UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[self.cameraView viewWithTag:1];
            //        [loadingIndicator removeFromSuperview];
            
            [OSRootViewController sharedController].tabView.alpha = 1.0f;
            
            OSWelcomeView *welcomeView = (OSWelcomeView *)[self.cameraView viewWithTag:1];
            [welcomeView removeFromSuperview];
            
        });

    } else {
        NSLog(@"Error initializing AR:%@", [error description]);
        dispatch_async( dispatch_get_main_queue(), ^{
            
        });
    }
}

- (bool)doStartTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    if (tracker == 0) {
        return false;
    }
    tracker->start();
    return true;
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - OSRootViewControllerDelegate

- (void)row0SideButtonAction:(UIButton *)sender {
    NSLog(@"hashtag");
    
    self.gridEnabled = !self.gridEnabled;
    
    if (self.gridEnabled) {
        self.gridLinesView.alpha = 1.0f;
    } else {
        self.gridLinesView.alpha = 0.0f;
    }
}

- (void)row1SideButtonAction:(UIButton *)sender {
    NSLog(@"flip");
    
    NSError * error = nil;
    if ([vapp stopCamera:&error]) {
        
        UIDevice * device = [UIDevice currentDevice];
        OSRootTableViewCell *rowCell = [[OSRootViewController sharedController].sideBarTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        
        if (self.frontCameraEnabled) {
            bool result = [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];
            self.frontCameraEnabled = !result;
            
            switch(device.orientation) {
                case UIDeviceOrientationPortrait:
                    NSLog(@"portrait");
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        rowCell.rowButton1.transform = CGAffineTransformMakeRotation(0);
                    }];
                }
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    NSLog(@"upside down");
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        rowCell.rowButton1.transform = CGAffineTransformMakeRotation(-OS_PI);
                    }];
                }
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    NSLog(@"landscape left");
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        rowCell.rowButton1.transform = CGAffineTransformMakeRotation(OS_PI/2);
                    }];
                }
                    break;
                case UIDeviceOrientationLandscapeRight:
                    NSLog(@"landscape right");
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        rowCell.rowButton1.transform = CGAffineTransformMakeRotation(-OS_PI/2);
                    }];
                }
                    break;
                case UIDeviceOrientationFaceUp:
                    NSLog(@"faceup");
                    break;
                case UIDeviceOrientationFaceDown:
                    NSLog(@"facedown");
                    break;
                default:
                    break;
            };
            
        } else {
            
            switch(device.orientation) {
                case UIDeviceOrientationPortrait:
                    NSLog(@"portrait");
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        rowCell.rowButton1.transform = CGAffineTransformMakeRotation(-OS_PI);
                    }];
                }
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    NSLog(@"upside down");
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        rowCell.rowButton1.transform = CGAffineTransformMakeRotation(0);
                    }];
                }
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    NSLog(@"landscape left");
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        rowCell.rowButton1.transform = CGAffineTransformMakeRotation(-OS_PI/2);
                    }];
                }
                    break;
                case UIDeviceOrientationLandscapeRight:
                    NSLog(@"landscape right");
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        rowCell.rowButton1.transform = CGAffineTransformMakeRotation(OS_PI/2);
                    }];
                }
                    break;
                case UIDeviceOrientationFaceUp:
                    NSLog(@"faceup");
                    break;
                case UIDeviceOrientationFaceDown:
                    NSLog(@"facedown");
                    break;
                default:
                    break;
            };
            
            bool result = [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_FRONT error:&error];
            self.frontCameraEnabled = result;
            if (self.frontCameraEnabled) {
                // Switch Flash toggle OFF, in case it was previously ON,
                // as the front camera does not support flash
                self.flashEnabled = NO;
            }
        }
    }
}

- (void)captureTabButtonAction:(UIButton *)sender {
    NSLog(@"capture");
    
    AudioServicesPlaySystemSoundWithCompletion(1108, ^{
        
    });
    
//    try {
    
        @try {
            UIImage *outputImage    = nil;
            CGRect screenRect       = [[UIScreen mainScreen] bounds];
            CGFloat scale           = [[UIScreen mainScreen] scale];
            CGRect s                = CGRectMake(0, 0, screenRect.size.width * scale, screenRect.size.height * scale);
//            uint8_t *buffer         = (uint8_t *) malloc(s.size.width * s.size.height * 4);
            GLubyte *buffer         = (GLubyte *) malloc(s.size.width * s.size.height * 4);

//            if (buffer == NULL || buffer == nil || (buffer[0] == '\0')) {
//                
//                NSLog(@"NULL");
//                return;
//            }
            
            // TODO - Find fix for buffer error
            glReadPixels(0, 0, s.size.width, s.size.height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
            CGDataProviderRef ref           = CGDataProviderCreateWithData(NULL, buffer, s.size.width * s.size.height * 4, NULL);
            CGColorSpaceRef colorSpaceRef   = CGColorSpaceCreateDeviceRGB();
            CGImageRef iref                 = CGImageCreate(s.size.width, s.size.height, 8, 32, s.size.width * 4, colorSpaceRef, kCGBitmapByteOrderDefault, ref, NULL, true, kCGRenderingIntentDefault);
            
            size_t width        = CGImageGetWidth(iref);
            size_t height       = CGImageGetHeight(iref);
            size_t length       = width * height * 4;
            uint32_t *pixels    = (uint32_t *)malloc(length);
            
            CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * 4,
                                                         CGImageGetColorSpace(iref), kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big);
            
            CGAffineTransform transform = CGAffineTransformIdentity;
            transform                   = CGAffineTransformMakeTranslation(0.0f, height);
            transform                   = CGAffineTransformScale(transform, 1.0, -1.0);
            CGContextConcatCTM(context, transform);
            CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
            CGImageRef outputRef    = CGBitmapContextCreateImage(context);
            outputImage             = [UIImage imageWithCGImage: outputRef];
            
            CGColorSpaceRelease(colorSpaceRef);
            CGDataProviderRelease(ref);
            CGImageRelease(iref);
            CGContextRelease(context);
            CGImageRelease(outputRef);
            free(pixels);
            free(buffer);
            
            [CustomAlbum addNewAssetWithImage:outputImage toAlbum:[CustomAlbum getMyAlbumWithName:CSAlbum] onSuccess:^(NSString *ImageId) {
                NSLog(@"%@",ImageId);
                self.recentImg = ImageId;
            } onError:^(NSError *error) {
                NSLog(@"probelm in saving image");
            } onFinish:^(NSString *finish) {
                
                PHAssetCollection *collection = [CustomAlbum getMyAlbumWithName:CSAlbum];
                [CustomAlbum getImageWithCollection:collection onSuccess:^(UIImage *image) {
                    self.galleryImageView.image = image;
                    
                    [UIView animateWithDuration:0.3f animations:^(void) {
                        [self.galleryImageView.layer addAnimation:[OSRootViewController showAnimationGroup] forKey:nil];
                    }];
                    
                } onError:^(NSError *error) {
                    NSLog(@"Not Found!");
                }];
            }];
        }
        @catch (NSException *exception) {
            // do nothing
            NSLog(@"Error in capture %@", exception.description);

        }
        

//    } catch (NSError *error) {
//        NSLog(@"Error in capture");
//    }
    
    [UIView animateWithDuration:0.1f
                     animations: ^{
                         self.view.alpha = 0.0f;
                     } completion: ^(BOOL finished) {
                         self.view.alpha = 1.0f;
                     }];
}

@end

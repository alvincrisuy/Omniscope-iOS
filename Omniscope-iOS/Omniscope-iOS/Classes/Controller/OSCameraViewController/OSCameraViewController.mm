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

#import "OSRootViewController.h"
#import "OSAboutViewController.h"
#import "OSGalleryViewController.h"

#import "UIDevice+DeviceType.h"
#import "NSString+DeviceType.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "CustomAlbum.h"

NSString *const CSAlbum = @"Omniscope";
NSString *const CSAssetIdentifier = @"assetIdentifier";
NSString *const CSAlbumIdentifier = @"albumIdentifier";

@interface OSCameraViewController ()

@property (nonatomic, retain) NSString *albumId;
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
    QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_TRIGGERAUTO);
}

- (void)doubleTapGestureAction:(UITapGestureRecognizer*)theGesture {
    
    OSAboutViewController *aboutViewController = [OSRootViewController sharedController].aboutViewController;
    
    [[OSRootViewController sharedController] presentViewController:aboutViewController animated:YES completion:^{
        
    }];
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
    } else {
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

- (void)createAlbum {
    [CustomAlbum makeAlbumWithTitle:CSAlbum onSuccess:^(NSString *AlbumId) {
        NSLog(@"album: %@", AlbumId);
        self.albumId = AlbumId;
     } onError:^(NSError *error) {
        NSLog(@"problem in creating album");
    }];
}

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
    
    CGRect doubleTapRect = CGRectZero;
    
    switch ([[UIDevice currentDevice] getDeviceTypeScreenXIB]) {
        case UIDeviceTypeScreenXIB35:
            doubleTapRect = CGRectMake(0, 0, 320, 480);
            break;
        case UIDeviceTypeScreenXIB4:
            doubleTapRect = CGRectMake(0, 0, 320, 568);
            break;
        case UIDeviceTypeScreenXIB47:
            doubleTapRect = CGRectMake(0, 0, 375, 667);
            break;
        case UIDeviceTypeScreenXIB55:
            doubleTapRect = CGRectMake(0, 0, 414, 736);
            break;
        case UIDeviceTypeScreenXIB97:
            doubleTapRect = CGRectMake(0, 0, 320, 480);
            break;
        case UIDeviceTypeScreenXIB129:
            doubleTapRect = CGRectMake(0, 0, 320, 480);
            break;
    }
    
    UIView *doubleTapView = [[UIView alloc] initWithFrame:doubleTapRect];
    [self.view addSubview:doubleTapView];
    
    OSAppDelegate *appDelegate = (OSAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = self.cameraView;
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.cameraView.layer;
    eaglLayer.opaque = TRUE;
    
    eaglLayer.drawableProperties = @{
                                     kEAGLDrawablePropertyRetainedBacking: [NSNumber numberWithBool:YES],
                                     kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8,
                                     };
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat captureButtonX = (screenRect.size.width / 2.0f) - 75/2;
    CGFloat captureButtonY = (screenRect.size.height - 75.0f * 1.5f);
    
    self.captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.captureButton addTarget:self
               action:@selector(captureButtonAction:)
     forControlEvents:UIControlEventTouchUpInside];
    [self.captureButton setImage:[UIImage imageNamed:@"capture150"] forState:UIControlStateNormal];
    [self.captureButton setImage:[UIImage imageNamed:@"capture150selected"] forState:UIControlStateSelected];
    [self.captureButton setImage:[UIImage imageNamed:@"capture150selected"] forState:UIControlStateFocused];
    [self.captureButton setImage:[UIImage imageNamed:@"capture150selected"] forState:UIControlStateHighlighted];
    self.captureButton.frame = CGRectMake(captureButtonX, captureButtonY, 75.0f, 75.0f);
    self.captureButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    self.captureButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;

    [self.view addSubview:self.captureButton];
    
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
//        [galleryButton setImage:image forState:UIControlStateNormal];
        galleryButton.frame = CGRectMake(galleryButtonX, galleryButtonY, 45.0, 45.0);
        [self.view addSubview:galleryButton];

    } onError:^(NSError *error) {
        NSLog(@"Not Found!");
    }];

    CGFloat frontBackButtonX = screenRect.size.width/2.0f + screenRect.size.width/4.0f;
    CGFloat frontBackButtonY = (screenRect.size.height - 60.0f * 1.5f);
    
    self.frontBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.frontBackButton addTarget:self
                      action:@selector(frontBackButtonAction:)
            forControlEvents:UIControlEventTouchUpInside];
    [self.frontBackButton setImage:[UIImage imageNamed:@"arrows-1"] forState:UIControlStateNormal];
    self.frontBackButton.frame = CGRectMake(frontBackButtonX, frontBackButtonY, 30.0, 30.0);
    self.frontBackButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    self.frontBackButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.frontBackButton.alpha = 0.5f;

    [self.view addSubview:self.frontBackButton];
    
    // double tap used to also trigger the menu
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doubleTapGestureAction:)];
    doubleTap.numberOfTapsRequired = 2;
    [doubleTapView addGestureRecognizer:doubleTap];
    
    // a single tap will trigger a single autofocus operation
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];
    if (doubleTap != NULL) {
        [tapGestureRecognizer requireGestureRecognizerToFail:doubleTap];
    }
    
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
    [vapp initAR:QCAR::GL_20 orientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    // show loading animation while AR is being initialized
    [self showLoadingAnimation];
    
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
}

- (void) orientationChanged:(NSNotification *)note {
    UIDevice * device = note.object;
    switch(device.orientation) {
        case UIDeviceOrientationPortrait:
            NSLog(@"portrait");
        {
            [UIView animateWithDuration:0.3 animations:^{
                self.galleryImageView.transform = CGAffineTransformMakeRotation(0);
                self.captureButton.transform = CGAffineTransformMakeRotation(0);
                self.frontBackButton.transform = CGAffineTransformMakeRotation(0);
            }];
            
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"upside down");
            
        {
            [UIView animateWithDuration:0.3 animations:^{
                self.galleryImageView.transform = CGAffineTransformMakeRotation(-3.14159265358979);
                self.captureButton.transform = CGAffineTransformMakeRotation(-3.14159265358979);
                self.frontBackButton.transform = CGAffineTransformMakeRotation(-3.14159265358979);
            }];
            
        }
            
            break;
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"landscape left");
            
        {
            [UIView animateWithDuration:0.3 animations:^{
                self.galleryImageView.transform = CGAffineTransformMakeRotation(3.14159265358979/2);
                self.captureButton.transform = CGAffineTransformMakeRotation(3.14159265358979/2);
                self.frontBackButton.transform = CGAffineTransformMakeRotation(3.14159265358979/2);
            }];
            
        }
            
            
            break;
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"landscape right");
            
        {
            [UIView animateWithDuration:0.3 animations:^{
                self.galleryImageView.transform = CGAffineTransformMakeRotation(-3.14159265358979/2);
                self.captureButton.transform = CGAffineTransformMakeRotation(-3.14159265358979/2);
                self.frontBackButton.transform = CGAffineTransformMakeRotation(-3.14159265358979/2);
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
    
    OSGalleryViewController *galleryViewController = [OSRootViewController sharedController].galleryViewController;
    
    [[OSRootViewController sharedController].contentNavigationController presentViewController:galleryViewController animated:YES completion:^{
        
    }];
}

- (IBAction)captureButtonAction:(id)sender {
    NSLog(@"capture");
    
    AudioServicesPlaySystemSoundWithCompletion(1108, ^{
        
        
        
    });
    
    UIImage *outputImage = nil;
    
    CGFloat widthScale = 0;
    CGFloat heightScale = 0;
    
    switch ([[UIDevice currentDevice] getDeviceTypeScreenXIB]) {
        case UIDeviceTypeScreenXIB35:
            widthScale = 320.0f;
            heightScale = 480.0f;
            break;
        case UIDeviceTypeScreenXIB4:
            
            widthScale = 320.0f;
            heightScale = 568.0f;
            break;
        case UIDeviceTypeScreenXIB47:
            
            widthScale = 375.0f;
            heightScale = 667.0f;
            break;
        case UIDeviceTypeScreenXIB55:
            
            widthScale = 414.0f;
            heightScale = 736.0f;
            break;
        case UIDeviceTypeScreenXIB97:
            
            widthScale = 320.0f;
            heightScale = 480.0f;
            break;
        case UIDeviceTypeScreenXIB129:
            
            widthScale = 320.0f;
            heightScale = 480.0f;
            break;
    }
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGRect s = CGRectMake(0, 0, widthScale * scale, heightScale * scale);
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
                [self.galleryImageView.layer addAnimation:[OSCameraViewController showAnimationGroup_] forKey:nil];
            }];
            
        } onError:^(NSError *error) {
            NSLog(@"Not Found!");
        }];
        
        
    }];
    
    [UIView animateWithDuration: 0.2
                     animations: ^{
                         self.view.alpha = 0.0f;
                     }
                     completion: ^(BOOL finished) {
                         self.view.alpha = 1.0f;
                     }
     ];
}

+ (CAAnimationGroup*)showAnimationGroup_
{
    static CAAnimationGroup* showAnimationGroup_ = nil;
    
    if (!showAnimationGroup_) {
        CABasicAnimation* opacityAnime;
        opacityAnime           = [[CABasicAnimation alloc] init];
        opacityAnime.keyPath   = @"opacity";
        opacityAnime.duration  = 0.3f;
        opacityAnime.fromValue = [NSNumber numberWithFloat:0.0f];
        opacityAnime.toValue   = [NSNumber numberWithFloat:1.0f];
        
        NSArray* valArraay;
        valArraay = [[NSArray alloc] initWithObjects:
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, 0.5)],
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1, 1.1, 1.1)],
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 0.9)],
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)], nil];
        
        CAKeyframeAnimation* scaleAnime;
        scaleAnime          = [[CAKeyframeAnimation alloc] init];
        scaleAnime.keyPath  = @"transform";
        scaleAnime.duration = 0.32f;
        scaleAnime.values   = valArraay;
        
        NSArray* animeArraay;
        animeArraay = [[NSArray alloc] initWithObjects:
                       opacityAnime,
                       scaleAnime, nil];
        
        showAnimationGroup_            = [[CAAnimationGroup alloc] init];
        showAnimationGroup_.duration   = 0.32;
        showAnimationGroup_.animations = animeArraay;
    }
    
    return showAnimationGroup_;
}

- (IBAction)frontBackButtonAction:(id)sender {
    NSLog(@"frontback");

    NSError * error = nil;
    if ([vapp stopCamera:&error]) {
        if (self.frontCameraEnabled) {
            bool result = [vapp startAR:QCAR::CameraDevice::CAMERA_BACK error:&error];
            self.frontCameraEnabled = !result;
            
            UIDevice * device = [UIDevice currentDevice];
            switch(device.orientation) {
                case UIDeviceOrientationPortrait:
                    NSLog(@"portrait");
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        self.frontBackButton.transform = CGAffineTransformMakeRotation(0);
                    }];
                    
                }
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    NSLog(@"upside down");
                    
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        self.frontBackButton.transform = CGAffineTransformMakeRotation(-3.14159265358979);
                    }];
                    
                }
                    
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    NSLog(@"landscape left");
                    
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        self.frontBackButton.transform = CGAffineTransformMakeRotation(3.14159265358979/2);
                    }];
                    
                }
                    
                    
                    break;
                case UIDeviceOrientationLandscapeRight:
                    NSLog(@"landscape right");
                    
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        self.frontBackButton.transform = CGAffineTransformMakeRotation(-3.14159265358979/2);
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
            
            UIDevice * device = [UIDevice currentDevice];
            switch(device.orientation) {
                case UIDeviceOrientationPortrait:
                    NSLog(@"portrait");
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        self.frontBackButton.transform = CGAffineTransformMakeRotation(-3.14159265358979);
                    }];
                    
                }
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    NSLog(@"upside down");
                    
                {
                    
                    [UIView animateWithDuration:0.3 animations:^{
                        self.frontBackButton.transform = CGAffineTransformMakeRotation(0);
                    }];
                    
                }
                    
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    NSLog(@"landscape left");
                    
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        self.frontBackButton.transform = CGAffineTransformMakeRotation(-3.14159265358979/2);
                    }];
                    
                    
                }
                    
                    
                    break;
                case UIDeviceOrientationLandscapeRight:
                    NSLog(@"landscape right");
                    
                {
                    [UIView animateWithDuration:0.3 animations:^{
                        self.frontBackButton.transform = CGAffineTransformMakeRotation(3.14159265358979/2);
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
            
            
            QCAR::setHint(QCAR::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, 5);
            
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
    
//    NSLog(@"ENTER assetsPickerController");
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end

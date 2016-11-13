//
//  OSRootViewController.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CircleProgressBar/CircleProgressBar.h>

@class OSAboutViewController;
@class OSCameraViewController;
@class OSGalleryViewController;
@class OSImageViewController;
@class OSHelpViewController;
@class OSLocationViewController;

typedef NS_ENUM(NSInteger, TabBarButtonTag) {
    Gallery             = 0,
    Capture             = 1,
    OtherInformation    = 2,
};

typedef NS_ENUM(NSInteger, SideBarButtonTag) {
    Row0 = 0,
    Row1 = 1,
    Row2 = 2,
    Row3 = 3,
    Row4 = 4,
    Row5 = 5,
    Row6 = 6,
};

@protocol OSRootViewControllerDelegate <NSObject>

@optional

- (void)galleryTabButtonAction:(UIButton *)sender;
- (void)captureTabButtonAction:(UIButton *)sender;
- (void)otherInformationTabButtonAction:(UIButton *)sender;

- (void)startRecordTabButtonAction;
- (void)endRecordTabButtonAction;

- (void)row0SideButtonAction:(UIButton *)sender;
- (void)row1SideButtonAction:(UIButton *)sender;
- (void)row2SideButtonAction:(UIButton *)sender;
- (void)row3SideButtonAction:(UIButton *)sender;
- (void)row4SideButtonAction:(UIButton *)sender;

@end

@interface OSRootViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) id <OSRootViewControllerDelegate> delegate;

// Rootview UIViews
@property (nonatomic, retain) IBOutlet UIView *navigationView;
@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIView *tabView;

@property (nonatomic, retain) IBOutlet UIView *tabWithCircleView;

@property (nonatomic, retain) IBOutlet NSLayoutConstraint *navigationViewHeight;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint *tabViewHeight;

// Tab Bar Buttons
@property (nonatomic, retain) IBOutlet UIButton *galleryTabButton;
@property (nonatomic, retain) IBOutlet UIButton *otherInformationTabButton;
@property (nonatomic, assign) TabBarButtonTag selectedButtonTag;
@property (nonatomic, retain) NSArray *tabBar;
@property (nonatomic, retain) IBOutlet UIView *galleryTabView;
@property (nonatomic, retain) IBOutlet UIView *captureTabView;
@property (nonatomic, retain) IBOutlet UIView *otherInformationTabView;
@property (nonatomic, retain) NSArray *tabBarViews;

@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, retain) NSTimer *timeRecording;
@property (nonatomic, assign) CGFloat recordProgress;
@property (nonatomic, retain) IBOutlet UIView *captureTabView2;
@property (nonatomic, retain) IBOutlet UIImageView *captureTabImageView;
@property (nonatomic, retain) IBOutlet UIImageView *captureTabRecordImageView;
@property (nonatomic, retain) IBOutlet CircleProgressBar *circularProgress;
@property (nonatomic, retain) IBOutlet UIButton *captureTabButton;

// Side Bar Buttons
@property (nonatomic, retain) IBOutlet UITableView *sideBarTableView;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint *sideBarTableViewWidth;
@property (nonatomic, assign) BOOL isSideBarTableViewDisplay;

// Navigation Controller - Navigate Pages
@property (nonatomic, retain) UINavigationController *contentNavigationController;

@property (nonatomic, retain) UIView *backButtonView;
@property (nonatomic, retain) UIButton *backButton;

// Transitions
- (void)transitionAbout;
- (void)transitionCamera;
- (void)transitionGallery;
- (void)transitionImage;
- (void)transitionHelp;
- (void)transitionLocation;

- (void)transition:(UIViewController *)viewController animated:(BOOL)animated;
- (void)popTransitionAnimated:(BOOL)animated;
- (void)pushTransition:(UIViewController *)viewController animated:(BOOL)animated;

- (void)showNavigationView;
- (void)hideNavigationView;

- (void)showSideTableView;
- (void)hideSideTableView;

- (void)showTabView;
- (void)hideTabView;

// Transfer
- (void)transferAboutViewController:(id)sender animated:(BOOL)animated;
- (void)transferCameraViewController:(id)sender animated:(BOOL)animated;
- (void)transferGalleryViewController:(id)sender animated:(BOOL)animated;
- (void)transferImageViewController:(id)sender animated:(BOOL)animated index:(NSInteger)index;
- (void)transferHelpViewController:(id)sender animated:(BOOL)animated;
- (void)transferLocationViewController:(id)sender animated:(BOOL)animated;

- (OSAboutViewController *)aboutViewController;
- (OSCameraViewController *)cameraViewController;
- (OSGalleryViewController *)galleryViewController;
- (OSImageViewController *)imageViewController;
- (OSHelpViewController *)helpViewController;
- (OSLocationViewController *)locationViewController;

// Singleton
+ (OSRootViewController *)sharedController;

// Tab Bar Buttons, Back Button Action
- (IBAction)backButtonAction:(UIButton *)sender;
- (IBAction)tabButtonAction:(UIButton *)sender;

+ (CAAnimationGroup*)showAnimationGroup;

@end

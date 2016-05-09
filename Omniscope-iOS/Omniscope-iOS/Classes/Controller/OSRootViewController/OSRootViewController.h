//
//  OSRootViewController.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSAboutViewController;
@class OSCameraViewController;
@class OSWelcomeViewController;
@class OSGalleryViewController;
@class OSImageViewController;

@interface OSRootViewController : UIViewController

// Rootview UIViews
@property (nonatomic, retain) IBOutlet UIView *navigationView;
@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIView *tabView;

@property (nonatomic, retain) IBOutlet NSLayoutConstraint *navigationViewHeight;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint *tabViewHeight;

// Navigation Controller - Navigate Pages
@property (nonatomic, retain) UINavigationController *contentNavigationController;

@property (nonatomic, retain) UIView *backButtonView;
@property (nonatomic, retain) UIButton *backButton;

// Transitions
- (void)transitionAbout;
- (void)transitionCamera;
- (void)transitionWelcome;
- (void)transitionGallery;
- (void)transitionImage;

- (void)transition:(UIViewController *)viewController animated:(BOOL)animated;
- (void)popTransitionAnimated:(BOOL)animated;
- (void)pushTransition:(UIViewController *)viewController animated:(BOOL)animated;

- (void)showNavigationView;
- (void)hideNavigationView;

- (void)showTabView;
- (void)hideTabView;

// Transfer
- (void)transferAboutViewController:(id)sender animated:(BOOL)animated;
- (void)transferCameraViewController:(id)sender animated:(BOOL)animated;
- (void)transferWelcomeViewController:(id)sender animated:(BOOL)animated;
- (void)transferGalleryViewController:(id)sender animated:(BOOL)animated;
- (void)transferImageViewController:(id)sender animated:(BOOL)animated index:(NSInteger)index;

- (OSAboutViewController *)aboutViewController;
- (OSCameraViewController *)cameraViewController;
- (OSWelcomeViewController *)welcomeViewController;
- (OSGalleryViewController *)galleryViewController;
- (OSImageViewController *)imageViewController;

// Singleton
+ (OSRootViewController *)sharedController;

@end

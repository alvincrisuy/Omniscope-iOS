//
//  OSRootViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSRootViewController.h"
#import "OSAboutViewController.h"
#import "OSCameraViewController.h"
#import "OSInstructionViewController.h"
#import "OSWelcomeViewController.h"

static OSRootViewController *_sharedController = nil;

@interface OSRootViewController () {
    OSAboutViewController *_aboutViewController;
    OSCameraViewController *_cameraViewController;
    OSInstructionViewController *_instructionViewController;
    OSWelcomeViewController *_welcomeViewController;
}

// Transition
- (void)hiddenAllPage;

// Back Button
- (IBAction)backButtonAction:(id)sender;

@end

@implementation OSRootViewController

#pragma mark - Singleton

+ (OSRootViewController *)sharedController {
    
    @synchronized(self) {
        if (_sharedController == nil) {
            _sharedController = [[self alloc] init];
        }
    }
    
    return _sharedController;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    
    _sharedController = self;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSLog(@"Size: %f %f %f %f",
          self.view.frame.size.width,
          self.view.frame.size.height,
          self.view.frame.origin.x,
          self.view.frame.origin.y);
    
    NSLog(@"Bounds: %f %f %f %f",
          self.view.bounds.size.width,
          self.view.bounds.size.height,
          self.view.bounds.origin.x,
          self.view.bounds.origin.y);
    
    [self transitionWelcome];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Back Button

- (IBAction)backButtonAction:(id)sender {
    [self popTransitionAnimated:YES];
}

#pragma mark - Transitions
- (void)transitionAbout {
    [self hiddenAllPage];
    
    [self transition:self.aboutViewController animated:NO];
}

- (void)transitionCamera {
    [self hiddenAllPage];
    
    [self transition:self.cameraViewController animated:NO];

}

- (void)transitionInstruction {
    [self hiddenAllPage];
    
    [self transition:self.instructionViewController animated:NO];
}

- (void)transitionWelcome {
    [self hiddenAllPage];
    
    [self transition:self.welcomeViewController animated:NO];
}


- (void)hiddenAllPage {
    if (self.contentNavigationController) {
        [self.contentNavigationController popToRootViewControllerAnimated:NO];
    }
    
    NSArray* views = [self.contentView subviews];
    for (UIView* view in views) {
        [view removeFromSuperview];
    }
}

- (void)transition:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.contentNavigationController != nil) {
        self.contentNavigationController = nil;
    }
    
    self.contentNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [self.contentNavigationController.view setFrame:self.contentView.bounds];
    
    self.backButtonView.alpha = 0;
    
    viewController.view.alpha = 1;
    
    CATransition* animation;
    animation      = [CATransition animation];
    animation.type = kCATransitionFade;
    {
        [self.contentView addSubview:self.contentNavigationController.view];
    }
    
    if (animated) {
        [self.contentView.layer addAnimation:animation forKey:nil];
    }
    
    [self.contentNavigationController setNavigationBarHidden:YES animated:NO];
    [self.contentNavigationController viewDidAppear:YES];
}

- (void)pushTransition:(UIViewController *)viewController animated:(BOOL)animated {
    CATransition* animation;
    animation      = [CATransition animation];
    animation.type = kCATransitionFade;
    {
        self.backButtonView.alpha = 1;
    }
    
    if (animated) {
        [self.backButtonView.layer addAnimation:animation forKey:nil];
    }
    
    viewController.view.frame = self.contentView.bounds;
    
    [self.contentNavigationController pushViewController:viewController animated:animated];
}

- (void)popTransitionAnimated:(BOOL)animated {
    [self.contentNavigationController popViewControllerAnimated:animated];
    
    if ([[self.contentNavigationController viewControllers] count] == 1) {
        CATransition* animation;
        animation      = [CATransition animation];
        animation.type = kCATransitionFade;
        {
            self.backButtonView.alpha = 0;
        }
        
        if (animated) {
            [self.backButtonView.layer addAnimation:animation forKey:nil];
        }
    }
}

- (void)showNavigationView {
    self.navigationViewHeight.constant = 60;//self.navigationView.frame.size.height;
}

- (void)hideNavigationView {
    self.navigationViewHeight.constant = 0.0f;
}

- (void)showTabView {
    self.tabViewHeight.constant = 60;//self.tabView.frame.size.height;
}

- (void)hideTabView {
    self.tabViewHeight.constant = 0.0f;
}

#pragma mark - Transfer
- (void)transferAboutViewController:(id)sender animated:(BOOL)animated {
    [self pushTransition:self.aboutViewController animated:animated];
}

- (void)transferCameraViewController:(id)sender animated:(BOOL)animated {
    [self pushTransition:self.cameraViewController animated:animated];
}

- (void)transferInstructionViewController:(id)sender animated:(BOOL)animated {
    [self pushTransition:self.instructionViewController animated:animated];
}

- (void)transferWelcomeViewController:(id)sender animated:(BOOL)animated {
    [self pushTransition:self.welcomeViewController animated:animated];
}

- (OSAboutViewController *)aboutViewController {
    if (!_aboutViewController) {
        _aboutViewController = [[OSAboutViewController alloc] init];
        _aboutViewController.view.frame = self.contentView.bounds;
    }
    
    return _aboutViewController;
}

- (OSCameraViewController *)cameraViewController {
    if (!_cameraViewController) {
        _cameraViewController = [[OSCameraViewController alloc] init];
        _cameraViewController.view.frame = self.contentView.bounds;
    }
    
    return _cameraViewController;
}

- (OSInstructionViewController *)instructionViewController {
    if (!_instructionViewController) {
        _instructionViewController = [[OSInstructionViewController alloc] init];
        _instructionViewController.view.frame = self.contentView.bounds;
    }
    
    return _instructionViewController;

}

- (OSWelcomeViewController *)welcomeViewController {
    if (!_welcomeViewController) {
        _welcomeViewController = [[OSWelcomeViewController alloc] init];
        _welcomeViewController.view.frame = self.contentView.bounds;
    }
    
    return _welcomeViewController;
}

@end

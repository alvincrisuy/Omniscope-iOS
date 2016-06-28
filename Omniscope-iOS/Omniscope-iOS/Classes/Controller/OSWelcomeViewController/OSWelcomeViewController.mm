//
//  OSWelcomeViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSWelcomeViewController.h"
#import "OSRootViewController.h"

#import "NSString+DeviceType.h"

@interface OSWelcomeViewController ()

@end

@implementation OSWelcomeViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:[NSStringFromClass([OSWelcomeViewController class]) concatenateClassToDeviceType] bundle:nibBundleOrNil]) {
        // Custom initialization
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.pressToStartButton.alpha = 0.0f;
    self.pressToStartLabel.alpha = 0.0f;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[OSRootViewController sharedController] hideNavigationView];
    [[OSRootViewController sharedController] hideTabView];
    [[OSRootViewController sharedController] hideSideTableView];
    
    [NSTimer scheduledTimerWithTimeInterval:3.0
                                     target:self
                                   selector:@selector(showPressToStart)
                                   userInfo:nil
                                    repeats:NO];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(animateLogo)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)hideLoading {
    
    [self.loadingIndicatorView stopAnimating];
    
}

- (void)showPressToStart {
    
    [self.pressToStartButton setAlpha:1.0f];

    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(hideLoading)
                                   userInfo:nil
                                    repeats:NO];

    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(continuousFadeInOut) userInfo:nil repeats:YES];

}

- (void)continuousFadeInOut {
    
    [UIView animateWithDuration:0.5 animations:^{
        
        [self.pressToStartLabel setAlpha:1.0f];
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.5 animations:^{
            
            [self.pressToStartLabel setAlpha:0.0f];
            
        } completion:^(BOOL finished) {
            
        }];
        
    }];
}

- (void)animateLogo {
    
    CATransition* animation;
    animation      = [CATransition animation];
    animation.type = kCATransitionFade;
    {
        [self.omniscopeView setAlpha:1.0f];
    }
    
    [self.omniscopeView.layer addAnimation:animation forKey:nil];
    
}

- (void)transitionCamera {
    
    [[OSRootViewController sharedController] transitionCamera];
    
}

- (IBAction)pressToStartButtonAction:(UIButton *)sender {
    
    NSLog(@"transition camera");
    
    [self transitionCamera];
    
}
@end

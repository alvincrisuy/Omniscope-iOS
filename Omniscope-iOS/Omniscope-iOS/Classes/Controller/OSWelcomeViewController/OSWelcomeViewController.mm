//
//  OSWelcomeViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSWelcomeViewController.h"
#import "OSRootViewController.h"

@interface OSWelcomeViewController ()

@end

@implementation OSWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[OSRootViewController sharedController] hideNavigationView];
    [[OSRootViewController sharedController] hideTabView];
    
    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(transitionCamera)
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

- (void)animateLogo {
    
    CATransition* animation;
    animation      = [CATransition animation];
    animation.type = kCATransitionFade;
    {
        self.omniscopeLabel.alpha = 1.0f;
    }
    
    [self.omniscopeLabel.layer addAnimation:animation forKey:nil];

}

- (void)transitionCamera {
    
    [[OSRootViewController sharedController] transitionCamera];
    
}

@end

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[OSRootViewController sharedController] hideNavigationView];
    [[OSRootViewController sharedController] hideTabView];
    
    [NSTimer scheduledTimerWithTimeInterval:3.0
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

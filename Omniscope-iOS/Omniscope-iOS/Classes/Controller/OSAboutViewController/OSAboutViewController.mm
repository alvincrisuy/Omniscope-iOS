//
//  OSAboutViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSAboutViewController.h"
#import "OSRootViewController.h"

#import "NSString+DeviceType.h"

@interface OSAboutViewController ()

@end

@implementation OSAboutViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:[NSStringFromClass([OSAboutViewController class]) concatenateClassToDeviceType] bundle:nibBundleOrNil]) {
        // Custom initialization
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)closeButtonAction:(UIButton *)sender {
    
    [[OSRootViewController sharedController] dismissViewControllerAnimated:YES completion:^{
        
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

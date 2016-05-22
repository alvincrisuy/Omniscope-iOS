//
//  OSWelcomeViewController.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSWelcomeViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIView *omniscopeView;
@property (nonatomic, retain) IBOutlet UILabel *omniscopeLabel;
@property (nonatomic, retain) IBOutlet UIButton *pressToStartButton;
@property (nonatomic, retain) IBOutlet UILabel *pressToStartLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *loadingIndicatorView;

- (IBAction)pressToStartButtonAction:(UIButton *)sender;

@end
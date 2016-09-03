//
//  OSWelcomeView.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSWelcomeView : UIView

@property (nonatomic, retain) IBOutlet UIView *omniscopeView;
@property (nonatomic, retain) IBOutlet UILabel *omniscopeLabel;
@property (nonatomic, retain) IBOutlet UIButton *pressToStartButton;
@property (nonatomic, retain) IBOutlet UILabel *pressToStartLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *loadingIndicatorView;

+ (instancetype)viewFromNib;

- (void)setup;
- (void)show;

@end

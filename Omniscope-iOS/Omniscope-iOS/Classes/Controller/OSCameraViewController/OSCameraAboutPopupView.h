//
//  OSCameraAboutPopupView.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 13/03/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSCameraAboutPopupView : UIView
@property (nonatomic, retain) IBOutlet UIView *contentView;

@property (nonatomic, retain) IBOutlet UIButton *okButton;

@property (nonatomic, retain) id delegate;

+ (id)viewFromNib;
- (void)show;

- (IBAction)okButtonAction:(UIButton *)sender;

@end

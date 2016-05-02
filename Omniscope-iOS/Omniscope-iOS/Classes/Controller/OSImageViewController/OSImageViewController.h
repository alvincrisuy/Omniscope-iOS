//
//  OSImageViewController.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 30/04/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSImageViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIButton *closeButton;
@property (nonatomic, retain) IBOutlet UIButton *shareButton;
@property (nonatomic, assign) NSInteger index;

@end
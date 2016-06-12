//
//  OSGalleryImagePopupView.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 09/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface OSGalleryImagePopupView : UIView <UIScrollViewDelegate>

@property (nonatomic, retain) PHAssetCollection *collection;
@property (nonatomic, retain) IBOutlet UIButton *okButton;
@property (nonatomic, retain) IBOutlet UIButton *shareButton;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *pageControl;
@property (nonatomic, assign) NSInteger totalPages;

@property (nonatomic, assign) NSInteger pages;

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, retain) id delegate;

+ (id)viewFromNib;
- (void)show;

- (IBAction)okButtonAction:(UIButton *)sender;
- (IBAction)shareButtonAction:(UIButton *)sender;

@end

//
//  OSGalleryImageBannerView.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 09/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSGalleryImageBannerView : UIView

@property (nonatomic, retain) IBOutlet UIImageView *imageView;

+ (id)loadNib:(NSInteger)index;

@end

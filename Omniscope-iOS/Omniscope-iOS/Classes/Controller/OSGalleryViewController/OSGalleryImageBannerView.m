//
//  OSGalleryImageBannerView.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 09/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSGalleryImageBannerView.h"
#import "NSString+DeviceType.h"

@implementation OSGalleryImageBannerView

+ (id)loadNib:(NSInteger)index {
    UINib* nib = [UINib nibWithNibName:[NSStringFromClass([OSGalleryImageBannerView class]) concatenateClassToDeviceType] bundle:[NSBundle mainBundle]];
    
    NSArray* nibArray = [nib instantiateWithOwner:nil options:nil];
    
    OSGalleryImageBannerView* bannerView = (OSGalleryImageBannerView *)[nibArray objectAtIndex:index];
    
    return bannerView;
}

@end

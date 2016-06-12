//
//  OSHelpBannerView.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 05/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSHelpBannerView.h"
#import "UIDevice+DeviceType.h"
#import "NSString+DeviceType.h"

@implementation OSHelpBannerView

+ (id)loadNib:(NSInteger)index {
    UINib* nib = [UINib nibWithNibName:[NSStringFromClass([OSHelpBannerView class]) concatenateClassToDeviceType] bundle:[NSBundle mainBundle]];
    
    NSArray* nibArray = [nib instantiateWithOwner:nil options:nil];
    
    OSHelpBannerView* bannerView = (OSHelpBannerView *)[nibArray objectAtIndex:index];
    
    return bannerView;
}

@end

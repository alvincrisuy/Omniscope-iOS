//
//  OSAboutTableViewCell.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 05/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSAboutTableViewCell.h"
#import "UIDevice+DeviceType.h"
#import "NSString+DeviceType.h"

#define kOSAboutTableViewCellRowHeight0 420.0f

@implementation OSAboutTableViewCell

+ (instancetype)cellFromNib:(NSInteger)index {
    NSArray* array;
    array = [[NSBundle mainBundle] loadNibNamed:[NSStringFromClass([OSAboutTableViewCell class]) concatenateClassToDeviceType]
                                          owner:nil
                                        options:nil];
    
    if (!array || ![array count]) {
        return nil;
    }
    
    OSAboutTableViewCell *cell = [array objectAtIndex:index];
    [cell setBackgroundColor:[UIColor clearColor]];
    
    return cell;
}

+ (CGFloat)cellHeightWithStyle:(OSAboutTableViewCellStyleRow)style {
    switch (style) {
        case OSAboutTableViewCellStyleRow0:
        {
            switch ([[UIDevice currentDevice] getDeviceTypeScreenXIB]) {
                case UIDeviceTypeScreenXIB35:
                    return kOSAboutTableViewCellRowHeight0;
                    break;
                case UIDeviceTypeScreenXIB4:
                    return kOSAboutTableViewCellRowHeight0 + 88;
                    break;
                case UIDeviceTypeScreenXIB47:
                    return kOSAboutTableViewCellRowHeight0 + 187;
                    break;
                case UIDeviceTypeScreenXIB55:
                    return kOSAboutTableViewCellRowHeight0 + 256;
                    break;
                case UIDeviceTypeScreenXIB97:
                    return kOSAboutTableViewCellRowHeight0;
                    break;
                case UIDeviceTypeScreenXIB129:
                    return kOSAboutTableViewCellRowHeight0;
                    break;
            }
        }
    }
}

@end

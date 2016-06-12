//
//  OSRootTableViewCell.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 05/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSRootTableViewCell.h"
#import "UIDevice+DeviceType.h"
#import "NSString+DeviceType.h"

#define kOSRootTableViewCellRowHeight0 85.0f
#define kOSRootTableViewCellRowHeight1 85.0f
#define kOSRootTableViewCellRowHeight2 85.0f
#define kOSRootTableViewCellRowHeight3 85.0f

@implementation OSRootTableViewCell

+ (instancetype)cellFromNib:(NSInteger)index {
    NSArray* array;
    array = [[NSBundle mainBundle] loadNibNamed:[NSStringFromClass([OSRootTableViewCell class]) concatenateClassToDeviceType]
                                          owner:nil
                                        options:nil];
    
    if (!array || ![array count]) {
        return nil;
    }
    
    OSRootTableViewCell *cell = [array objectAtIndex:index];
    [cell setBackgroundColor:[UIColor clearColor]];
    
    return cell;
}

+ (CGFloat)cellHeightWithStyle:(OSRootTableViewCellStyleRow)style {
    switch (style) {
        case OSRootTableViewCellStyleRow0:
        {
            switch ([[UIDevice currentDevice] getDeviceTypeScreenXIB]) {
                case UIDeviceTypeScreenXIB35:
                    return kOSRootTableViewCellRowHeight0;
                    break;
                case UIDeviceTypeScreenXIB4:
                    return kOSRootTableViewCellRowHeight0 + 22;
                    break;
                case UIDeviceTypeScreenXIB47:
                    return kOSRootTableViewCellRowHeight0 + 35;
                    break;
                case UIDeviceTypeScreenXIB55:
                    return kOSRootTableViewCellRowHeight0 + 64;
                    break;
                case UIDeviceTypeScreenXIB97:
                    return kOSRootTableViewCellRowHeight0;
                    break;
                case UIDeviceTypeScreenXIB129:
                    return kOSRootTableViewCellRowHeight0;
                    break;
            }
        }
        case OSRootTableViewCellStyleRow1:
        {
            switch ([[UIDevice currentDevice] getDeviceTypeScreenXIB]) {
                case UIDeviceTypeScreenXIB35:
                    return kOSRootTableViewCellRowHeight1;
                    break;
                case UIDeviceTypeScreenXIB4:
                    return kOSRootTableViewCellRowHeight1 + 22;
                    break;
                case UIDeviceTypeScreenXIB47:
                    return kOSRootTableViewCellRowHeight1 + 35;
                    break;
                case UIDeviceTypeScreenXIB55:
                    return kOSRootTableViewCellRowHeight1 + 64;
                    break;
                case UIDeviceTypeScreenXIB97:
                    return kOSRootTableViewCellRowHeight1;
                    break;
                case UIDeviceTypeScreenXIB129:
                    return kOSRootTableViewCellRowHeight1;
                    break;
            }
        }
        case OSRootTableViewCellStyleRow2:
        {
            switch ([[UIDevice currentDevice] getDeviceTypeScreenXIB]) {
                case UIDeviceTypeScreenXIB35:
                    return kOSRootTableViewCellRowHeight2;
                    break;
                case UIDeviceTypeScreenXIB4:
                    return kOSRootTableViewCellRowHeight2 + 22;
                    break;
                case UIDeviceTypeScreenXIB47:
                    return kOSRootTableViewCellRowHeight2 + 35;
                    break;
                case UIDeviceTypeScreenXIB55:
                    return kOSRootTableViewCellRowHeight2 + 64;
                    break;
                case UIDeviceTypeScreenXIB97:
                    return kOSRootTableViewCellRowHeight2;
                    break;
                case UIDeviceTypeScreenXIB129:
                    return kOSRootTableViewCellRowHeight2;
                    break;
            }
        }
        case OSRootTableViewCellStyleRow3:
        {
            switch ([[UIDevice currentDevice] getDeviceTypeScreenXIB]) {
                case UIDeviceTypeScreenXIB35:
                    return kOSRootTableViewCellRowHeight3;
                    break;
                case UIDeviceTypeScreenXIB4:
                    return kOSRootTableViewCellRowHeight3 + 22;
                    break;
                case UIDeviceTypeScreenXIB47:
                    return kOSRootTableViewCellRowHeight3 + 35;
                    break;
                case UIDeviceTypeScreenXIB55:
                    return kOSRootTableViewCellRowHeight3 + 64;
                    break;
                case UIDeviceTypeScreenXIB97:
                    return kOSRootTableViewCellRowHeight3;
                    break;
                case UIDeviceTypeScreenXIB129:
                    return kOSRootTableViewCellRowHeight3;
                    break;
            }
        }
    }
}

@end

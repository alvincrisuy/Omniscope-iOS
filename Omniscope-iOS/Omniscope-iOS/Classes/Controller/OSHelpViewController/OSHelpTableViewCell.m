//
//  OSHelpTableViewCell.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 05/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSHelpTableViewCell.h"
#import "UIDevice+DeviceType.h"
#import "NSString+DeviceType.h"

#define kOSHelpTableViewCellRowHeight0 370.0f

@implementation OSHelpTableViewCell

+ (instancetype)cellFromNib:(NSInteger)index {
    NSArray* array;
    array = [[NSBundle mainBundle] loadNibNamed:[NSStringFromClass([OSHelpTableViewCell class]) concatenateClassToDeviceType]
                                          owner:nil
                                        options:nil];
    
    if (!array || ![array count]) {
        return nil;
    }
    
    OSHelpTableViewCell *cell = [array objectAtIndex:index];
    [cell setBackgroundColor:[UIColor clearColor]];
    
    return cell;
}

+ (CGFloat)cellHeightWithStyle:(OSHelpTableViewCellStyleRow)style {
    switch (style) {
        case OSHelpTableViewCellStyleRow0:
        {
            switch ([[UIDevice currentDevice] getDeviceTypeScreenXIB]) {
                case UIDeviceTypeScreenXIB35:
                    return kOSHelpTableViewCellRowHeight0;
                    break;
                case UIDeviceTypeScreenXIB4:
                    return kOSHelpTableViewCellRowHeight0 + 88;
                    break;
                case UIDeviceTypeScreenXIB47:
                    return kOSHelpTableViewCellRowHeight0 + 187;
                    break;
                case UIDeviceTypeScreenXIB55:
                    return kOSHelpTableViewCellRowHeight0 + 256;
                    break;
                case UIDeviceTypeScreenXIB97:
                    return kOSHelpTableViewCellRowHeight0;
                    break;
                case UIDeviceTypeScreenXIB129:
                    return kOSHelpTableViewCellRowHeight0;
                    break;
            }
        }
    }
}

@end

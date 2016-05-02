//
//  UIDevice+DeviceType.m
//  KWTG-iOS
//
//  Created by Cris Uy on 14/01/2016.
//  Copyright © 2016 Alvin Cris Uy. All rights reserved.
//

#import "UIDevice+DeviceType.h"

@implementation UIDevice (DeviceType)

- (UIDeviceTypeScreenXIB)getDeviceTypeScreenXIB {
    
    NSInteger deviceScreenHeight = [UIScreen mainScreen].bounds.size.height;
    
    UIDeviceTypeScreenXIB deviceScreen;
    
    switch (deviceScreenHeight) {
        case 480:
            deviceScreen = UIDeviceTypeScreenXIB35;
            break;
        case 568:
            deviceScreen = UIDeviceTypeScreenXIB4;
            break;
        case 667:
            deviceScreen = UIDeviceTypeScreenXIB47;
            break;
        case 736:
            deviceScreen = UIDeviceTypeScreenXIB55;
            break;
        case 1024:
            deviceScreen = UIDeviceTypeScreenXIB97;
            break;
        case 1366:
            deviceScreen = UIDeviceTypeScreenXIB129;
            break;
        default:
            deviceScreen = UIDeviceTypeScreenXIB35;
            break;
    }
    
    return deviceScreen;
}

- (BOOL)isIpad {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

@end
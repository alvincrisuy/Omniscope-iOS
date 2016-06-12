//
//  OSWelcomeView.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSWelcomeView.h"
#import "UIDevice+DeviceType.h"
#import "NSString+DeviceType.h"

@implementation OSWelcomeView

+ (instancetype)viewFromNib {
    NSArray* array;
    array = [[NSBundle mainBundle] loadNibNamed:[NSStringFromClass([OSWelcomeView class]) concatenateClassToDeviceType]
                                          owner:nil
                                        options:nil];
    
    if (!array || ![array count]) {
        return nil;
    }
    
    OSWelcomeView *view = [array objectAtIndex:0];
    view.frame = [UIScreen mainScreen].bounds;
    
    return view;
}

@end

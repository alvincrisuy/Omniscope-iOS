//
//  OSGridLinesView.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 03/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSGridLinesView.h"
#import "UIDevice+DeviceType.h"
#import "NSString+DeviceType.h"

@implementation OSGridLinesView

+ (instancetype)viewFromNib {
    NSArray* array;
    array = [[NSBundle mainBundle] loadNibNamed:[NSStringFromClass([OSGridLinesView class]) concatenateClassToDeviceType]
                                          owner:nil
                                        options:nil];
    
    if (!array || ![array count]) {
        return nil;
    }
    
    OSGridLinesView *view = [array objectAtIndex:0];
    view.frame = [UIScreen mainScreen].bounds;
    
    return view;
}

@end

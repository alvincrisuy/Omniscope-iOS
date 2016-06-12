//
//  OSAboutTableViewCell.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 05/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OSAboutTableViewCellStyleRow) {
    OSAboutTableViewCellStyleRow0 = 0,
};

@interface OSAboutTableViewCell : UITableViewCell

+ (instancetype)cellFromNib:(NSInteger)index;
+ (CGFloat)cellHeightWithStyle:(OSAboutTableViewCellStyleRow)style;

@end
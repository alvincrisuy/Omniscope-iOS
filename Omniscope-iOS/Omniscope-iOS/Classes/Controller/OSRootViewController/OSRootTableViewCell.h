//
//  OSRootTableViewCell.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 05/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OSRootTableViewCellStyleRow) {
    OSRootTableViewCellStyleRow0 = 0,
    OSRootTableViewCellStyleRow1 = 1,
    OSRootTableViewCellStyleRow2 = 2,
    OSRootTableViewCellStyleRow3 = 3,
};

@interface OSRootTableViewCell : UITableViewCell

// 0
@property (nonatomic, retain) IBOutlet UIButton *rowButton0;

// 1
@property (nonatomic, retain) IBOutlet UIButton *rowButton1;

// 2
@property (nonatomic, retain) IBOutlet UIButton *rowButton2;

// 3
@property (nonatomic, retain) IBOutlet UIButton *rowButton3;

+ (instancetype)cellFromNib:(NSInteger)index;
+ (CGFloat)cellHeightWithStyle:(OSRootTableViewCellStyleRow)style;

@end

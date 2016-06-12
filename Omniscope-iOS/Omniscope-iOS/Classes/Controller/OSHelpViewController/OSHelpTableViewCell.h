//
//  OSHelpTableViewCell.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 05/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OSHelpTableViewCellStyleRow) {
    OSHelpTableViewCellStyleRow0 = 0,
};

@interface OSHelpTableViewCell : UITableViewCell

// 0
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView0;
@property (nonatomic, retain) IBOutlet UIPageControl *pageControl0;
@property (nonatomic, assign) NSInteger totalPages0;

+ (instancetype)cellFromNib:(NSInteger)index;
+ (CGFloat)cellHeightWithStyle:(OSHelpTableViewCellStyleRow)style;

@end

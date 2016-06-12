//
//  OSHelpViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 05/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSHelpViewController.h"
#import "OSRootViewController.h"
#import "OSHelpBannerView.h"
#import "OSHelpTableViewCell.h"

#import "NSString+DeviceType.h"

@interface OSHelpViewController ()

@end

@implementation OSHelpViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] bundle:nibBundleOrNil]) {
        // Custom initialization
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:0.3f
                     animations: ^{
                         [OSRootViewController sharedController].tabView.alpha = 0.0f;
                         [OSRootViewController sharedController].sideBarTableView.alpha = 0.0f;
                     }];
}

- (void)closeButtonAction:(UIButton *)sender {
    
    [UIView animateWithDuration:0.3f
                     animations: ^{
                         [OSRootViewController sharedController].tabView.alpha = 1.0f;
                         [OSRootViewController sharedController].sideBarTableView.alpha = 1.0f;
                     }];
    
    [[OSRootViewController sharedController] popTransitionAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [OSHelpTableViewCell cellHeightWithStyle:0];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSHelpTableViewCellStyleRow index = OSHelpTableViewCellStyleRow0;
    
    static NSString *CELL_IDENTIFIER = @"0";
    
    switch (index) {
        case OSHelpTableViewCellStyleRow0:
            CELL_IDENTIFIER = @"0";
            break;
    }
    
    OSHelpTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER];
    
    if (cell == nil) {
        cell = [OSHelpTableViewCell cellFromNib:index];
    }
    
    if (index == 0) {
        for (OSHelpBannerView* bannerView in cell.scrollView0.subviews) {
            [bannerView removeFromSuperview];
        }
        
        cell.scrollView0.delegate = self;
        
        NSInteger bannerCount = 4;
        
        OSHelpBannerView* bannerView = [OSHelpBannerView loadNib:bannerCount - 1];
        
        CGRect frame = bannerView.frame;
        frame.origin.x = 0;
        bannerView.frame = frame;
        [cell.scrollView0 addSubview:bannerView];
        
        int flexWidth = 0;
        
        if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController"]) {
            flexWidth = 320;
        } else if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController~iphone4"]) {
            flexWidth = 320;
        } else if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController~iphone47"]) {
            flexWidth = 375;
        } else if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController~iphone55"]) {
            flexWidth = 414;
        }
        for (int i = 1; i <= bannerCount; i++) {
            OSHelpBannerView* bannerView = [OSHelpBannerView loadNib:i - 1];
            
            CGRect frame = bannerView.frame;
            
            frame.origin.x = flexWidth * i;
            
            bannerView.frame = frame;
            
            [cell.scrollView0 addSubview:bannerView];
        }
        
        OSHelpBannerView* bannerView_ = [OSHelpBannerView loadNib:0];
        frame = bannerView_.frame;
        frame.origin.x = flexWidth * (bannerCount + 1);
        bannerView_.frame = frame;
        [cell.scrollView0 addSubview:bannerView_];
        
        cell.scrollView0.contentSize = CGSizeMake(flexWidth * (bannerCount + 2), cell.scrollView0.frame.size.height);
        
        cell.pageControl0.numberOfPages = cell.totalPages0 = bannerCount + 2;
        
        cell.pageControl0.numberOfPages = bannerCount;
        cell.pageControl0.currentPage = 0;
        
        frame.origin.x = flexWidth * 1;
        frame.origin.y = 0;
        
        [cell.scrollView0 scrollRectToVisible:frame animated:NO];
        
    }
    
    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    OSHelpTableViewCell *rowCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    int currentPage = floor((rowCell.scrollView0.contentOffset.x - rowCell.scrollView0.frame.size.width / rowCell.totalPages0) / rowCell.scrollView0.frame.size.width) + 1;
    NSInteger setCurrentPage = 0;
    
    int flexWidth = 0;
    
    if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController"]) {
        flexWidth = 320;
    } else if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController~iphone4"]) {
        flexWidth = 320;
    } else if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController~iphone47"]) {
        flexWidth = 375;
    } else if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController~iphone55"]) {
        flexWidth = 414;
    }
    
    if (currentPage==0) {
        [rowCell.scrollView0 scrollRectToVisible:CGRectMake(flexWidth * (rowCell.totalPages0 - 2), 0, flexWidth, scrollView.frame.size.height) animated:NO];
        setCurrentPage = rowCell.totalPages0 - 2;
    } else if (currentPage == ((rowCell.totalPages0 - 2) + 1)) {
        [rowCell.scrollView0 scrollRectToVisible:CGRectMake(flexWidth, 0, flexWidth, scrollView.frame.size.height) animated:NO];
    } else {
        setCurrentPage = currentPage;
    }
    
    rowCell.pageControl0.currentPage = setCurrentPage - 1;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
    OSHelpTableViewCell *rowCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    int currentPage = floor((rowCell.scrollView0.contentOffset.x - rowCell.scrollView0.frame.size.width / rowCell.totalPages0) / rowCell.scrollView0.frame.size.width) + 1;
    NSInteger setCurrentPage = 0;
    
    int flexWidth = 0;
    
    if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController"]) {
        flexWidth = 320;
    } else if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController~iphone4"]) {
        flexWidth = 320;
    } else if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController~iphone47"]) {
        flexWidth = 375;
    } else if ([[NSStringFromClass([OSHelpViewController class]) concatenateClassToDeviceType] isEqualToString:@"OSHelpViewController~iphone55"]) {
        flexWidth = 414;
    }
    
    if (currentPage == 0) {
        setCurrentPage = rowCell.totalPages0 - 2;
        [rowCell.scrollView0 scrollRectToVisible:CGRectMake(flexWidth * (rowCell.totalPages0 - 2), 0, flexWidth, scrollView.frame.size.height) animated:NO];
    } else if (currentPage == ((rowCell.totalPages0 - 2) + 1)) {
        [rowCell.scrollView0 scrollRectToVisible:CGRectMake(flexWidth, 0, flexWidth, scrollView.frame.size.height) animated:NO];
    } else {
        setCurrentPage = currentPage;
    }
    
    rowCell.pageControl0.currentPage = setCurrentPage - 1;
}

@end

//
//  OSAboutViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSAboutViewController.h"
#import "OSRootViewController.h"
#import "OSAboutTableViewCell.h"

#import "NSString+DeviceType.h"

@interface OSAboutViewController ()

@end

@implementation OSAboutViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:[NSStringFromClass([OSAboutViewController class]) concatenateClassToDeviceType] bundle:nibBundleOrNil]) {
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
    OSAboutTableViewCellStyleRow index = (OSAboutTableViewCellStyleRow)indexPath.row;
    
    return [OSAboutTableViewCell cellHeightWithStyle:index];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSAboutTableViewCellStyleRow index = (OSAboutTableViewCellStyleRow)indexPath.row;
    
    static NSString *CELL_IDENTIFIER = @"0";
    
    switch (index) {
        case OSAboutTableViewCellStyleRow0:
            CELL_IDENTIFIER = @"0";
            break;
    }
    
    OSAboutTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER];
    
    if (cell == nil) {
        cell = [OSAboutTableViewCell cellFromNib:index];
    }
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [info objectForKey:@"CFBundleShortVersionString"];
    
    cell.versionLabel.text = [NSString stringWithFormat:@"V%@", version];
    
    return cell;
}

@end

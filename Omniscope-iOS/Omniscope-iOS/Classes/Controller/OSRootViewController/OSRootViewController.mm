//
//  OSRootViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/02/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSRootViewController.h"
#import "OSAboutViewController.h"
#import "OSCameraViewController.h"
#import "OSWelcomeViewController.h"
#import "OSGalleryViewController.h"
#import "OSImageViewController.h"
#import "OSRootTableViewCell.h"
#import "OSHelpViewController.h"
#import "OSLocationViewController.h"

#import "UIDevice+DeviceType.h"
#import "NSString+DeviceType.h"

static OSRootViewController *_sharedController = nil;

@interface OSRootViewController () {
    OSAboutViewController *_aboutViewController;
    OSCameraViewController *_cameraViewController;
    OSWelcomeViewController *_welcomeViewController;
    OSGalleryViewController *_galleryViewController;
    OSImageViewController *_imageViewController;
    OSHelpViewController *_helpViewController;
    OSLocationViewController *_locationViewController;
}

// Transition
- (void)hiddenAllPage;

@end

@implementation OSRootViewController

#pragma mark - Singleton

+ (OSRootViewController *)sharedController {
    
    @synchronized(self) {
        if (_sharedController == nil) {
            _sharedController = [[self alloc] init];
        }
    }
    
    return _sharedController;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:[NSStringFromClass([OSRootViewController class]) concatenateClassToDeviceType] bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    
    _sharedController = self;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSLog(@"Size: %f %f %f %f",
          self.view.frame.size.width,
          self.view.frame.size.height,
          self.view.frame.origin.x,
          self.view.frame.origin.y);
    
    NSLog(@"Bounds: %f %f %f %f",
          self.view.bounds.size.width,
          self.view.bounds.size.height,
          self.view.bounds.origin.x,
          self.view.bounds.origin.y);
    
    self.tabBar = [[NSArray alloc] initWithObjects:
                   self.galleryTabButton,
                   self.captureTabButton,
                   self.otherInformationTabButton, nil];
    
    self.tabBarViews = [[NSArray alloc] initWithObjects:
                        self.galleryTabView,
                        self.captureTabView,
                        self.otherInformationTabButton, nil];
    
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    
    // Create a path with the rectangle in it.
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat radius = 35.0f;
    
    CGPathAddArc(path, nil, self.tabWithCircleView.frame.size.width/2, self.tabWithCircleView.frame.size.height/2, radius, 0.0, 2 * M_PI, false);
    CGPathAddRect(path, nil, CGRectMake(0, 0, self.tabWithCircleView.frame.size.width, self.tabWithCircleView.frame.size.height));
    
    maskLayer.backgroundColor = [UIColor blackColor].CGColor;
    
    maskLayer.path = path;
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    
    // Release the path since it's not covered by ARC.
    self.tabWithCircleView.layer.mask = maskLayer;
    self.tabWithCircleView.clipsToBounds = YES;

    self.isSideBarTableViewDisplay = NO;
    
    _selectedButtonTag = Capture;
    [self setSelectedButtonTag:_selectedButtonTag];
    
    [self transitionWelcome];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button

- (IBAction)backButtonAction:(id)sender {
    [self popTransitionAnimated:YES];
}

- (IBAction)tabButtonAction:(UIButton *)sender {
    [self disselectHighlightedButton];
    
    self.selectedButtonTag = (TabBarButtonTag)[sender tag];
    
    switch (self.selectedButtonTag) {
        case Gallery:
        {
            OSGalleryViewController *galleryViewController = [OSRootViewController sharedController].galleryViewController;
            
            [[OSRootViewController sharedController].contentNavigationController presentViewController:galleryViewController animated:YES completion:^{
                
            }];
        }
            break;
        case Capture:
            [_delegate captureTabButtonAction:sender];
            break;
        case OtherInformation:
            
            self.isSideBarTableViewDisplay = !self.isSideBarTableViewDisplay;
            
            if (self.isSideBarTableViewDisplay) {
                [self showSideTableView];
            } else {
                [self hideSideTableView];
            }
            
            break;
    }
}

#pragma mark - Transitions
- (void)transitionAbout {
    [self hiddenAllPage];
    
    [self transition:self.aboutViewController animated:NO];
}

- (void)transitionCamera {
    [self hiddenAllPage];
    
    [self transition:self.cameraViewController animated:NO];
}

- (void)transitionWelcome {
    [self hiddenAllPage];
    
    [self transition:self.welcomeViewController animated:NO];
}

- (void)transitionGallery {
    [self hiddenAllPage];
    
    [self transition:self.galleryViewController animated:NO];
}

- (void)transitionImage {
    [self hiddenAllPage];
    
    [self transition:self.imageViewController animated:NO];
}

- (void)transitionHelp {
    [self hiddenAllPage];
    
    [self transition:self.helpViewController animated:NO];
}

- (void)transitionLocation {
    [self hiddenAllPage];
    
    [self transition:self.locationViewController animated:NO];
}

- (void)disselectHighlightedButton {
    [[self.tabBar objectAtIndex:self.selectedButtonTag] setSelected:NO];
}

- (void)setSelectedButtonTag:(TabBarButtonTag)selectedButtonTag {
    _selectedButtonTag = selectedButtonTag;
    if (self.tabBar) {
        
        if (selectedButtonTag != Capture) {
            [[self.tabBar objectAtIndex:selectedButtonTag] setSelected:YES];
        }
        
        [UIView animateWithDuration:0.3f animations:^(void) {
            UIButton *button = [self.tabBar objectAtIndex:selectedButtonTag];
            [button.layer addAnimation:[OSRootViewController showAnimationGroup] forKey:nil];
        }];
    }
}

- (void)hiddenAllPage {
    if (self.contentNavigationController) {
        [self.contentNavigationController popToRootViewControllerAnimated:NO];
    }
    
    NSArray* views = [self.contentView subviews];
    for (UIView* view in views) {
        [view removeFromSuperview];
    }
}

- (void)transition:(UIViewController *)viewController animated:(BOOL)animated {
    
    if ([viewController isKindOfClass:[OSCameraViewController class]] ||
        [viewController isKindOfClass:[OSGalleryViewController class]] ||
        [viewController isKindOfClass:[OSAboutViewController class]]) {
        [self setSelectedButtonTag:_selectedButtonTag];
    } else {
        [self disselectHighlightedButton];
        
        CATransition* animation;
        animation      = [CATransition animation];
        animation.type = kCATransitionFade;
        {
            self.backButtonView.alpha = 1;
        }
        
        if (animated) {
            [self.backButtonView.layer addAnimation:animation forKey:nil];
        }
    }

    if (self.contentNavigationController != nil) {
        self.contentNavigationController = nil;
    }
    
    self.contentNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [self.contentNavigationController.view setFrame:self.contentView.bounds];
    
    self.backButtonView.alpha = 0;
    
    viewController.view.alpha = 1;
    
    CATransition* animation;
    animation      = [CATransition animation];
    animation.type = kCATransitionFade;
    {
        [self.contentView addSubview:self.contentNavigationController.view];
    }
    
    if (animated) {
        [self.contentView.layer addAnimation:animation forKey:nil];
    }
    
    [self.contentNavigationController setNavigationBarHidden:YES animated:NO];
    [self.contentNavigationController viewDidAppear:YES];
}

- (void)pushTransition:(UIViewController *)viewController animated:(BOOL)animated {
    CATransition* animation;
    animation      = [CATransition animation];
    animation.type = kCATransitionFade;
    {
        self.backButtonView.alpha = 1;
    }
    
    if (animated) {
        [self.backButtonView.layer addAnimation:animation forKey:nil];
    }
    
    viewController.view.frame = self.contentView.bounds;
    
    [self.contentNavigationController pushViewController:viewController animated:animated];
}

- (void)popTransitionAnimated:(BOOL)animated {
    [self.contentNavigationController popViewControllerAnimated:animated];
    
    if ([[self.contentNavigationController viewControllers] count] == 1) {
        CATransition* animation;
        animation      = [CATransition animation];
        animation.type = kCATransitionFade;
        {
            self.backButtonView.alpha = 0;
        }
        
        if (animated) {
            [self.backButtonView.layer addAnimation:animation forKey:nil];
        }
    }
}

- (void)showNavigationView {
    self.navigationViewHeight.constant = 60;
}

- (void)hideNavigationView {
    self.navigationViewHeight.constant = 0.0f;
}

- (void)showSideTableView {
    [self.view layoutIfNeeded];

    [UIView animateWithDuration:0.3 animations:^{
        self.sideBarTableViewWidth.constant = 0.0f;
        
        [self.view layoutIfNeeded];
    }];
}

- (void)hideSideTableView {
    [self.view layoutIfNeeded];

    [UIView animateWithDuration:0.3 animations:^{
        self.sideBarTableViewWidth.constant = -106.5f;
        
        [self.view layoutIfNeeded];
    }];
}

- (void)showTabView {
    self.tabViewHeight.constant = 120;
}

- (void)hideTabView {
    self.tabViewHeight.constant = 0.0f;
}

#pragma mark - Transfer
- (void)transferAboutViewController:(id)sender animated:(BOOL)animated {
    [self pushTransition:self.aboutViewController animated:animated];
}

- (void)transferCameraViewController:(id)sender animated:(BOOL)animated {
    [self pushTransition:self.cameraViewController animated:animated];
}

- (void)transferWelcomeViewController:(id)sender animated:(BOOL)animated {
    [self pushTransition:self.welcomeViewController animated:animated];
}

- (void)transferGalleryViewController:(id)sender animated:(BOOL)animated {
    [self pushTransition:self.galleryViewController animated:animated];
}

- (void)transferImageViewController:(id)sender animated:(BOOL)animated index:(NSInteger)index {
    
    OSImageViewController *vc = self.imageViewController;
    vc.index = index;
    
    [self pushTransition:vc animated:animated];
}

- (void)transferHelpViewController:(id)sender animated:(BOOL)animated {
    [self pushTransition:self.helpViewController animated:animated];
}

- (void)transferLocationViewController:(id)sender animated:(BOOL)animated {
    [self pushTransition:self.locationViewController animated:animated];
}

- (OSAboutViewController *)aboutViewController {
    if (!_aboutViewController) {
        _aboutViewController = [[OSAboutViewController alloc] init];
        _aboutViewController.view.frame = self.contentView.bounds;
    }
    
    return _aboutViewController;
}

- (OSCameraViewController *)cameraViewController {
    if (!_cameraViewController) {
        _cameraViewController = [[OSCameraViewController alloc] init];
        _cameraViewController.view.frame = self.contentView.bounds;
    }
    
    return _cameraViewController;
}

- (OSWelcomeViewController *)welcomeViewController {
    if (!_welcomeViewController) {
        _welcomeViewController = [[OSWelcomeViewController alloc] init];
        _welcomeViewController.view.frame = self.contentView.bounds;
    }
    
    return _welcomeViewController;
}

- (OSGalleryViewController *)galleryViewController {
//    if (!_galleryViewController) {
        _galleryViewController = [[OSGalleryViewController alloc] init];
        _galleryViewController.view.frame = self.contentView.bounds;
//    }
    
    return _galleryViewController;
}

- (OSImageViewController *)imageViewController {
//    if (!_imageViewController) {
    _imageViewController = [[OSImageViewController alloc] init];
    _imageViewController.view.frame = self.contentView.bounds;
//    }
    
    return _imageViewController;
}

- (OSHelpViewController *)helpViewController {
    if (!_helpViewController) {
        _helpViewController = [[OSHelpViewController alloc] init];
        _helpViewController.view.frame = self.contentView.bounds;
    }
    
    return _helpViewController;
}

- (OSLocationViewController *)locationViewController {
    if (!_locationViewController) {
        _locationViewController = [[OSLocationViewController alloc] init];
        _locationViewController.view.frame = self.contentView.bounds;
    }
    
    return _locationViewController;
}

+ (CAAnimationGroup*)showAnimationGroup {
    static CAAnimationGroup* showAnimationGroup_ = nil;
    
    if (!showAnimationGroup_) {
        CABasicAnimation* opacityAnime;
        opacityAnime           = [[CABasicAnimation alloc] init];
        opacityAnime.keyPath   = @"opacity";
        opacityAnime.duration  = 0.3f;
        opacityAnime.fromValue = [NSNumber numberWithFloat:0.0f];
        opacityAnime.toValue   = [NSNumber numberWithFloat:1.0f];
        
        NSArray* valArraay;
        valArraay = [[NSArray alloc] initWithObjects:
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, 0.5)],
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1, 1.1, 1.1)],
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 0.9)],
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)], nil];
        
        CAKeyframeAnimation* scaleAnime;
        scaleAnime          = [[CAKeyframeAnimation alloc] init];
        scaleAnime.keyPath  = @"transform";
        scaleAnime.duration = 0.32f;
        scaleAnime.values   = valArraay;
        
        NSArray* animeArraay;
        animeArraay = [[NSArray alloc] initWithObjects:
                       opacityAnime,
                       scaleAnime, nil];
        
        showAnimationGroup_            = [[CAAnimationGroup alloc] init];
        showAnimationGroup_.duration   = 0.32;
        showAnimationGroup_.animations = animeArraay;
    }
    
    return showAnimationGroup_;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSRootTableViewCellStyleRow level = (OSRootTableViewCellStyleRow)indexPath.row;
    
    return [OSRootTableViewCell cellHeightWithStyle:level];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSRootTableViewCellStyleRow index = (OSRootTableViewCellStyleRow)indexPath.row;
    
    static NSString *CELL_IDENTIFIER = @"0";
    
    switch (index) {
        case OSRootTableViewCellStyleRow0:
            CELL_IDENTIFIER = @"0";
            break;
        case OSRootTableViewCellStyleRow1:
            CELL_IDENTIFIER = @"1";
            break;
        case OSRootTableViewCellStyleRow2:
            CELL_IDENTIFIER = @"2";
            break;
        case OSRootTableViewCellStyleRow3:
            CELL_IDENTIFIER = @"3";
            break;
        case OSRootTableViewCellStyleRow4:
            CELL_IDENTIFIER = @"4";
            break;
    }
    
    OSRootTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER];
    
    if (cell == nil) {
        cell = [OSRootTableViewCell cellFromNib:index];
    }
    
    [cell.rowButton0 addTarget:self action:@selector(rowButton0Action:) forControlEvents:UIControlEventTouchUpInside];
    [cell.rowButton1 addTarget:self action:@selector(rowButton1Action:) forControlEvents:UIControlEventTouchUpInside];
    [cell.rowButton2 addTarget:self action:@selector(rowButton2Action:) forControlEvents:UIControlEventTouchUpInside];
    [cell.rowButton3 addTarget:self action:@selector(rowButton3Action:) forControlEvents:UIControlEventTouchUpInside];
    [cell.rowButton4 addTarget:self action:@selector(rowButton4Action:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (void)rowButton0Action:(UIButton *)sender {
    [_delegate row0SideButtonAction:sender];
}

- (void)rowButton1Action:(UIButton *)sender {
    [_delegate row1SideButtonAction:sender];
}

- (void)rowButton2Action:(UIButton *)sender {
    [self transferLocationViewController:self.contentNavigationController.visibleViewController animated:YES];
}

- (void)rowButton3Action:(UIButton *)sender {
    [self transferHelpViewController:self.contentNavigationController.visibleViewController animated:YES];
}

- (void)rowButton4Action:(UIButton *)sender {
    [self transferAboutViewController:self.contentNavigationController.visibleViewController animated:YES];
}

@end

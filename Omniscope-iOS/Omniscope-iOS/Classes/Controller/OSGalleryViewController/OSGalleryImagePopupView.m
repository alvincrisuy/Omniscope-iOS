//
//  OSGalleryImagePopupView.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 09/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSGalleryImagePopupView.h"
#import "OSRootViewController.h"
#import "NSString+DeviceType.h"
#import "OSGalleryImageBannerView.h"
#import "CustomAlbum.h"

NSString *const CSAlbum2 = @"Omniscope";

@interface OSGalleryImagePopupView () {
    BOOL isShowing;
}

@end

@implementation OSGalleryImagePopupView

+ (id)viewFromNib {
    NSArray* array;
    array = [[NSBundle mainBundle] loadNibNamed:[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] owner:nil options:nil];
    if ( !array || ![array count]) {
        return nil;
    }
    
    OSGalleryImagePopupView *view = (OSGalleryImagePopupView *)[array objectAtIndex:0];
    
    return view;
}

- (void)show {
    
    self.alpha = 0.0f;
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    if (!isShowing) {
        self.center = [[[UIApplication sharedApplication] keyWindow] center];
        [UIView animateWithDuration:0.3f animations:^(void) {
            
            CATransition* animation;
            animation      = [CATransition animation];
            animation.type = kCATransitionFade;
            {
                self.alpha = 1.0f;
            }
            
            [self.layer addAnimation:animation forKey:nil];
            
//            [self.layer addAnimation:[OSGalleryImagePopupView showAnimationGroup_] forKey:nil];
            [[[UIApplication sharedApplication] keyWindow] addSubview:self];
            [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:self];
        }];
    }
    
    isShowing = YES;
    self.collection = [CustomAlbum getMyAlbumWithName:CSAlbum2];
    
    PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:self.collection options:nil];
    NSArray *assetArray = [CustomAlbum getAssets:assets];
    
    
    
    for (OSGalleryImageBannerView* bannerView in self.scrollView.subviews) {
        [bannerView removeFromSuperview];
    }
    
    self.pages = assetArray.count;
    NSInteger bannerCount = self.pages;
    int flexWidth = 0;
    
    if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView"]) {
        flexWidth = 320;
    } else if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView~iphone4"]) {
        flexWidth = 320;
    } else if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView~iphone47"]) {
        flexWidth = 375;
    } else if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView~iphone55"]) {
        flexWidth = 414;
    }
    
    for (int i = 0; i < bannerCount; i++) {
        OSGalleryImageBannerView* bannerView = [OSGalleryImageBannerView loadNib:0];
        
        [CustomAlbum getImageWithCollection:self.collection onSuccess:^(UIImage *image) {
            
            bannerView.imageView.image = image;
            
        } onError:^(NSError *error) {
            NSLog(@"Not Found!");
        } atIndex:i];
        
        CGRect frame = bannerView.frame;
        
        frame.origin.x = flexWidth * i;
        
        bannerView.frame = frame;
        
        [self.scrollView addSubview:bannerView];
    }
    
    OSGalleryImageBannerView* bannerView_ = [OSGalleryImageBannerView loadNib:0];

    CGRect frame = bannerView_.frame;
    frame.origin.x = flexWidth * (bannerCount + 1);
    
    self.scrollView.contentSize = CGSizeMake(flexWidth * bannerCount, self.scrollView.frame.size.height);
    
    frame.origin.x = flexWidth * self.index;
    frame.origin.y = 0;
    
    [self.scrollView scrollRectToVisible:frame animated:NO];
}

- (void)dismiss {
    
    if (isShowing) {
        [UIView animateWithDuration:0.3f animations:^(void) {
            [self removeFromSuperview];
        }];
    }
    isShowing = NO;
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (IBAction)okButtonAction:(UIButton *)sender {
    
    [self dismiss];
}

- (IBAction)shareButtonAction:(UIButton *)sender {
    
    // DELETE
//    [CustomAlbum deleteImageWithCollection:self.collection onSuccess:^(BOOL isSuccess) {
//        
//        if (isSuccess) {
//            
//        }
//        
//    } toAlbum:[CustomAlbum getMyAlbumWithName:CSAlbum2] onError:^(NSError *error) {
//        
//    } atIndex:self.index];
    
//    NSString *textToShare   = @"";
    NSURL *myWebsite        = [NSURL URLWithString:@"http://kebcerda.com"];
    
    OSGalleryImageBannerView* bannerView = [self.scrollView.subviews objectAtIndex:self.index];
    
    UIImage *shareImage = bannerView.imageView.image;
    NSArray *objectsToShare = @[shareImage, myWebsite];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
//    NSArray *excludeActivities = @[UIActivityTypePostToFacebook,
//                                   UIActivityTypePostToTwitter,
//                                   UIActivityTypeMessage,
//                                   UIActivityTypeMail,
//                                   UIActivityTypeAirDrop,
//                                   UIActivityTypePrint,
//                                   UIActivityTypePostToFlickr,
//                                   UIActivityTypePostToVimeo];
//
//    activityVC.excludedActivityTypes = excludeActivities;
    
    activityVC.completionWithItemsHandler = ^(NSString * __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError) {
        
        NSLog(@"%@", activityType);
        NSLog(@"%@", returnedItems);
        
        [[OSRootViewController sharedController].contentNavigationController presentViewController:(UIViewController *)[OSRootViewController sharedController].galleryViewController
                                                                                          animated:NO
                                                                                        completion:^{
                                                                                            
                                                                                            [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:self];
        }];
    };
    
    
    if ([OSRootViewController sharedController].contentNavigationController.presentedViewController) {
        [[OSRootViewController sharedController].contentNavigationController dismissViewControllerAnimated:NO completion:^{
            [[OSRootViewController sharedController].contentNavigationController presentViewController:activityVC
                                                                                              animated:YES
                                                                                            completion:^{
                                                                                                
                                                                                            }];
        }];
    } else {
        [[OSRootViewController sharedController].contentNavigationController presentViewController:activityVC
                                                                                          animated:YES
                                                                                        completion:^{
                                                                                            
                                                                                        }];
    }
}

+ (CAAnimationGroup*)showAnimationGroup_
{
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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    NSInteger currentPage = floor((self.scrollView.contentOffset.x - self.scrollView.frame.size.width / self.totalPages) / self.scrollView.frame.size.width) + 1;
    
    self.index = currentPage;
//    NSInteger setCurrentPage = 0;
//    
//    int flexWidth = 0;
//    
//    if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView"]) {
//        flexWidth = 320;
//    } else if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView~iphone4"]) {
//        flexWidth = 320;
//    } else if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView~iphone47"]) {
//        flexWidth = 375;
//    } else if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView~iphone55"]) {
//        flexWidth = 414;
//    }
//    
//    if (currentPage == 0) {
//        [self.scrollView scrollRectToVisible:CGRectMake(flexWidth * (self.totalPages - 2), 0, flexWidth, scrollView.frame.size.height) animated:NO];
//        setCurrentPage = self.totalPages - 2;
//    } else if (currentPage == ((self.totalPages - 2) + 1)) {
//        [self.scrollView scrollRectToVisible:CGRectMake(flexWidth, 0, flexWidth, scrollView.frame.size.height) animated:NO];
//    } else {
//        setCurrentPage = currentPage;
//    }
//    
//    self.pageControl.currentPage = setCurrentPage - 1;
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    NSInteger currentPage = floor((self.scrollView.contentOffset.x - self.scrollView.frame.size.width / self.totalPages) / self.scrollView.frame.size.width) + 1;
    
    self.index = currentPage;
//    NSInteger setCurrentPage = 0;
//    
//    int flexWidth = 0;
//    
//    if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView"]) {
//        flexWidth = 320;
//    } else if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView~iphone4"]) {
//        flexWidth = 320;
//    } else if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView~iphone47"]) {
//        flexWidth = 375;
//    } else if ([[NSStringFromClass([OSGalleryImagePopupView class]) concatenateClassToDeviceType] isEqualToString:@"OSGalleryImagePopupView~iphone55"]) {
//        flexWidth = 414;
//    }
//    
//    if (currentPage == 0) {
//        setCurrentPage = self.totalPages - 2;
//        [self.scrollView scrollRectToVisible:CGRectMake(flexWidth * (self.totalPages - 2), 0, flexWidth, scrollView.frame.size.height) animated:NO];
//    } else if (currentPage == ((self.totalPages - 2) + 1)) {
//        [self.scrollView scrollRectToVisible:CGRectMake(flexWidth, 0, flexWidth, scrollView.frame.size.height) animated:NO];
//    } else {
//        setCurrentPage = currentPage;
//    }
//    
//    self.pageControl.currentPage = setCurrentPage - 1;
}

@end

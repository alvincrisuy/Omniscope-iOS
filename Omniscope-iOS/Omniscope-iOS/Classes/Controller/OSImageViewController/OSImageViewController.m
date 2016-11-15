//
//  OSImageViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 30/04/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSImageViewController.h"
#import "OSRootViewController.h"
#import "OSGalleryViewController.h"
#import "CustomAlbum.h"
#import "OSImageBannerView.h"

#import "NSString+DeviceType.h"

NSString *const CSAlbum1 = @"Omniscope";

static void *ASVC_ContextCurrentPlayerItemObservation           = &ASVC_ContextCurrentPlayerItemObservation;

@interface OSImageViewController ()

@end

@implementation OSImageViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:[NSStringFromClass([OSImageViewController class]) concatenateClassToDeviceType] bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    self.collection = [CustomAlbum getMyAlbumWithName:CSAlbum1];
    
    PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:self.collection options:nil];
    NSArray *assetArray = [CustomAlbum getAssets:assets];
    
    for (OSImageBannerView* bannerView in self.scrollView.subviews) {
        [bannerView removeFromSuperview];
    }
    
    self.pages = assetArray.count;
    NSInteger bannerCount = self.pages;
    int flexWidth = self.view.frame.size.width;
    
    for (int i = 0; i < bannerCount; i++) {
        OSImageBannerView* bannerView = [OSImageBannerView loadNib:0];
        
        PHImageManager *manager = [PHImageManager defaultManager];
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        PHAsset *asset = [CustomAlbum getImageWithCollectionAsset:self.collection atIndex:i];
        
        bannerView.mediaType = asset.mediaType;
        
        switch (asset.mediaType) {
            case PHAssetMediaTypeImage:
            {
                [manager requestImageForAsset:asset targetSize:screenRect.size contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    bannerView.imageView.image = result;
                }];
            }
                break;
            case PHAssetMediaTypeVideo:
            {
                [manager requestAVAssetForVideo:asset
                                        options:nil
                                  resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                      
                                      if (i == self.index) {
                                          bannerView.isPlaying = YES;
                                      } else {
                                          bannerView.isPlaying = NO;
                                      }
                                      
                                      [bannerView setup:asset];
                }];
            }
                break;
            default:
                break;
        }

        CGRect frame = bannerView.frame;
        
        frame.origin.x = flexWidth * i;
        
        bannerView.frame = frame;
        
        [self.scrollView addSubview:bannerView];
    }
    
    OSImageBannerView* bannerView_ = [OSImageBannerView loadNib:0];
    
    CGRect frame = bannerView_.frame;
    frame.origin.x = flexWidth * (bannerCount + 1);
    
    self.scrollView.contentSize = CGSizeMake(flexWidth * bannerCount, self.scrollView.frame.size.height);
    
    self.totalPages = bannerCount;
    
    frame.origin.x = flexWidth * self.index;
    frame.origin.y = 0;
    
    [self.scrollView scrollRectToVisible:frame animated:NO];
    
    self.isHiddenOptions = YES;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [tapGesture setDelegate:self];
    [tapGesture setNumberOfTapsRequired:1];
    [self.scrollView addGestureRecognizer:tapGesture];
    
}

- (void)tapGestureAction:(UIGestureRecognizer *)sender {
    
    self.isHiddenOptions = !self.isHiddenOptions;
    
    if (self.isHiddenOptions) {
        [UIView animateWithDuration:0.3f animations:^{
            self.optionsView.alpha = 1.0f;
            [UIApplication sharedApplication].statusBarHidden = NO;
        }];
    } else {
        [UIView animateWithDuration:0.3f animations:^{
            self.optionsView.alpha = 0.0f;
            [UIApplication sharedApplication].statusBarHidden = YES;
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)okButtonAction:(UIButton *)sender {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    
    [[OSRootViewController sharedController] popPresentingTransitionAnimated:NO];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)shareButtonAction:(UIButton *)sender {
    
    OSImageBannerView* bannerView = [self.scrollView.subviews objectAtIndex:self.index];
    
    if (bannerView.mediaType == PHAssetMediaTypeVideo) {
        // share video
    } else if (bannerView.mediaType == PHAssetMediaTypeImage) {
        UIImage *shareImage = bannerView.imageView.image;
        NSArray *objectsToShare = @[shareImage];
        
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
        
        activityVC.completionWithItemsHandler = ^(NSString * __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError) {
            
            NSLog(@"%@", activityType);
            NSLog(@"%@", returnedItems);
        };
        
        [[OSRootViewController sharedController].contentNavigationController presentViewController:activityVC
                                                                                          animated:YES
                                                                                        completion:^{
                                                                                            
                                                                                        }];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger currentPage = floor((self.scrollView.contentOffset.x - self.scrollView.frame.size.width / self.totalPages) / self.scrollView.frame.size.width) + 1;
    
    self.index = currentPage;
    
    NSInteger counter = 0;
    for (OSImageBannerView *bannerView in self.scrollView.subviews) {
        if (bannerView.mediaType == PHAssetMediaTypeVideo) {
            if (counter == self.index) {
                if (bannerView.isPlaying) {
                    
                } else {
                    bannerView.isPlaying = YES;
                    [bannerView.videoView.player playItemAtIndex:0];
                }
            } else {
                bannerView.isPlaying = NO;
                [bannerView.videoView.player stop];
            }
        }
        
        counter++;
    }
    
//    OSImageBannerView *bannerView = [self.scrollView.subviews objectAtIndex:self.index];
//    if (bannerView.mediaType == PHAssetMediaTypeVideo) {
//        bannerView.isPlaying = YES;
//        [bannerView.videoView.player playItemAtIndex:0];
//    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    NSInteger currentPage = floor((self.scrollView.contentOffset.x - self.scrollView.frame.size.width / self.totalPages) / self.scrollView.frame.size.width) + 1;
    
    self.index = currentPage;
}

- (BOOL)prefersStatusBarHidden {
    return self.isHiddenOptions;
}

@end

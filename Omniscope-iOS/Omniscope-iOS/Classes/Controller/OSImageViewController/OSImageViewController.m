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

#import "NSString+DeviceType.h"

#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKShareKit/FBSDKShareDialog.h>

NSString *const CSAlbum1 = @"Omniscope";

@interface OSImageViewController () <FBSDKSharingDelegate>

@property (nonatomic, retain) PHAssetCollection *collection;

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
    
    [self.closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.shareButton addTarget:self action:@selector(shareButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.collection = [CustomAlbum getMyAlbumWithName:CSAlbum1];

    [CustomAlbum getImageWithCollection:self.collection onSuccess:^(UIImage *image) {
        
        self.imageView.image = image;
        
    } onError:^(NSError *error) {
        NSLog(@"Not Found!");
    } atIndex:self.index];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeButtonAction:(UIButton *)sender {
    
    [[OSRootViewController sharedController].contentNavigationController popViewControllerAnimated:YES];
    
    OSGalleryViewController *galleryViewController = [OSRootViewController sharedController].galleryViewController;

    [[OSRootViewController sharedController].contentNavigationController presentViewController:galleryViewController animated:YES completion:^{
        
    }];
}

- (void)shareButtonAction:(UIButton *)sender {

    FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] init];
    photo.image = self.imageView.image;
    photo.userGenerated = YES;
    FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
    content.photos = @[photo];
    content.hashtag = [FBSDKHashtag hashtagWithString:@"#Omniscope"];
    
    FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
    dialog.fromViewController = self;
    dialog.delegate = self;
    dialog.shareContent = content;
    dialog.mode = FBSDKShareDialogModeShareSheet;
    [dialog show];
    
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
    
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
    
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
    
}

@end

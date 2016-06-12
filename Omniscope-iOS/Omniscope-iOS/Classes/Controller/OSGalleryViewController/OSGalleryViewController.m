//
//  OSGalleryViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 30/04/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSGalleryViewController.h"
#import "OSRootViewController.h"
#import "CustomAlbum.h"
#import "OSGalleryImagePopupView.h"
#import "NSString+DeviceType.h"

#import "OSImageViewController.h"

#import <Photos/Photos.h>

NSString *const CSAlbum = @"Omniscope";

@interface OSGalleryViewController ()

@property (nonatomic, retain) PHAssetCollection *collection;

@end

@implementation OSGalleryViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:[NSStringFromClass([OSGalleryViewController class]) concatenateClassToDeviceType] bundle:nibBundleOrNil]) {
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
    
    [CustomAlbum makeAlbumWithTitle:CSAlbum onSuccess:^(NSString *AlbumId) {
        //        self.albumId = AlbumId;
    } onError:^(NSError *error) {
        NSLog(@"problem in creating album");
    }];
    
    self.collection = [CustomAlbum getMyAlbumWithName:CSAlbum];
    
    UINib *nib = [UINib nibWithNibName:[@"CollectionCell" concatenateClassToDeviceType] bundle: nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:@"collectionCell"];
    self.collectionView.dataSource = self;

}

- (void)closeButtonAction:(UIButton *)sender {
    
    [[OSRootViewController sharedController].contentNavigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:self.collection options:nil];
    NSArray *assetArray = [CustomAlbum getAssets:assets];

    return assetArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"collectionCell" forIndexPath:indexPath];
    
    NSInteger index = indexPath.row;
    
    [CustomAlbum getImageWithCollection:self.collection onSuccess:^(UIImage *image) {
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake(0,0,cell.frame.size.width, cell.frame.size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [cell.contentView addSubview:imageView];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width, cell.frame.size.height)];
        [button addTarget:self action:@selector(imageView:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = index;
        [cell.contentView addSubview:button];
        
    } onError:^(NSError *error) {
        
        NSLog(@"Not Found!");
    
    } atIndex:index];
    
    return cell;
}

- (void)imageView:(UIButton *)sender {
    
//    [[OSRootViewController sharedController].contentNavigationController dismissViewControllerAnimated:YES completion:^{
//        
//    }];
//    
//    [[OSRootViewController sharedController] transferImageViewController:self animated:YES index:sender.tag];
    
    OSGalleryImagePopupView *popupView = [OSGalleryImagePopupView viewFromNib];
    popupView.delegate = self;
    popupView.index = sender.tag;
    [popupView show];
}

@end

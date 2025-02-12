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
    
    [[OSRootViewController sharedController] showTabView];
    
    if ([OSRootViewController sharedController].isSideBarTableViewDisplay) {
        [[OSRootViewController sharedController] showSideTableView];
    }

    [[OSRootViewController sharedController] popPresentingTransitionAnimated:NO];
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
    
//    [CustomAlbum getImageWithCollection:self.collection onSuccess:^(UIImage *image) {
//        
//        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
//        imageView.frame = CGRectMake(0,0,cell.frame.size.width, cell.frame.size.height);
//        imageView.contentMode = UIViewContentModeScaleAspectFill;
//        [cell.contentView addSubview:imageView];
//        
//        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width, cell.frame.size.height)];
//        [button addTarget:self action:@selector(imageView:) forControlEvents:UIControlEventTouchUpInside];
//        button.tag = index;
//        [cell.contentView addSubview:button];
//        
//    } onError:^(NSError *error) {
//        
//        NSLog(@"Not Found!");
//    
//    } atIndex:index];
//    
    
    PHImageManager *manager = [PHImageManager defaultManager];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    PHAsset *asset = [CustomAlbum getImageWithCollectionAsset:self.collection atIndex:index];
    
    [manager requestImageForAsset:asset targetSize:screenRect.size contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:result];
        imageView.frame = CGRectMake(0,0,cell.frame.size.width, cell.frame.size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [cell.contentView addSubview:imageView];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width, cell.frame.size.height)];
        [button addTarget:self action:@selector(imageView:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = index;
        [cell.contentView addSubview:button];
        
        switch (asset.mediaType) {
            case PHAssetMediaTypeImage:
                break;
            case PHAssetMediaTypeVideo:
            {
                UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play"]];
                imageView.frame = CGRectMake(cell.frame.size.width/2 - cell.frame.size.width/4,
                                             cell.frame.size.height/2 - cell.frame.size.height/4,
                                             cell.frame.size.width/2,
                                             cell.frame.size.height/2);
                imageView.contentMode = UIViewContentModeScaleAspectFill;
                imageView.alpha = 0.7f;
                [cell.contentView addSubview:imageView];
                
            }
                break;
            default:
                break;
        }
    }];
    
    return cell;
}

- (void)imageView:(UIButton *)sender {
    
//    OSGalleryImagePopupView *popupView = [OSGalleryImagePopupView viewFromNib];
//    popupView.delegate = self;
//    popupView.index = sender.tag;
//    [popupView show];
    
    [[OSRootViewController sharedController] presentImageViewController:self index:sender.tag];
}

@end

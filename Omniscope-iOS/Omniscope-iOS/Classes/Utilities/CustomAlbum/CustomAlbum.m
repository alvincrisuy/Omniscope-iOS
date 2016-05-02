//
//  CustomAlbum.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 29/04/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "CustomAlbum.h"

@implementation CustomAlbum

#pragma mark - PHPhoto

+(void)makeAlbumWithTitle:(NSString *)title onSuccess:(void(^)(NSString *AlbumId))onSuccess onError: (void(^)(NSError * error)) onError
{
    //Check weather the album already exist or not
    
    if (![self getMyAlbumWithName:title]) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            // Request editing the album.
            PHAssetCollectionChangeRequest *createAlbumRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
            
            // Get a placeholder for the new asset and add it to the album editing request.
            PHObjectPlaceholder * placeHolder = [createAlbumRequest placeholderForCreatedAssetCollection];
            if (placeHolder) {
                onSuccess(placeHolder.localIdentifier);
            }
            
        } completionHandler:^(BOOL success, NSError *error) {
            NSLog(@"Finished adding asset. %@", (success ? @"Success" : error));
            if (error) {
                onError(error);
            }
        }];
    } else {
        onSuccess(title);
    }
}

+(void)addNewAssetWithImage:(UIImage *)image toAlbum:(PHAssetCollection *)album onSuccess:(void(^)(NSString *ImageId))onSuccess onError: (void(^)(NSError * error)) onError onFinish:(void(^)(NSString *finish))onFinish
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        
        // Request editing the album.
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:album];
        
        // Get a placeholder for the new asset and add it to the album editing request.
        PHObjectPlaceholder * placeHolder = [createAssetRequest placeholderForCreatedAsset];
        [albumChangeRequest addAssets:@[ placeHolder ]];
        
        NSLog(@"%@",placeHolder.localIdentifier);
        if (placeHolder) {
            onSuccess(placeHolder.localIdentifier);
        }
        
        
    } completionHandler:^(BOOL success, NSError *error) {
        NSLog(@"Finished adding asset. %@", (success ? @"Success" : error));
        
        onFinish(@"finish");
        
        if (error) {
            onError(error);
        }
    }];
}

+ (PHAssetCollection *)getMyAlbumWithName:(NSString*)AlbumName
{
#if 0
    NSString * identifier = [[NSUserDefaults standardUserDefaults]objectForKey:kAlbumIdentifier];
    if (!identifier) return nil;
    PHFetchResult *assetCollections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[identifier]
                                                                                           options:nil];
#else
    PHFetchResult *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                               subtype:PHAssetCollectionSubtypeAlbumRegular
                                                                               options:nil];
#endif
    NSLog(@"assetCollections.count = %lu", (unsigned long)assetCollections.count);
    if (assetCollections.count == 0) return nil;
    
    __block PHAssetCollection * myAlbum;
    [assetCollections enumerateObjectsUsingBlock:^(PHAssetCollection *album, NSUInteger idx, BOOL *stop) {
//        NSLog(@"album:%@", album);
//        NSLog(@"album.localizedTitle:%@", album.localizedTitle);
        if ([album.localizedTitle isEqualToString:AlbumName]) {
            myAlbum = album;
            *stop = YES;
        }
    }];
    
    if (!myAlbum) return nil;
    
    NSLog(@"album: %@", myAlbum);
    
    return myAlbum;
}

+(NSArray *)getAssets:(PHFetchResult *)fetch
{
    __block NSMutableArray * assetArray = NSMutableArray.new;
    [fetch enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
//        NSLog(@"asset:%@", asset);
        [assetArray addObject:asset];
    }];
    return assetArray;
}

+ (void)getImageWithIdentifier:(NSString*)imageId onSuccess:(void(^)(UIImage *image))onSuccess onError: (void(^)(NSError * error)) onError
{
    NSError *error = [[NSError alloc] init];
    PHFetchResult *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[imageId] options:nil];
    if (assets.count == 0) onError(error);
    
    NSArray * assetArray = [self getAssets:assets];
    PHImageManager *manager = [PHImageManager defaultManager];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    [manager requestImageForAsset:assetArray.firstObject targetSize:screenRect.size contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        onSuccess(result);
        
    }];
    
}

+ (void)getImageWithCollection:(PHAssetCollection*)collection onSuccess:(void(^)(UIImage *image))onSuccess onError: (void(^)(NSError * error)) onError
{
    NSError *error = [[NSError alloc] init];
    //    PHFetchResult *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[imageId] options:nil];
    PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    if (assets.count == 0) {
        onError(error);
    }
    
    NSArray * assetArray = [self getAssets:assets];
    PHImageManager *manager = [PHImageManager defaultManager];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    [manager requestImageForAsset:assetArray.lastObject targetSize:screenRect.size contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        onSuccess(result);
    }];
}

+ (void)getImageWithCollection:(PHAssetCollection*)collection onSuccess:(void(^)(UIImage *image))onSuccess onError: (void(^)(NSError * error)) onError atIndex:(NSInteger)index
{
    NSError *error = [[NSError alloc] init];
    PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    if (assets.count == 0) {
        onError(error);
    }
    
    NSArray * assetArray = [self getAssets:assets];
    PHImageManager *manager = [PHImageManager defaultManager];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    PHAsset *asset = [assetArray objectAtIndex:index];
    [manager requestImageForAsset:asset targetSize:screenRect.size contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        onSuccess(result);
    }];
}

@end

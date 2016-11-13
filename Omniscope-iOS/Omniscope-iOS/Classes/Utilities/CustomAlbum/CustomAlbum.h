//
//  CustomAlbum.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 29/04/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface CustomAlbum : NSObject

//Creating album with given name
+(void)makeAlbumWithTitle:(NSString *)title onSuccess:(void(^)(NSString *AlbumId))onSuccess onError: (void(^)(NSError * error)) onError;

//Get the album by name
+(PHAssetCollection *)getMyAlbumWithName:(NSString*)AlbumName;

//Add a image
+(void)addNewAssetWithImage:(UIImage *)image toAlbum:(PHAssetCollection *)album onSuccess:(void(^)(NSString *ImageId))onSuccess onError: (void(^)(NSError * error)) onError onFinish:(void(^)(NSString *finish))onFinish;

//Add a video
+(void)addNewAssetWithVideo:(NSURL *)fileURL toAlbum:(PHAssetCollection *)album onSuccess:(void(^)(NSString *VideoId))onSuccess onError: (void(^)(NSError * error)) onError onFinish:(void(^)(NSString *finish))onFinish;

+(NSArray *)getAssets:(PHFetchResult *)fetch;

//get the image using identifier
+ (void)getImageWithIdentifier:(NSString*)imageId onSuccess:(void(^)(UIImage *image))onSuccess onError: (void(^)(NSError * error)) onError;

+ (void)getImageWithCollection:(PHAssetCollection*)collection onSuccess:(void(^)(UIImage *image))onSuccess onError: (void(^)(NSError * error)) onError;

+ (void)getImageWithCollection:(PHAssetCollection*)collection onSuccess:(void(^)(UIImage *image))onSuccess onError: (void(^)(NSError * error)) onError atIndex:(NSInteger)index;

+ (PHAsset *)getImageWithCollectionAsset:(PHAssetCollection*)collection atIndex:(NSInteger)index;

//Delete image
+ (void)deleteImageWithCollection:(PHAssetCollection *)collection onSuccess:(void(^)(BOOL isSuccess))onSuccess toAlbum:(PHAssetCollection *)album onError:(void(^)(NSError * error))onError atIndex:(NSInteger)index;
@end

//
//  OSImageBannerView.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 13/11/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#import "ASVideoView.h"
#import "ASQueueVideoPlayer.h"

@interface OSImageBannerView : UIView

@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, assign) PHAssetMediaType mediaType;
@property (nonatomic, retain) AVURLAsset *urlAsset;
@property (nonatomic, retain) PHAsset *phAsset;

@property (nonatomic, retain) ASVideoView *videoView;
@property (nonatomic, assign) BOOL isPlaying;

+ (id)loadNib:(NSInteger)index;

- (void)setup:(AVAsset *)asset;

@end

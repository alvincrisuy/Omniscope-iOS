//
//  OSImageBannerView.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 13/11/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSImageBannerView.h"
#import "NSString+DeviceType.h"

@implementation OSImageBannerView

+ (id)loadNib:(NSInteger)index {
    UINib* nib = [UINib nibWithNibName:[NSStringFromClass([OSImageBannerView class]) concatenateClassToDeviceType] bundle:[NSBundle mainBundle]];
    
    NSArray* nibArray = [nib instantiateWithOwner:nil options:nil];
    
    OSImageBannerView* bannerView = (OSImageBannerView *)[nibArray objectAtIndex:index];
    
    return bannerView;
}

- (void)setup:(AVAsset *)asset {
    
    AVURLAsset *urlAsset = (AVURLAsset *)asset;
    
    self.videoView = [ASVideoView create];
    self.videoView.popoverParent.alpha = 0.0f;
    self.videoView.vwOverlayContainer.alpha = 0.0f;
    self.videoView.vwTopBar.alpha = 0.0f;
    self.videoView.vwBottomBar.alpha = 0.0f;
    self.videoView.vwAirPlay.alpha = 0.0f;
    
    [self.videoView setFrame:self.bounds];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self addSubview:self.videoView];
    });
    
    self.videoView.player.logs = ^(NSString *log) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"LOG %@", log);
        });
    };
    
    [self addObserver:self
           forKeyPath:@"videoView.player.currentItem.state"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:nil];
    
    ASQueuePlayerItem *item = nil;
    NSMutableArray *items = [NSMutableArray array];
    item = [[ASQueuePlayerItem alloc] initWithTitle:@""
                                                url:urlAsset.URL.absoluteURL
                                           userInfo:@{}];
    
    [items addObject:item];
    
    [self.videoView.player appendItemsToPlaylist:items];
    
    if (self.isPlaying) {
        [self.videoView.player playItemAtIndex:0];
    } else {
        
    }
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    OSImageBannerView *bannerView = (OSImageBannerView *)object;
    
    switch (bannerView.videoView.player.currentItem.state) {
        case ASQueuePlayerItemStatePrepared:
            NSLog(@"Prepare");
            break;
        case ASQueuePlayerItemStateUnprepared:
            NSLog(@"unprepared");
            if (self.isPlaying) {
                [self.videoView.player playItemAtIndex:0];
            }
            break;
        case ASQueuePlayerItemStateFailed:
            NSLog(@"failed");
            break;
        default:
            break;
    }
}

- (void)dealloc {
    
    if (self.mediaType == PHAssetMediaTypeVideo) {
        [self removeObserver:self
                  forKeyPath:@"videoView.player.currentItem.state"
                     context:nil];
    }
}

@end

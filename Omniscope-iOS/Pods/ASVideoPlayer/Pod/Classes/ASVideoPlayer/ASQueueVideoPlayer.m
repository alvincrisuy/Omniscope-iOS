//
//  ASQueueVideoPlayer.m
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import "ASQueueVideoPlayer.h"
#import "ASBaseVideoPlayer_Private.h"

#define SYSTEM_VERSION_LESS_THAN(v)                                     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

static void *ASVP_ContextCurrentItemDurationObservation                 = &ASVP_ContextCurrentItemDurationObservation;
static void *ASVP_ContextCurrentItemMetabservation                      = &ASVP_ContextCurrentItemMetabservation;

@interface ASQueueVideoPlayer ()
{
    UIBackgroundTaskIdentifier _bgExtendedTask;
}

@property (nonatomic, strong) NSMutableArray<ASQueuePlayerItem *>       *playlistMutable;
@property (nonatomic, strong) NSMutableDictionary                       *itemsDict;

@property (nonatomic, strong) ASQueuePlayerItem                         *currentItem;

@property (nonatomic, assign) BOOL                                      stopPreparingAssets;
@property (nonatomic, strong) ASQueuePlayerItem                         *currentPreparingItem;

// Closed Captions
//[
@property (nonatomic, strong) AVMediaSelectionGroup                     *ccMediaGroup;
@property (nonatomic, strong) NSMutableArray                            *ccMediaOptionsArray;
@property (nonatomic, strong) AVMediaSelectionOption                    *ccMediaOption;
//]

@end

@implementation ASQueueVideoPlayer

- (void)setup:(double)interval
{
    if (self.videoPlayer != nil)
    {
        if ([self.delegate respondsToSelector:@selector(outputViewForVideoPlayer:)])
        {
            AVPlayerLayer *playerLayer = [self.delegate outputViewForVideoPlayer:self];
            
            [playerLayer setPlayer:self.videoPlayer];
        }
        
        // Video player already created.
        return;
    }
    
    self.videoPlayer            = [AVQueuePlayer new];
    
    self.playlistMutable        = [NSMutableArray<ASQueuePlayerItem *> array];
    self.itemsDict              = [NSMutableDictionary new];
    
    [self addAirPlayFunctionality];

    [self initScrubberTimer:interval];
    
    // Observe the player item end to determine when it has finished playing.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    
    // Add handler for "going to background" notification.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    // Create notification observers for background tasks.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetBackgroundTask:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopBackgroundTask:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    /* Observe the AVPlayer "rate" property to update the scrubber control. */
    [self addObserver:self
           forKeyPath:@"videoPlayer.rate"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:&ASVP_ContextRateObservation];
    
    /* Observe the AVPlayer "currentItem" property to find out when any
     AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
     occur.*/
    [self addObserver:self
           forKeyPath:@"videoPlayer.currentItem"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:&ASVP_ContextCurrentItemObservation];
    
    [self addObserver:self
           forKeyPath:@"videoPlayer.currentItem.status"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:&ASVP_ContextStatusObservation];
    
    [self addObserver:self
           forKeyPath:@"videoPlayer.currentItem.duration"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:&ASVP_ContextCurrentItemDurationObservation];
    
    [self addObserver:self
           forKeyPath:@"videoPlayer.currentItem.playbackBufferEmpty"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:&ATVP_ContextBufferObservation];
    
    [self addObserver:self
           forKeyPath:@"videoPlayer.currentItem.playbackLikelyToKeepUp"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:&ATVP_ContextBufferLikelyToKeepUpObservation];
    
    [self addObserver:self
           forKeyPath:@"videoPlayer.currentItem.timedMetadata"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:&ASVP_ContextCurrentItemMetabservation];
    
    if ([self.delegate respondsToSelector:@selector(outputViewForVideoPlayer:)])
    {
        AVPlayerLayer *playerLayer = [self.delegate outputViewForVideoPlayer:self];
        
        [playerLayer setPlayer:self.videoPlayer];
    }
    
    [self setState:ASVideoPlayerState_Init];
}

- (void)setup
{
    [self setup:1.0];
}

#pragma mark - Reset video player
- (void)reset
{
    // Send event "End".
    [self sendEventEnd];
    
    [self.videoPlayer pause];
    
    [self removeScrubberTimer];

    [self removeObserver:self
              forKeyPath:@"videoPlayer.rate"
                 context:&ASVP_ContextRateObservation];
    
    [self removeObserver:self
              forKeyPath:@"videoPlayer.currentItem"
                 context:&ASVP_ContextCurrentItemObservation];
    
    [self removeObserver:self
              forKeyPath:@"videoPlayer.currentItem.status"
                 context:&ASVP_ContextStatusObservation];
    
    [self removeObserver:self
              forKeyPath:@"videoPlayer.currentItem.duration"
                 context:&ASVP_ContextCurrentItemDurationObservation];
    
    [self removeObserver:self
              forKeyPath:@"videoPlayer.currentItem.playbackBufferEmpty"
                 context:ATVP_ContextBufferObservation];
    
    [self removeObserver:self
              forKeyPath:@"videoPlayer.currentItem.playbackLikelyToKeepUp"
                 context:&ATVP_ContextBufferLikelyToKeepUpObservation];
    
    [self removeObserver:self
              forKeyPath:@"videoPlayer.currentItem.timedMetadata"
                 context:&ASVP_ContextCurrentItemMetabservation];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    
    self.videoPlayer = nil;
    
    [self setState:ASVideoPlayerState_Suspended];
}

- (void)appendItemsToPlaylist:(NSArray<ASQueuePlayerItem *> *)items
{
    for (ASQueuePlayerItem *item in items)
    {
        // Add only unique items.
        if (self.itemsDict[item.asset.URL.absoluteString] == nil)
        {
            [item updatePlaylistIndex:self.playlistMutable.count];
            [self.playlistMutable addObject:item];
            self.itemsDict[item.asset.URL.absoluteString] = item;
        }
    }
}

- (void)prepareItems:(NSUInteger)startIndex
          completion:(void (^)())completion
{
    if (self.stopPreparingAssets)
    {
        ASVP_LOG(@"Preparing Interrupted.");
        ASVP_CLIENT_LOG(self, @"Preparing Interrupted.");
        
        [self.currentPreparingItem cancelPreparing];
        
        if (completion)
        {
            completion();
        }
        
        return;
    }
    
    if (startIndex >= self.playlist.count)
    {
        ASVP_LOG(@"Preparing Completed.");
        ASVP_CLIENT_LOG(self, @"Preparing Completed.");
        if (completion)
        {
            completion();
        }
        
        return;
    }
    
    self.currentPreparingItem = self.playlist[startIndex];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    __weak __typeof(self) weakSelf = self;
    [self.currentPreparingItem prepareItem:^(NSError *error)
    {
        
        if (weakSelf.stopPreparingAssets)
        {
            ASVP_LOG(@"Preparing Interrupted.");
            ASVP_CLIENT_LOG(self, @"Preparing Interrupted.");

            [weakSelf.currentPreparingItem cancelPreparing];

            if (completion)
            {
                completion();
            }

            return;
        }

        if (error)
        {
            [weakSelf assetFailedToPrepareForPlayback:error];
        }
        
        [weakSelf prepareItems:startIndex + 1 completion:completion];
        
        dispatch_async(dispatch_get_main_queue(), ^
        {
            /* IMPORTANT: Must dispatch to main queue in order to operate on the AVQueuePlayer and AVPlayerItem. */
            [(AVQueuePlayer *)weakSelf.videoPlayer insertItem:[AVPlayerItem playerItemWithAsset:weakSelf.currentPreparingItem.asset]
                                                    afterItem:nil];

            // Start playing.
            if (weakSelf.isPlaying == NO)
            {
                [weakSelf play];
            }
        });
    }];
}

#pragma mark - Clear Playlist

- (void)clearPlaylist
{
    [((AVQueuePlayer *)self.videoPlayer) removeAllItems];
    [self.itemsDict removeAllObjects];
    [self.playlistMutable removeAllObjects];
    self.currentItem = nil;
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" property value observer. */
    if (context == ASVP_ContextStatusObservation)
    {
        //TODO:
        //        [self.vwVideo syncPlayPauseButtons];
        
        NSNumber *statusAsNumber = change[NSKeyValueChangeNewKey];
        AVPlayerItemStatus status = [statusAsNumber isKindOfClass:[NSNumber class]] ? statusAsNumber.integerValue : AVPlayerItemStatusUnknown;
        
        if ([statusAsNumber isKindOfClass:[NSNumber class]] == NO)
        {
            self.currentItem = nil;
            [self setState:ASVideoPlayerState_Suspended];
            
            return;
        }
        
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerItemStatusUnknown:
            {
                [self setState:ASVideoPlayerState_Unknown];
                
                ASVP_LOG(@"Current Item Status: Unknown");
                ASVP_CLIENT_LOG(self, @"Current Item Status: Unknown");
                
                break;
            }
                
            case AVPlayerItemStatusReadyToPlay:
            {
                if (self.initialSeek != 0.0)
                {
                    CMTime playerDuration = [self playerItemDuration];
                    if (CMTIME_IS_INVALID(playerDuration))
                    {
                        break;
                    }
                    
                    double duration = CMTimeGetSeconds(playerDuration);
                    if (duration - self.initialSeek < 10.0)
                    {
                        self.initialSeek -= 10.0;
                    }
                    
                    [self.videoPlayer seekToTime:CMTimeMakeWithSeconds(self.initialSeek, NSEC_PER_SEC)
                               completionHandler:^(BOOL finished)
                     {
                         
                     }];
                    self.initialSeek = 0.0f;
                }
                
                [self __enableSubtitles:self.enableSubtitles];
                
                if (self.state == ASVideoPlayerState_Seeking)
                {
                    if (!self.isScrubbing)
                    {
                        ASVP_LOG(@"Current Item Status: Ready To Play");
                        ASVP_CLIENT_LOG(self, @"Current Item Status: Ready To Play");
                        [self setState:ASVideoPlayerState_Playing];
                    }
                }
                else if (self.state == ASVideoPlayerState_Paused)
                {
                    
                }
                else
                {
                    ASVP_LOG(@"Current Item Status: Ready To Play");
                    ASVP_CLIENT_LOG(self, @"Current Item Status: Ready To Play");
                    [self setState:ASVideoPlayerState_Playing];
                }
                
                break;
            }
                
            case AVPlayerItemStatusFailed:
            {
                [self.currentItem updateStatus:ASQueuePlayerItemStateFailed
                                         error:self.videoPlayer.currentItem.error];

                [self playerFailedWithError:self.videoPlayer.currentItem.error];
                
                ASVP_LOG(@"Current Item Status: Failed(%@)", self.videoPlayer.currentItem.error);
                ASVP_CLIENT_LOG(self, @"Current Item Status: Failed(%@)", self.videoPlayer.currentItem.error);
                
                break;
            }
        }
    }
    /* AVPlayer "rate" property value observer. */
    else if (context == ASVP_ContextRateObservation)
    {
        ASVP_LOG(@"rate = %f", self.videoPlayer.rate);
        ASVP_CLIENT_LOG(self, @"rate = %f", self.videoPlayer.rate);
        
        if (self.state == ASVideoPlayerState_Seeking)
        {
            return;
        }
        
        if (self.isPlaying)
        {
            ASVP_LOG(@"self.videoPlayer.currentItem.status = %ld", (long)self.videoPlayer.currentItem.status);
            if (SYSTEM_VERSION_LESS_THAN(@"9.0") == NO)
            {
                if (self.videoPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay)
                {
                    [self setState:ASVideoPlayerState_Playing];
                }
            }
            else
            {
                [self setState:ASVideoPlayerState_Playing];
            }
        }
        else
        {
            [self setState:ASVideoPlayerState_Paused];
        }
    }
    /* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
    else if (context == ASVP_ContextCurrentItemObservation)
    {
        if ([self.delegate respondsToSelector:@selector(videoPlayer:currentItem:)])
        {
            AVURLAsset *asset = (AVURLAsset *)self.videoPlayer.currentItem.asset;
            
            ASQueuePlayerItem *currentItem = self.itemsDict[asset.URL.absoluteString];
            [self.delegate videoPlayer:self currentItem:currentItem];
            
            [self setCurrentItem:currentItem];
        }
    }
    else if (context == ASVP_ContextCurrentItemDurationObservation)
    {
        
    }
    else if (context == ATVP_ContextBufferObservation)
    {
        if (self.videoPlayer.currentItem.playbackBufferEmpty)
        {
            /* Buffer is empty, which will cause player to pause, so show spinner. */
            if (self.state != ASVideoPlayerState_Paused &&
                self.state != ASVideoPlayerState_Seeking)
            {
                [self setState:ASVideoPlayerState_LoadingContent];
            }
        }
    }
    else if (context == ATVP_ContextBufferLikelyToKeepUpObservation)
    {
        if (self.state != ASVideoPlayerState_Paused &&
            self.state != ASVideoPlayerState_Seeking)
        {
            if (self.videoPlayer.currentItem.playbackLikelyToKeepUp)
            {
                [self setState:ASVideoPlayerState_Playing];
            }
        }
    }
    else if (context == ASVP_ContextCurrentItemMetabservation)
    {
        if ([self.delegate respondsToSelector:@selector(videoPlayer:meta:)])
        {
            NSMutableArray *metaItems = [NSMutableArray array];
            for (AVMetadataItem *metaItem in self.videoPlayer.currentItem.timedMetadata)
            {
                [metaItems addObject:@{
                                      @"identifier"     : metaItem.identifier?  : @"",
                                      @"value"          : metaItem.value?       : @"",
                                      @"description"    : metaItem.extraAttributes[@"info"]?  : @""
                                      }];
            }
            
            [self.delegate videoPlayer:self meta:metaItems];
            [self printMeta];
        }
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

#pragma mark - Handle Video End

// Called when the player item has played to its end time.
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    // Send video logging ping when video has reached the end.
    [self sendEventEnd];
}

#pragma mark - Error Handling

- (void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self syncScrubber];
    
    self.userInfo = @{@"error" : error, @"current_item" : self.currentPreparingItem? : [NSNull null]};
    
    [self setState:ASVideoPlayerState_AssetPreparingFailed];
}

- (void)playerFailedWithError:(NSError *)error
{
    [self syncScrubber];
    
    self.userInfo = @{@"error" : error, @"current_item" : self.currentPreparingItem? : [NSNull null]};
    
    [self setState:ASVideoPlayerState_Failed];
}

#pragma mark - AirPlay

- (void)addAirPlayFunctionality
{
    // Set AirPlay properties for AVPlayer.
    self.videoPlayer.allowsExternalPlayback                             = YES;
    self.videoPlayer.usesExternalPlaybackWhileExternalScreenIsActive    = YES;
    self.videoPlayer.externalPlaybackVideoGravity                       = AVLayerVideoGravityResizeAspect;
}

#pragma mark - Duration

- (CMTime)playerItemDuration
{
    AVPlayerItem *playerItem = [self.videoPlayer currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        return([playerItem duration]);
    }
    else if (playerItem.status == AVPlayerItemStatusUnknown && self.videoPlayer.externalPlaybackActive)
    {
        return([playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}

#pragma mark -
#pragma mark Movie scrubber control

/* ---------------------------------------------------------
 **  Methods to handle manipulation of the movie scrubber control
 ** ------------------------------------------------------- */

/* Cancels the previously registered time observer. */
- (void)removeScrubberTimer
{
    if (self.timeObserver)
    {
        [self.videoPlayer removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

/* Requests invocation of a given block during media playback to update the movie scrubber control. */
-(void)initScrubberTimer:(double)interval
{
    /* Update the scrubber during normal playback. */
    __weak ASBaseVideoPlayer *weakSelf = self;
    self.timeObserver = [self.videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                       queue:NULL /* If you pass NULL, the main queue is used. */
                                                                  usingBlock:^(CMTime time)
                         {
                             [weakSelf syncScrubber];
                         }];
}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
    if (self.isScrubbing)
    {
        return;
    }
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        if ([self.delegate respondsToSelector:@selector(videoPlayer:currentTime:timeLeft:duration:)])
        {
            [self.delegate videoPlayer:self currentTime:0 timeLeft:0 duration:0];
        }
        
        //TODO:
        //        self.vwVideo.scrubberMinValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        double time = CMTimeGetSeconds([self.videoPlayer currentTime]);
        
        if ([self.delegate respondsToSelector:@selector(videoPlayer:currentTime:timeLeft:duration:)])
        {
            [self.delegate videoPlayer:self currentTime:time timeLeft:duration - time duration:duration];
        }
        
        // Sync playedTime by starting to track played time when video starts playing.
        if (time >= 1.0 && [self isPlaying])
        {
            self.playedTimeSeconds++;
        }
        
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           // Send video logging ping every 30 seconds of actual played time.
                           if ((self.playedTimeSeconds >= 1) && ((self.playedTimeSeconds % 30) == 0))
                           {
                               [self sendEventPlaying];
                           }
                       });
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(videoPlayer:currentTime:timeLeft:duration:)])
        {
            [self.delegate videoPlayer:self currentTime:0 timeLeft:0 duration:0];
        }
    }
}

#pragma mark - Public Methods

- (BOOL)isScrubbing
{
    return self.restoreAfterScrubbingRate != 0.f;
}

- (BOOL)isPlaying
{
    return [self.videoPlayer rate] != 0.f;
}

- (void)beginScrubbing
{
    // Enter in Seeking mode.
    [self setState:ASVideoPlayerState_Seeking];
    
    self.restoreAfterScrubbingRate = [self.videoPlayer rate];
    [self.videoPlayer setRate:0.f];
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (void)endScrubbing
{
    if (self.restoreAfterScrubbingRate)
    {
        [self.videoPlayer setRate:self.restoreAfterScrubbingRate];
        self.restoreAfterScrubbingRate = 0.0f;
        
        [self setState:ASVideoPlayerState_Playing];
    }
}

/* Set the player current time to match the scrubber position. */
- (void)seekToTime:(double)time
{
    self.isSeeking = YES;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        [self.videoPlayer seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)
                   completionHandler:^(BOOL finished)
        {
            
        }];
    }
}

- (BOOL)canSeek
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return NO;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration) == NO)
    {
        return NO;
    }
    
    return YES;
}

- (void)seekToRelativeTime:(double)relativeTime
{
    self.isSeeking =        YES;

    double duration         = CMTimeGetSeconds([self.videoPlayer currentItem].duration);
    relativeTime            = relativeTime * duration;
    [self.videoPlayer seekToTime:CMTimeMakeWithSeconds(relativeTime, NSEC_PER_SEC)];
}

- (void)seekToRelativeTime:(double)relativeTime
                completion:(void (^)(BOOL finished))completion
{
    self.isSeeking =        YES;
    
    double duration         = CMTimeGetSeconds([self.videoPlayer currentItem].duration);
    relativeTime            = relativeTime * duration;
    [self.videoPlayer seekToTime:CMTimeMakeWithSeconds(relativeTime, NSEC_PER_SEC)
                 toleranceBefore:kCMTimeZero
                  toleranceAfter:kCMTimeZero
               completionHandler:completion];
}

- (double)currentRelativeTime
{
    double duration         = CMTimeGetSeconds([self.videoPlayer currentItem].duration);
    double currentTime      = CMTimeGetSeconds([self.videoPlayer currentItem].currentTime);
    
    if (duration > 0)
    {
        return currentTime / duration;
    }
    
    return 0;
}

- (double)currentTime
{
    return CMTimeGetSeconds([self.videoPlayer currentItem].currentTime);
}

- (double)videoDurationLoaded
{
    return CMTimeGetSeconds([self.videoPlayer currentItem].duration);
}

- (double)videoDuration
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return 0.0;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        return duration;
    }
    
    return DBL_MAX;
}

- (void)play
{
    if (self.isPlaying)
    {
        return;
    }
    
    [self.videoPlayer play];
}

- (void)pause
{
    if (self.isPlaying == NO)
    {
        return;
    }
    
    [self.videoPlayer pause];
    
    // Send event "Pause".
    [self sendEventPause];
}

- (void)initialSeek:(double)seekTo
{
    self.initialSeek = seekTo;
}

- (NSArray<ASQueuePlayerItem *> *)playlist
{
    return self.playlistMutable;
}

#pragma mark - Controls

- (BOOL)prevItem
{
    if (self.playlist.count && (self.currentItem.playlistIndex > 0))
    {
        [self playItemAtIndex:self.currentItem.playlistIndex - 1];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)nextItem
{
    if (self.playlist.count && (self.currentItem.playlistIndex < self.playlist.count - 1))
    {
        [self playItemAtIndex:self.currentItem.playlistIndex + 1];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)playItemAtIndex:(NSUInteger)itemIndex
{
    if (itemIndex >= self.playlist.count)
    {
        return NO;
    }
    
    if (self.currentItem && (itemIndex == self.currentItem.playlistIndex))
    {
        return NO;
    }
    
    self.stopPreparingAssets = YES;
    [self.currentPreparingItem cancelPreparing];
    
    [(AVQueuePlayer *)self.videoPlayer removeAllItems];
    
    self.stopPreparingAssets = NO;
    [self prepareItems:itemIndex completion:nil];
    
    [self setState:ASVideoPlayerState_AssetPreparing];
    
    return YES;
}

- (NSInteger)indexForItemURL:(NSString *)itemURL
{
    ASQueuePlayerItem *item = self.itemsDict[itemURL];
    if (item)
    {
        return item.playlistIndex;
    }
    
    return -1;
}

- (BOOL)deleteItemAtIndex:(NSUInteger)index
{
    if (index >= self.playlistMutable.count)
    {
        return NO;
    }
    
    [self stop];
    
    ASQueuePlayerItem *item = self.playlistMutable[index];
    
    [self.itemsDict removeObjectForKey:item.asset.URL.absoluteString];
    [self.playlistMutable removeObjectAtIndex:index];
    
    return YES;
}

- (void)stop
{
    [self sendEventStopped];
    
    self.stopPreparingAssets = YES;
    [self.currentPreparingItem cancelPreparing];
    
    [(AVQueuePlayer *)self.videoPlayer removeAllItems];
}

#pragma mark - Handle notifications

- (void)appWillResignActive:(NSNotification *)notification
{
    [self sendEventResignActive];
}

- (void)resetBackgroundTask:(NSNotification*)notification
{
    // When app is sent to the background or the device is in sleep/standby mode,
    // this method should be called to extend app's active background session.
    //DLog(@"");
    
    UIApplication *thisApp = [UIApplication sharedApplication];
    
    // If an existing background task is running,
    // end it first before starting a new one.
    if (_bgExtendedTask != UIBackgroundTaskInvalid) {
        [thisApp endBackgroundTask:_bgExtendedTask];
        _bgExtendedTask = UIBackgroundTaskInvalid;
    }
    
    // Start new background task to extend background session.
    _bgExtendedTask = [thisApp beginBackgroundTaskWithExpirationHandler:^
                       {
                           if (_bgExtendedTask != UIBackgroundTaskInvalid)
                           {
                               [[UIApplication sharedApplication] endBackgroundTask:_bgExtendedTask];
                               _bgExtendedTask = UIBackgroundTaskInvalid;
                           }
                       }];
}

- (void)stopBackgroundTask:(NSNotification*)notification
{
    // When app returns to the foreground as the active app,
    // this method should be called to end any extended background session.
    //DLog(@"");
    
    UIApplication *thisApp = [UIApplication sharedApplication];
    if (_bgExtendedTask != UIBackgroundTaskInvalid)
    {
        [thisApp endBackgroundTask:_bgExtendedTask];
        _bgExtendedTask = UIBackgroundTaskInvalid;
    }
}

#pragma mark - Closed Captions

- (void)enableSubtitles:(BOOL)enable
{
    self.enableSubtitles = enable;
}

- (void)__enableSubtitles:(BOOL)shouldEnable
{
    if (shouldEnable) {
        // YES, attempt to enable CC button, but only if CC is available for selected video.
        
        self.ccMediaGroup = [self.videoPlayer.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        if (self.ccMediaGroup)
        {
            NSArray *ccMediaGroupOptions = self.ccMediaGroup.options;
            
            if (ccMediaGroupOptions.count > 0)
            {
                //DLog(@"ccMediaGroupOptions.count > 0 = %@", ccMediaGroupOptions);
                
                if (self.ccMediaOptionsArray == nil)
                {
                    self.ccMediaOptionsArray = [NSMutableArray array];
                }
                
                [self.ccMediaOptionsArray removeAllObjects];
                
                // Cycle through media options to find only valid CC options.
                for (AVMediaSelectionOption *mediaOption in ccMediaGroupOptions)
                {
                    if (mediaOption.extendedLanguageTag)
                    {
                        // Valid CC option, so add it to the valid list array.
                        
                        //DLog(@"VALID mediaOption: extendedLanguageTag = %@, displayName = %@, mediaType = %@", mediaOption.extendedLanguageTag, mediaOption.displayName, mediaOption.mediaType);
                        
                        [self.ccMediaOptionsArray addObject:mediaOption];
                    }
                }
                
                if (self.ccMediaOptionsArray.count > 0)
                {
                    // Valid CC media options list has at least one option, so enable CC button.
                    
                    //DLog(@"ccMediaOptionsArray.count > 0, so ENABLE CC button.");
                    
                    if (UIAccessibilityIsClosedCaptioningEnabled())
                    {
                        // User has iOS System Settings CC turned ON, which overrides app-level CC settings.
                        
                        //                        DLog(@"UIAccessibilityIsClosedCaptioningEnabled = YES");
                        
                        //                        showingCC = YES;
                        
                        // Show app-level CC button as Selected AND Disabled to reflect System CC Settings.
                        //                        [self.mCCButton setImage:[UIImage imageNamed:@"QKVideoIcon-CC-Sel.png"] forState:UIControlStateNormal];
                        //                        self.mCCButton.enabled = NO;
                        
                    }
                    else
                    {
                        // User has iOS System Settings CC turned OFF, so enable app-level CC.
                        //                        self.mCCButton.enabled = YES;
                    }
                    
                    // Set Closed Captioning property.
                    self.videoPlayer.closedCaptionDisplayEnabled = YES;
                    
                    [self startClosedCaptions:0];
                    
                }
                else
                {
                    // There are NO valid CC media options, so disable CC button.
                    //                    self.mCCButton.enabled = NO;
                    
                    // Set Closed Captioning property.
                    self.videoPlayer.closedCaptionDisplayEnabled = NO;
                }
                
            }
            else
            {
                // NO legible media group OPTIONS, so disable CC button.
                //                self.mCCButton.enabled = NO;
                
                // Set Closed Captioning property.
                self.videoPlayer.closedCaptionDisplayEnabled = NO;
            }
            
        }
        else
        {
            // NO legible media GROUP, so disable CC button.
            //            self.mCCButton.enabled = NO;
            
            // Set Closed Captioning property.
            self.videoPlayer.closedCaptionDisplayEnabled = NO;
        }
        
    }
    else
    {
        // NO, so disable CC button.
        
        //        self.mCCButton.enabled = NO;
        
        // Set Closed Captioning property.
        self.videoPlayer.closedCaptionDisplayEnabled = NO;
    }
}

- (void)startClosedCaptions:(NSInteger)mediaOptionIndex
{
    // Turns ON Closed Captioning & Subtitles for select CC media option.
    
    if (self.ccMediaOptionsArray.count > mediaOptionIndex)
    {
        self.ccMediaOption = self.ccMediaOptionsArray[mediaOptionIndex];
        
        //DLog(@"START ccMediaOption.extendedLanguageTag = %@, displayName = %@, mediaType = %@", ccMediaOption.extendedLanguageTag, ccMediaOption.displayName, ccMediaOption.mediaType);
        
        [self.videoPlayer.currentItem selectMediaOption:self.ccMediaOption inMediaSelectionGroup:self.ccMediaGroup];
    }
}

#pragma mark - Helpers

- (void)printMeta
{
    ASVP_LOG(@"Meta data items: %d", (int)self.videoPlayer.currentItem.timedMetadata.count);
    ASVP_CLIENT_LOG(self, @"Meta data items: %d", (int)self.videoPlayer.currentItem.timedMetadata.count);
    
    NSUInteger index = 0;
    for (AVMetadataItem *metaItem in self.videoPlayer.currentItem.timedMetadata)
    {
        ASVP_LOG(@"Meta item(%d):\nIdentifier: %@\nValue:%@\nInfo:%@\n",
                 (int)index,
                 metaItem.identifier, metaItem.value, metaItem.extraAttributes[@"info"]);
        
        ASVP_CLIENT_LOG(self, @"Meta item(%d):\nIdentifier: %@\nValue:%@\nInfo:%@\n",
                        (int)index,
                        metaItem.identifier,
                        metaItem.value,
                        metaItem.extraAttributes[@"info"]);
    }
}

+ (NSString *)stateStringFromState:(ASVideoPlayerState)state
{
    NSString *stateString = nil;
    
    switch (state)
    {
        case ASVideoPlayerState_Unknown:
        {
            stateString = @"Unknown";
            
            break;
        }
            
        case ASVideoPlayerState_Init:
        {
            stateString = @"Init";
            
            break;
        }
            
        case ASVideoPlayerState_AssetPreparing:
        {
            stateString = @"Preparing";
            
            break;
        }
            
        case ASVideoPlayerState_AssetPreparingFailed:
        {
            stateString = @"Failed";
            
            break;
        }
            
        case ASVideoPlayerState_ReadyToPlay:
        {
            stateString = @"ReadyToPlay";
            
            break;
        }
            
        case ASVideoPlayerState_LoadingContent:
        {
            stateString = @"LoadingContent";
            
            break;
        }
            
        case ASVideoPlayerState_Playing:
        {
            stateString = @"Playing";
            
            break;
        }
            
        case ASVideoPlayerState_Paused:
        {
            stateString = @"Paused";
            
            break;
        }
            
        case ASVideoPlayerState_Suspended:
        {
            stateString = @"Suspended";
            
            break;
        }
            
        case ASVideoPlayerState_Failed:
        {
            stateString = @"Failed";
            
            break;
        }
            
        default:
            break;
    }
    
    return stateString;
}

@end

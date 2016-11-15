//
//  ASBaseVideoPlayer.h
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

// Forward
//[
@class ASBaseVideoPlayer;
@class ASVideoEvent;
//]

// Externs
//[
FOUNDATION_EXTERN void *ASVP_ContextRateObservation;
FOUNDATION_EXTERN void *ASVP_ContextStatusObservation;
FOUNDATION_EXTERN void *ASVP_ContextCurrentItemObservation;
FOUNDATION_EXTERN void *ATVP_ContextBufferObservation;
FOUNDATION_EXTERN void *ATVP_ContextBufferLikelyToKeepUpObservation;

FOUNDATION_EXTERN NSString const *kASVP_TracksKey;
FOUNDATION_EXTERN NSString const *kASVP_PlayableKey;
//]

#define ASVP_DEBUG

#ifdef ASVP_DEBUG
    #define ASVP_LOG( s, ... ) NSLog( @"<%p %@:%@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], [[NSString stringWithUTF8String:__func__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] );
    #define ASVP_CLIENT_LOG( player, s, ...) if (player.logs) player.logs([NSString stringWithFormat:@"[%@]: %@", [NSDate date], [NSString stringWithFormat:(s), ##__VA_ARGS__]])
#else
    #define ASVP_LOG( s, ... )
    #define ASVP_CLIENT_LOG( player, s, ...)
#endif

typedef NS_ENUM(NSInteger, ASVideoPlayerState)
{
    /**
     *  Unknown
     */
    ASVideoPlayerState_Unknown          = -1,
    
    /**
     *  Init
     */
    ASVideoPlayerState_Init,
    
    /**
     *  Preparing the current asset
     */
    ASVideoPlayerState_AssetPreparing,
    
    /**
     *  Current asset preparing failed.
     */
    ASVideoPlayerState_AssetPreparingFailed,
    
    /**
     *  Ready to Play
     */
    ASVideoPlayerState_ReadyToPlay,
    
    /**
     *  Loading Content
     */
    ASVideoPlayerState_LoadingContent,
    
    /**
     *  Playing
     */
    ASVideoPlayerState_Playing,
    
    /**
     *  Paused
     */
    ASVideoPlayerState_Paused,
    
    /**
     *  Seeking
     */
    ASVideoPlayerState_Seeking,
    
    /**
     *  Suspended
     */
    ASVideoPlayerState_Suspended,
    
    /**
     *  Failed
     */
    ASVideoPlayerState_Failed,
};

@protocol ASVideoPlayerDelegate <NSObject>

- (AVPlayerLayer *)outputViewForVideoPlayer:(ASBaseVideoPlayer *)videoPlayer;

@optional

- (void)videoPlayer:(ASBaseVideoPlayer *)videoPlayer currentTime:(double)currentTime timeLeft:(double)timeLeft duration:(double)duration;

- (void)videoPlayer:(ASBaseVideoPlayer *)videoPlayer currentItem:(id)currentItem;

- (void)videoPlayer:(ASBaseVideoPlayer *)videoPlayer meta:(NSArray *)meta;

@end

@protocol ASVideoPlayerEventsDelegate <NSObject>

- (void)videoPlayer:(ASBaseVideoPlayer *)videoPlayer event:(ASVideoEvent *)event;

@end

@interface ASBaseVideoPlayer : NSObject

@property (nonatomic, weak) id<ASVideoPlayerDelegate>           delegate;
@property (nonatomic, weak) id<ASVideoPlayerEventsDelegate>     eventsDelegate;

@property (nonatomic, strong, readonly) NSURL                   *sourceURL;
@property (nonatomic, strong, readonly) AVPlayer                *videoPlayer;
@property (nonatomic, strong, readonly) NSDictionary            *userInfo;

@property (nonatomic, assign, readonly) BOOL                    isPlaying;
@property (nonatomic, assign, readonly) ASVideoPlayerState      state;

@property (nonatomic, copy) void (^logs)(NSString *log);

/**
 *  Override this method if your custom class is going to inherit ASBaseVideoPlayer so that you can specify 
 *  custom settings upon creation.
 *
 *  @return AVPlayer
 */
- (AVPlayer *)createVideoPlayer;

/**
 *  Loads a video from the passed videoURL.
 *
 *  @param videoURL
 */
- (void)loadVideoURL:(NSURL *)videoURL;

/**
 *  Play the loaded video.
 */
- (void)play;

/**
 *  Pause the played video.
 */
- (void)pause;

/**
 *  Specifies the position on which the video will initially start playing after it was once loaded.
 *
 *  @param seekTo The position.
 */
- (void)initialSeek:(double)seekTo;

/**
 *  Used to check if the video player is still scrubbing(seeking).
 *
 *  @return isScrubbing flag.
 */
- (BOOL)isScrubbing;

/**
 *  Call this method to tell the player the scrubbing begins.
 */
- (void)beginScrubbing;

/**
 *  Call this method to tell the player the scrubbing ended.
 */
- (void)endScrubbing;

/**
 *  Seek to desired position.
 *
 *  @param time
 */
- (void)seekToTime:(double)time;

/**
 *  Enables/Disables CC.
 *
 *  @param enable
 *
 */
- (void)enableSubtitles:(BOOL)enable;

/**
 *  Retrieves the duration of the loaded video. Must be called after ASVideoPlayerState_ReadyToPlay is received.
 *
 *  @return Video duration. Check if the video duration is DBL_MAX(usually that means it is a live stream).
 */
- (double)videoDuration;

/**
 *  Resets video player data.
 */
- (void)reset;

/**
 *  Helper method used to get readable string from ASVideoPlayerState.
 *
 *  @param state
 *
 *  @return Readable state string.
 */
+ (NSString *)stateStringFromState:(ASVideoPlayerState)state;

@end

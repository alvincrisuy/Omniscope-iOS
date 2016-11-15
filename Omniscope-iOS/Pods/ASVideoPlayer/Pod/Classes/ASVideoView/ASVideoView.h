//
//  ASVideoView.h
//
//  Created by Alexey Stoyanov on 12/3/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ASVideoView.h"
#import "ASVideoEvent.h"
#import "ASQueueVideoPlayer.h"

// Forward
//[
@class ASVideoPlayer;
@class ASQueueVideoPlayer;
@class ASQueuePlayerItem;
//]

@interface ASVideoView : UIView

//@property (nonatomic, strong, readonly) ASVideoPlayer               *player;
@property (nonatomic, strong, readonly) ASQueueVideoPlayer          *player;
@property (nonatomic, assign) CGFloat                               scrubberMinValue;
@property (nonatomic, assign) CGFloat                               scrubberMaxValue;
@property (nonatomic, assign) CGFloat                               scrubberValue;
@property (nonatomic, strong) UIView                                *popoverParent;

@property (nonatomic, copy) void (^closeHandler)();

@property (nonatomic, strong) IBOutlet UIView                   *vwOverlayContainer;
@property (nonatomic, strong) IBOutlet UIView                   *vwTopBar;
@property (nonatomic, strong) IBOutlet UIView                   *vwBottomBar;
@property (nonatomic, strong) IBOutlet UIView                   *vwAirPlay;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView  *vwActivityIndicator;

@property (nonatomic, strong) IBOutlet UILabel                  *lblTitle;
@property (nonatomic, strong) IBOutlet UILabel                  *lblTimePlayed;
@property (nonatomic, strong) IBOutlet UILabel                  *lblTimeLeft;

@property (nonatomic, strong) IBOutlet UISlider                 *scrubber;

@property (nonatomic, strong) IBOutlet UIButton                 *btnFullscreen; // Won't be needed.
@property (nonatomic, strong) IBOutlet UIButton                 *btnVolume;
@property (nonatomic, strong) IBOutlet UIButton                 *btnPlay;
@property (nonatomic, strong) IBOutlet UIButton                 *btnContainer;
@property (nonatomic, strong) IBOutlet UIButton                 *btnDone;
@property (nonatomic, strong) IBOutlet UIButton                 *btnDoneArea;

+ (instancetype)create;

#pragma mark - Play, Pause buttons
- (void)showPauseButton;
- (void)showPlayButton;
- (void)syncPlayPauseButtons;
- (void)enablePlayerButtons;
- (void)disablePlayerButtons;

#pragma mark - Scrubber
- (void)enableScrubber;
- (void)disableScrubber;
- (void)scrubberColor:(UIColor *)color;

#pragma mark - Title
- (void)updateTitle:(NSString *)title;

#pragma mark - Update Time Labels
- (void)updatePlayedTimeLabel:(double)seconds;
- (void)updateLeftTimeLabel:(double)seconds;

#pragma mark - Reset
- (void)reset;

#pragma mark - Activity
- (void)busy:(BOOL)show;

#pragma mark - Enable Done Button
- (void)enableDoneButton;

@end

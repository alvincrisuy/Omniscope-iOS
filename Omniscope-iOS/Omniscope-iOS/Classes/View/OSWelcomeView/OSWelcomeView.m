//
//  OSWelcomeView.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 01/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSWelcomeView.h"
#import "UIDevice+DeviceType.h"
#import "NSString+DeviceType.h"
#import "OSRootViewController.h"

#import "CustomAlbum.h"

NSString *const CSAlbum4 = @"Omniscope";

@interface OSWelcomeView() {
    BOOL isShowing;
}

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, assign) NSInteger progress;

@end

@implementation OSWelcomeView

+ (instancetype)viewFromNib {
    NSArray* array;
    array = [[NSBundle mainBundle] loadNibNamed:[NSStringFromClass([OSWelcomeView class]) concatenateClassToDeviceType]
                                          owner:nil
                                        options:nil];
    
    if (!array || ![array count]) {
        return nil;
    }
    
    OSWelcomeView *view = [array objectAtIndex:0];
    view.frame = [UIScreen mainScreen].bounds;
    
    return view;
}

- (void)show {
    self.center = [[[UIApplication sharedApplication] keyWindow] center];
    [[[UIApplication sharedApplication] keyWindow] addSubview:self];
    [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:self];
    
    [CustomAlbum makeAlbumWithTitle:CSAlbum4 onSuccess:^(NSString *AlbumId) {
        //        self.albumId = AlbumId;
    } onError:^(NSError *error) {
        NSLog(@"problem in creating album");
    }];
    
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            
        }];
    }
}

- (void)setup {
    self.pressToStartButton.alpha = 0.0f;
    self.pressToStartLabel.alpha = 0.0f;

    [[OSRootViewController sharedController] hideNavigationView];
    [[OSRootViewController sharedController] hideTabView];
    [[OSRootViewController sharedController] hideSideTableView];

    [NSTimer scheduledTimerWithTimeInterval:3.0
                                     target:self
                                   selector:@selector(showPressToStart)
                                   userInfo:nil
                                    repeats:NO];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(animateLogo)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)hideLoading {
    
    [self.loadingIndicatorView stopAnimating];
    
}

- (void)showPressToStart {
    
    [self.pressToStartButton setAlpha:1.0f];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(hideLoading)
                                   userInfo:nil
                                    repeats:NO];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(continuousFadeInOut) userInfo:nil repeats:YES];
    
}

- (void)continuousFadeInOut {
    
    [UIView animateWithDuration:0.5 animations:^{
        
        [self.pressToStartLabel setAlpha:1.0f];
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.5 animations:^{
            
            [self.pressToStartLabel setAlpha:0.0f];
            
        } completion:^(BOOL finished) {
            
        }];
        
    }];
}

- (void)animateLogo {
    
    CATransition* animation;
    animation      = [CATransition animation];
    animation.type = kCATransitionFade;
    {
        [self.omniscopeView setAlpha:1.0f];
    }
    
    [self.omniscopeView.layer addAnimation:animation forKey:nil];
    
}

- (void)transitionCamera {
    
    [[OSRootViewController sharedController] transitionCamera];
    
}

- (IBAction)pressToStartButtonAction:(UIButton *)sender {

    [[OSRootViewController sharedController] showTabView];

    [UIView animateWithDuration:0.3f animations:^{
        [self setAlpha:0.0f];
    } completion:^(BOOL finished) {
        [self dismiss];
    }];
}

- (void)dismiss {
    [self removeFromSuperview];
}

/*
- (void)setup {
    
    [[OSRootViewController sharedController] hideNavigationView];
    [[OSRootViewController sharedController] hideTabView];
    [[OSRootViewController sharedController] hideSideTableView];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(animateLogo)
                                   userInfo:nil
                                    repeats:NO];
    
    [NSTimer scheduledTimerWithTimeInterval:6.0f target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
}

- (void)continuousScaling {
    
    [UIView animateWithDuration:1.0 animations:^{
        
        self.logoView.transform = CGAffineTransformMakeScale(0.9f, 0.9f);

    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:1.0 animations:^{
            
            self.logoView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
            
        } completion:^(BOOL finished) {
            
        }];
    }];
}

- (void)animateLogo {
    
    CATransition* animation;
    animation      = [CATransition animation];
    animation.type = kCATransitionFade;
    {
        [self.logoView setAlpha:1.0f];
    }
    
    [self.logoView.layer addAnimation:animation forKey:nil];
    
    [[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(continuousScaling) userInfo:nil repeats:YES] fire];
    
    self.progress = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f repeats:YES block:^(NSTimer * _Nonnull timer) {
        //        10/55 * 100
        //        (1/55) * 100
        
        self.progress++;
//        NSLog(@"PROGRESS: %ld", self.progress);
        
        CGFloat progressCount = ((CGFloat)self.progress/55.0f) * 100.0f;
        self.progressLabel.text = [NSString stringWithFormat:@"%ld%%", (long)progressCount];
        
//        NSLog(@"PROGRESS COUNT: %ld", (long)progressCount);
        
    }];
    [self.timer fire];
}

- (void)dismiss {
    
    [self.timer invalidate];
    self.timer = nil;
    
    [[OSRootViewController sharedController] showTabView];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(fade)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)fade {
    [UIView animateWithDuration:1.0f animations:^{
        
        self.alpha = 0.0f;
        
    } completion:^(BOOL finished) {
        
        [self removeFromSuperview];
        
    }];
} */

@end

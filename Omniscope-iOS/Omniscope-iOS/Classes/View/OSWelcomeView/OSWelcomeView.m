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

@interface OSWelcomeView() {
    BOOL isShowing;
}

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

- (IBAction)pressToStartButtonAction:(UIButton *)sender {
    
    [[OSRootViewController sharedController] showTabView];
    
    CATransition* animation;
    animation      = [CATransition animation];
    animation.type = kCATransitionFade;
    {
        [self setAlpha:0.0f];
    }
    
    [self.layer addAnimation:animation forKey:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:0.3
                                     target:self
                                   selector:@selector(dismiss)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)dismiss {
    [self removeFromSuperview];
}

@end

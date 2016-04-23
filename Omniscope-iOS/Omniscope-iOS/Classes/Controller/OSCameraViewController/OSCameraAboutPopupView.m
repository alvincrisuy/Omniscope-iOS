//
//  OSCameraAboutPopupView.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 13/03/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSCameraAboutPopupView.h"

@interface OSCameraAboutPopupView () {
    BOOL isShowing;
}

@end

@implementation OSCameraAboutPopupView

+ (id)viewFromNib {
    NSArray* array;
    array = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([OSCameraAboutPopupView class]) owner:nil options:nil];
    if ( !array || ![array count]) {
        return nil;
    }
    
    return [array objectAtIndex:0];
}

- (void)show {
    
    if (!isShowing) {
        self.center = [[[UIApplication sharedApplication] keyWindow] center];
        [UIView animateWithDuration:0.3f animations:^(void) {
            [self.layer addAnimation:[OSCameraAboutPopupView showAnimationGroup_] forKey:nil];
            [[[UIApplication sharedApplication] keyWindow] addSubview:self];
            [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:self];
        }];
    }
    isShowing = YES;
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.contentView.bounds];
    self.contentView.layer.cornerRadius = 5.0f;
    self.contentView.layer.masksToBounds = NO;
    self.contentView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.contentView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.contentView.layer.shadowOpacity = 0.8f;
    self.contentView.layer.shadowPath = shadowPath.CGPath;
    
}

- (void)dismiss {
    
    if (isShowing) {
        [UIView animateWithDuration:0.3f animations:^(void) {
            [self removeFromSuperview];
        }];
    }
    isShowing = NO;
    
}

- (IBAction)okButtonAction:(UIButton *)sender {
    
    [self dismiss];
}

+ (CAAnimationGroup*)showAnimationGroup_
{
    static CAAnimationGroup* showAnimationGroup_ = nil;
    
    if (!showAnimationGroup_) {
        CABasicAnimation* opacityAnime;
        opacityAnime           = [[CABasicAnimation alloc] init];
        opacityAnime.keyPath   = @"opacity";
        opacityAnime.duration  = 0.3f;
        opacityAnime.fromValue = [NSNumber numberWithFloat:0.0f];
        opacityAnime.toValue   = [NSNumber numberWithFloat:1.0f];
        
        NSArray* valArraay;
        valArraay = [[NSArray alloc] initWithObjects:
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, 0.5)],
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1, 1.1, 1.1)],
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 0.9)],
                     [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)], nil];
        
        CAKeyframeAnimation* scaleAnime;
        scaleAnime          = [[CAKeyframeAnimation alloc] init];
        scaleAnime.keyPath  = @"transform";
        scaleAnime.duration = 0.32f;
        scaleAnime.values   = valArraay;
        
        NSArray* animeArraay;
        animeArraay = [[NSArray alloc] initWithObjects:
                       opacityAnime,
                       scaleAnime, nil];
        
        showAnimationGroup_            = [[CAAnimationGroup alloc] init];
        showAnimationGroup_.duration   = 0.32;
        showAnimationGroup_.animations = animeArraay;
    }
    
    return showAnimationGroup_;
}

@end

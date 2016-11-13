//
//  OSCameraImageTargetsEAGLView.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 13/03/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIGLViewProtocol.h"
#import "OSGLResourceHandler.h"
#import "Texture.h"
#import "OSApplicationSession.h"
#import "OSVideoPlayerHelper.h"

#define kNumAugmentationTextures 34

#define kNumVideoAugmentationTextures 5

static const int kNumVideoTargets = 11;

@interface OSCameraImageTargetsEAGLView : UIView <UIGLViewProtocol, OSGLResourceHandler> {
@private
    // OpenGL ES context
    EAGLContext *context;
    
    // The OpenGL ES names for the framebuffer and renderbuffers used to render
    // to this view
    GLuint defaultFramebuffer;
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;
    
    // Shader handles
    GLuint shaderProgramID;
    GLint vertexHandle;
    GLint normalHandle;
    GLint textureCoordHandle;
    GLint mvpMatrixHandle;
    GLint texSampler2DHandle;
    
    // Texture used when rendering augmentation
    Texture* augmentationTexture[kNumAugmentationTextures];
    Texture* videoAugmentationTexture[kNumVideoAugmentationTextures];

    BOOL offTargetTrackingEnabled;
    
    // VIDEO
    // Instantiate one VideoPlayerHelper per target
    OSVideoPlayerHelper *videoPlayerHelper[kNumVideoTargets];
    float videoPlaybackTime[kNumVideoTargets];
    
    // Timer to pause on-texture video playback after tracking has been lost.
    // Note: written/read on two threads, but never concurrently
    NSTimer* trackingLostTimer;
    
    // Coordinates of user touch
    float touchLocation_X;
    float touchLocation_Y;
    
    // indicates how the video will be played
    BOOL playVideoFullScreen;
    
    // Lock to synchronise data that is (potentially) accessed concurrently
    NSLock* dataLock;
}

@property (nonatomic, weak) OSApplicationSession * vapp;

- (id)initWithFrame:(CGRect)frame appSession:(OSApplicationSession *) app;

- (void)finishOpenGLESCommands;
- (void)freeOpenGLESResources;

- (void) setOffTargetTrackingMode:(BOOL) enabled;

//
- (void) willPlayVideoFullScreen:(BOOL) fullScreen;

- (void) prepare;
- (void) dismiss;

- (bool) handleTouchPoint:(CGPoint) touchPoint;

- (void) preparePlayers;
- (void) dismissPlayers;

@end

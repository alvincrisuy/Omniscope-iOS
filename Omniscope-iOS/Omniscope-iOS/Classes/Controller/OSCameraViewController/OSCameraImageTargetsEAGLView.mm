//
//  OSCameraImageTargetsEAGLView.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 13/03/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>

#import "OSCameraImageTargetsEAGLView.h"
#import "OSRootViewController.h"

#import "Vuforia.h"
#import "State.h"
#import "Tool.h"
#import "Renderer.h"
#import "TrackableResult.h"
#import "VideoBackgroundConfig.h"
#import "MultiTargetResult.h"
#import "ImageTarget.h"

#import "OSCameraImageTargetsEAGLView.h"
#import "Texture.h"
#import "OSApplicationUtils.h"
#import "OSApplicationShaderUtils.h"
#import "Quad.h"
#import "SampleMath.h"

namespace {
    // --- Data private to this unit ---
    
    // Teapot texture filenames
    const char* textureFilenames[] = {
        "emoji_heaven.png",     // 0
        "emojis.png",           // 1
        "e1.png",               // 2    USED
        "e2.png",               // 3    USED
        "e3.png",               // 4    USED
        "e4.png",               // 5    USED
        "e5.png",               // 6    USED
        "e6.png",               // 7    USED
        "e9.png",               // 8    USED
        "e10.png",              // 9    USED
        "e11.png",              // 10   USED
        "e12.png",              // 11   USED
        "e13.png",              // 12   USED
        "Aa.png",               // 13   USED
        "Ba.png",               // 14   USED
        "Ca.png",               // 15   USED
        "Da.png",               // 16   USED
        "Fa.png",               // 17   USED
        "Ga.png",               // 18   USED
        "Ha.png",               // 19   USED
        "Hb.png",               // 20   USED
        "Ia.png",               // 21   USED
        "Ja.png",               // 22   USED
        "A-tag.png",            // 23   USED
        "B-tag.png",            // 24   USED
        "C-tag.png",            // 25   USED
        "D-tag.png",            // 26   USED
        "F-tag.png",            // 27   USED
        "G-tag.png",            // 28   USED
        "H-tag.png",            // 29   USED
        "I-tag.png",            // 30   USED
        "J-tag.png",            // 31   USED
        "Ka.png",               // 32   USED
        "K-tag.png",            // 33   USED
        "hermes.png",           // 34   USED
        "merhes-tag.png",       // 35   USED
    };
    
    const char* textureVideoStateFiles[kNumAugmentationTextures] = {
        "icon_play.png",
        "icon_loading.png",
        "icon_error.png",
        "VuforiaSizzleReel_1.png",
        "VuforiaSizzleReel_2.png"
    };
    
    enum tagObjectIndex {
        OBJECT_PLAY_ICON,
        OBJECT_BUSY_ICON,
        OBJECT_ERROR_ICON,
        OBJECT_KEYFRAME_1,
        OBJECT_KEYFRAME_2,
    };
    
    const NSTimeInterval TRACKING_LOST_TIMEOUT = 2.0f;
    
    // Playback icon scale factors
    const float SCALE_ICON = 2.0f;
    
    // Video quad texture coordinates
    const GLfloat videoQuadTextureCoords[] = {
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
        0.0, 0.0,
    };
    
    struct tagVideoData {
        // Needed to calculate whether a screen tap is inside the target
        Vuforia::Matrix44F modelViewMatrix;
        
        // Trackable dimensions
        Vuforia::Vec2F targetPositiveDimensions;
        
        // Currently active flag
        BOOL isActive;
    } videoData[kNumVideoTargets];
    
    int touchedTarget = 0;
    
    // Model scale factor
    //    const float kObjectScaleNormal = 20.0f;
    //    const float kObjectScaleNormal = 55.0f;
    //    const float kObjectScaleOffTargetTracking = 12.0f;
}

@interface OSCameraImageTargetsEAGLView (PrivateMethods)

- (void)initShaders;
- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

@end

@implementation OSCameraImageTargetsEAGLView

@synthesize vapp = vapp;

// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame appSession:(OSApplicationSession *) app
{
    self = [super initWithFrame:frame];
    
    if (self) {
        vapp = app;
        // Enable retina mode if available on this device
        if (YES == [vapp isRetinaDisplay]) {
            [self setContentScaleFactor:[UIScreen mainScreen].nativeScale];
        }
        
        // Load the augmentation textures
        for (int i = 0; i < kNumAugmentationTextures; ++i) {
            augmentationTexture[i] = [[Texture alloc] initWithImageFile:[NSString stringWithCString:textureFilenames[i] encoding:NSASCIIStringEncoding]];
        }
        
        for (int i = 0; i < kNumVideoAugmentationTextures; ++i) {
            videoAugmentationTexture[i] = [[Texture alloc] initWithImageFile:[NSString stringWithCString:textureVideoStateFiles[i] encoding:NSASCIIStringEncoding]];
        }
        
        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];
        }
        
        // Generate the OpenGL ES texture and upload the texture data for use
        // when rendering the augmentation
        for (int i = 0; i < kNumAugmentationTextures; ++i) {
            GLuint textureID;
            glGenTextures(1, &textureID);
            [augmentationTexture[i] setTextureID:textureID];
            glBindTexture(GL_TEXTURE_2D, textureID);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [augmentationTexture[i] width], [augmentationTexture[i] height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[augmentationTexture[i] pngData]);
        }
        
        for (int i = 0; i < kNumVideoAugmentationTextures; ++i) {
            GLuint textureID;
            glGenTextures(1, &textureID);
            [videoAugmentationTexture[i] setTextureID:textureID];
            glBindTexture(GL_TEXTURE_2D, textureID);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [videoAugmentationTexture[i] width], [videoAugmentationTexture[i] height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[videoAugmentationTexture[i] pngData]);
            
            // Set appropriate texture parameters (for NPOT textures)
            if (OBJECT_KEYFRAME_1 <= i) {
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            }
        }
        
        offTargetTrackingEnabled = YES;
        
        [self initShaders];
    }
    
    return self;
}

- (void) willPlayVideoFullScreen:(BOOL) fullScreen {
    playVideoFullScreen = fullScreen;
}

- (void) prepare {
    // For each target, create a VideoPlayerHelper object and zero the
    // target dimensions
    // For each target, create a VideoPlayerHelper object and zero the
    // target dimensions
    for (int i = 0; i < kNumVideoTargets; ++i) {
        videoPlayerHelper[i] = [[OSVideoPlayerHelper alloc] initWithRootViewController:[OSRootViewController sharedController].cameraViewController];
        videoData[i].targetPositiveDimensions.data[0] = 0.0f;
        videoData[i].targetPositiveDimensions.data[1] = 0.0f;
    }
    
    // Start video playback from the current position (the beginning) on the
    // first run of the app
    for (int i = 0; i < kNumVideoTargets; ++i) {
        videoPlaybackTime[i] = VIDEO_PLAYBACK_CURRENT_POSITION;
    }
    
    // For each video-augmented target
    for (int i = 0; i < kNumVideoTargets; ++i) {
        // Load a local file for playback and resume playback if video was
        // playing when the app went into the background
        OSVideoPlayerHelper* player = [self getVideoPlayerHelper:i];
        NSString* filename;
        
        switch (i) {
            case 0:
                filename = @"72016_FINAL1.mp4";
                break;
            case 1:
                filename = @"BOMB1.mp4";
                break;
            case 2:
                filename = @"BOMB2.mp4";
                break;
            case 3:
                filename = @"EGG1.mp4";
                break;
            case 4:
                filename = @"EGG2.mp4";
                break;
            case 5:
                filename = @"TANK1.mp4";
                break;
            case 6:
                filename = @"TANK3.mp4";
                break;
            case 7:
                filename = @"USSOLDIER.mp4";
                break;
            case 8:
                filename = @"JAPSOLDIER.mp4";
                break;
            case 9:
                filename = @"REEL.mp4";
                break;
            case 10:
                filename = @"glitch.mp4";
                break;
            default:
                filename = @"72016_FINAL1.mp4";
                break;
        }
        
        if (NO == [player load:filename playImmediately:NO fromPosition:videoPlaybackTime[i]]) {
            NSLog(@"Failed to load media");
        }
    }
}

- (void) dismiss {
    for (int i = 0; i < kNumVideoTargets; ++i) {
        [videoPlayerHelper[i] unload];
        videoPlayerHelper[i] = nil;
    }
}

- (void)dealloc {
    [self deleteFramebuffer];
    
    // Tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    for (int i = 0; i < kNumAugmentationTextures; ++i) {
        augmentationTexture[i] = nil;
    }
    
    for (int i = 0; i < kNumVideoAugmentationTextures; ++i) {
        videoAugmentationTexture[i] = nil;
    }
    
    for (int i = 0; i < kNumVideoTargets; ++i) {
        videoPlayerHelper[i] = nil;
    }

}


- (void)finishOpenGLESCommands {
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context) {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}

- (void)freeOpenGLESResources {
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    [self deleteFramebuffer];
    glFinish();
}

- (void)setOffTargetTrackingMode:(BOOL) enabled {
    offTargetTrackingEnabled = enabled;
}

//------------------------------------------------------------------------------
#pragma mark - User interaction

- (bool) handleTouchPoint:(CGPoint) point {
    // Store the current touch location
    touchLocation_X = point.x;
    touchLocation_Y = point.y;
    
    // Determine which target was touched (if no target was touch, touchedTarget
    // will be -1)
    touchedTarget = [self tapInsideTargetWithID];
    
    // Ignore touches when videoPlayerHelper is playing in fullscreen mode
    if (-1 != touchedTarget && PLAYING_FULLSCREEN != [videoPlayerHelper[touchedTarget] getStatus]) {
        // Get the state of the video player for the target the user touched
        MEDIA_STATE mediaState = [videoPlayerHelper[touchedTarget] getStatus];
        
        // If any on-texture video is playing, pause it
        for (int i = 0; i < kNumVideoTargets; ++i) {
            if (PLAYING == [videoPlayerHelper[i] getStatus]) {
                [videoPlayerHelper[i] pause];
            }
        }
        
#ifdef EXAMPLE_CODE_REMOTE_FILE
        // With remote files, single tap starts playback using the native player
        if (ERROR != mediaState && NOT_READY != mediaState) {
            // Play the video
            NSLog(@"Playing video with native player");
            [videoPlayerHelper[touchedTarget] play:YES fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
        }
#else
        // For the target the user touched
        if (ERROR != mediaState && NOT_READY != mediaState && PLAYING != mediaState) {
            // Play the video
            NSLog(@"Playing video with on-texture player");
            [videoPlayerHelper[touchedTarget] play:playVideoFullScreen fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
        }
#endif
        return true;
    } else {
        return false;
    }
}
- (void) preparePlayers {
    [self prepare];
}


- (void) dismissPlayers {
    [self dismiss];
}

// Determine whether a screen tap is inside the target
- (int)tapInsideTargetWithID
{
    Vuforia::Vec3F intersection, lineStart, lineEnd;
    // Get the current projection matrix
    Vuforia::Matrix44F projectionMatrix = [vapp projectionMatrix];
    Vuforia::Matrix44F inverseProjMatrix = SampleMath::Matrix44FInverse(projectionMatrix);
    CGRect rect = [self bounds];
    int touchInTarget = -1;
    
    // ----- Synchronise data access -----
    [dataLock lock];
    
    // The target returns as pose the centre of the trackable.  Thus its
    // dimensions go from -width / 2 to width / 2 and from -height / 2 to
    // height / 2.  The following if statement simply checks that the tap is
    // within this range
    for (int i = 0; i < kNumVideoTargets; ++i) {
        SampleMath::projectScreenPointToPlane(inverseProjMatrix, videoData[i].modelViewMatrix, rect.size.width, rect.size.height,
                                              Vuforia::Vec2F(touchLocation_X, touchLocation_Y), Vuforia::Vec3F(0, 0, 0), Vuforia::Vec3F(0, 0, 1), intersection, lineStart, lineEnd);
        
        if ((intersection.data[0] >= -videoData[i].targetPositiveDimensions.data[0]) && (intersection.data[0] <= videoData[i].targetPositiveDimensions.data[0]) &&
            (intersection.data[1] >= -videoData[i].targetPositiveDimensions.data[1]) && (intersection.data[1] <= videoData[i].targetPositiveDimensions.data[1])) {
            // The tap is only valid if it is inside an active target
            if (YES == videoData[i].isActive) {
                touchInTarget = i;
                break;
            }
        }
    }
    
    [dataLock unlock];
    // ----- End synchronise data access -----
    
    return touchInTarget;
}

// Get a pointer to a VideoPlayerHelper object held by this EAGLView
- (OSVideoPlayerHelper*)getVideoPlayerHelper:(int)index
{
    return videoPlayerHelper[index];
}

//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods

// Draw the current frame using OpenGL
//
// This method is called by Vuforia when it wishes to render the current frame to
// the screen.
//
// *** Vuforia will call this method periodically on a background thread ***
- (void)renderFrameVuforia
{
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Render video background and retrieve tracking state
    Vuforia::State state = Vuforia::Renderer::getInstance().begin();
    Vuforia::Renderer::getInstance().drawVideoBackground();
    
    glEnable(GL_DEPTH_TEST);
    // We must detect if background reflection is active and adjust the culling direction.
    // If the reflection is active, this means the pose matrix has been reflected as well,
    // therefore standard counter clockwise face culling will result in "inside out" models.
    glDisable(GL_CULL_FACE);
    glEnable(GL_BLEND);
    
    glCullFace(GL_BACK);
    if(Vuforia::Renderer::getInstance().getVideoBackgroundConfig().mReflection == Vuforia::VIDEO_BACKGROUND_REFLECTION_ON)
        glFrontFace(GL_CW);  //Front camera
    else
        glFrontFace(GL_CCW);   //Back camera
    
    //    if (state.getNumTrackableResults()) {
    //
    //        const Vuforia::TrackableResult* result = NULL;
    //        int numResults = state.getNumTrackableResults();
    //
    //        // Browse results searching for the MultiTargets
    //        for (int j=0; j<numResults; j++) {
    //            NSLog(@"index: %d", j);
    //            result = state.getTrackableResult(j);
    //            if (result->isOfType(Vuforia::MultiTargetResult::getClassType())) {
    //                NSLog(@"ENTER is multitarget");
    //                break;
    //            }
    //
    //        }
    //
    //        // If it was not found exit
    //        if (result == NULL)
    //        {
    //            // Clean up and leave
    //            glDisable(GL_BLEND);
    //            glDisable(GL_DEPTH_TEST);
    //            glDisable(GL_CULL_FACE);
    //
    //            Vuforia::Renderer::getInstance().end();
    //            [self presentFramebuffer];
    //            return;
    //        }
    //
    //    }
    
    // ----- Synchronise data access -----
    [dataLock lock];

    // Assume all targets are inactive (used when determining tap locations)
    for (int i = 0; i < kNumVideoTargets; ++i) {
        videoData[i].isActive = NO;
    }
    
    // Set the viewport
    glViewport(vapp.viewport.posX, vapp.viewport.posY, vapp.viewport.sizeX, vapp.viewport.sizeY);
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {
        // Get the trackable
        const Vuforia::TrackableResult* result = state.getTrackableResult(i);
        const Vuforia::Trackable& trackable = result->getTrackable();
        
        //const Vuforia::Trackable& trackable = result->getTrackable();
        Vuforia::Matrix44F modelViewMatrix = Vuforia::Tool::convertPose2GLMatrix(result->getPose());
        
        // OpenGL 2
        Vuforia::Matrix44F modelViewProjection;
        
        BOOL isVideo = NO;
        int playerIndex = 0;
        
        int targetIndex = 0;
        float kObjectScaleNormal = 55.0f;
        GLfloat vertices[] = {
            -5, -10, 0, // bottom left corner
            -5,  10, 0, // top left corner
            5,  10, 0, // top right corner
            5, -10, 0  // bottom right corner
        }; // bottom right corner
        
        float xX = 0.0f;
        float yY = 0.0f;
        float zZ = 0.0f;
        
        if (!strcmp(trackable.getName(), "Track1")) {
            targetIndex = 0;
            kObjectScaleNormal = 20.0f;
            zZ = 20.0f;
            //            vertices[12] = {  -5, -5, 0, // bottom left corner
            //                              -5,  5, 0, // top left corner
            //                               5,  5, 0, // top right corner
            //                               5, -5, 0  // bottom right corner
            //                                      }; // bottom right corner
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 130.0f;
            yY = 300.0f;
            //        } else if (!strcmp(trackable.getName(), "Track2")) {
            //            // 11   12
            //            targetIndex = 12;
            //            kObjectScaleNormal = 15.0f;
            //
            //            vertices[0] = -5;
            //            vertices[1] = -5;
            //            vertices[2] = 0;
            //            vertices[3] = -5;
            //            vertices[4] = 5;
            //            vertices[5] = 0;
            //            vertices[6] = 5;
            //            vertices[7] = 5;
            //            vertices[8] = 0;
            //            vertices[9] = 5;
            //            vertices[10] = -5;
            //            vertices[11] = 0;
            //
            //            xX = 120.0f;
            //            yY = -220.0f;
            //
            //        } else if (!strcmp(trackable.getName(), "Track5")) {
            //            // 2    3
            //            targetIndex = 3;
            //            kObjectScaleNormal = 15.0f;
            //
            //            vertices[0] = -5;
            //            vertices[1] = -5;
            //            vertices[2] = 0;
            //            vertices[3] = -5;
            //            vertices[4] = 5;
            //            vertices[5] = 0;
            //            vertices[6] = 5;
            //            vertices[7] = 5;
            //            vertices[8] = 0;
            //            vertices[9] = 5;
            //            vertices[10] = -5;
            //            vertices[11] = 0;
            //
            //
            //            xX = 40.0f;
            //            yY = 300.0f;
            //
        } else if (!strcmp(trackable.getName(), "Track3")) {
            targetIndex = 1;
            kObjectScaleNormal = 100.0f;
            zZ = 100.0f;
            
            vertices[0] = -20;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -20;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 20;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 20;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 120.0f;
            yY = 220.0f;
            
        } else if (!strcmp(trackable.getName(), "T1")) {
            targetIndex = 2;
            
            kObjectScaleNormal = 100.0f;
            zZ = 100.0f;
            
            vertices[0] = -5;
            vertices[1] = -10;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 10;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 10;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -10;
            vertices[11] = 0;
            
            xX = 720.0f;
            yY = 50.0f;
        } else if (!strcmp(trackable.getName(), "T2")) {
            targetIndex = 3;
            
            kObjectScaleNormal = 25.0f;
            zZ = 25.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 440.0f;
            yY = 450.0f;
        } else if (!strcmp(trackable.getName(), "T3")) {
            targetIndex = 4;
            
            kObjectScaleNormal = 100.0f;
            zZ = 100.0f;
            
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 380.0f;
            yY = 400.0f;
            
        } else if (!strcmp(trackable.getName(), "T4")) {
            targetIndex = 5;
            
            kObjectScaleNormal = 50.0f;
            zZ = 50.0f;
            
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 380.0f;
            yY = 240.0f;
        } else if (!strcmp(trackable.getName(), "T5")) {
            targetIndex = 6;
            
            kObjectScaleNormal = 100.0f;
            zZ = 100.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 150.0f;
            yY = 180.0f;
        } else if (!strcmp(trackable.getName(), "T6")) {
            targetIndex = 7;
            
            kObjectScaleNormal = 35.0f;
            zZ = 35.0f;
            
            vertices[0] = -20;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -20;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 20;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 20;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 0.0f;
            yY = 100.0f;
        } else if (!strcmp(trackable.getName(), "T7")) {
            targetIndex = 25;
            
            // not working
        } else if (!strcmp(trackable.getName(), "T8")) {
            targetIndex = 26;
            
            // not working
        } else if (!strcmp(trackable.getName(), "T9")) {
            targetIndex = 8;
            
            kObjectScaleNormal = 100.0f;
            zZ = 100.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 250.0f;
            yY = 128.0f;
        } else if (!strcmp(trackable.getName(), "T10")) {
            targetIndex = 9;
            
            
            kObjectScaleNormal = 100.0f;
            zZ = 100.0f;
            
            vertices[0] = -9;
            vertices[1] = -4;
            vertices[2] = 0;
            
            vertices[3] = -9;
            vertices[4] = 4;
            vertices[5] = 0;
            
            vertices[6] = 8;
            vertices[7] = 4;
            vertices[8] = 0;
            
            vertices[9] = 8;
            vertices[10] = -4;
            vertices[11] = 0;
            
            xX = 20.0f;
            yY = 35.0f;
        } else if (!strcmp(trackable.getName(), "T11")) {
            targetIndex = 10;
            
            kObjectScaleNormal = 50.0f;
            zZ = 50.0f;
            
            vertices[0] = -20;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -20;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 22;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 22;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 50.0f;
            yY = 50.0f;
        } else if (!strcmp(trackable.getName(), "T12")) {
            targetIndex = 11;
            
            kObjectScaleNormal = 100.0f;
            zZ = 100.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 0.0f;
            yY = 90.0f;
            
        } else if (!strcmp(trackable.getName(), "T13")) {
            targetIndex = 12;
            
            kObjectScaleNormal = 100.0f;
            zZ = 100.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 250.0f;
            yY = 200.0f;
        } else if (!strcmp(trackable.getName(), "A1")) {
            targetIndex = 13;
            
            kObjectScaleNormal = 104.0f;
            zZ = 0.0f;
            
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 60.0f;
            yY = 271.0f;
        } else if (!strcmp(trackable.getName(), "B1")) {
            targetIndex = 14;
            
            kObjectScaleNormal = 92.0f;
            zZ = 0.0f;
            
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 70.0f;
            yY = 385.0f;
        } else if (!strcmp(trackable.getName(), "C1")) {
            targetIndex = 15;
            
            kObjectScaleNormal = 180.0f;
            zZ = 0.0f;
            
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 65.0f;
            yY = 135.0f;
        } else if (!strcmp(trackable.getName(), "D1")) {
            targetIndex = 16;
            
            kObjectScaleNormal = 130.0f;
            zZ = 0.0f;
            
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = -50.0f;
            yY = -725.0f;
        } else if (!strcmp(trackable.getName(), "E1")) {
            
        } else if (!strcmp(trackable.getName(), "F1")) {
            targetIndex = 17;
            
            kObjectScaleNormal = 300.0f;
            zZ = 0.0f;
            
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = -100.0f;
            yY = -340.0f;
        } else if (!strcmp(trackable.getName(), "G1")) {
            targetIndex = 18;
            
            kObjectScaleNormal = 365.0f;
            zZ = 0.0f;
            
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = -120.0f;
            yY = -390.0f;
        } else if (!strcmp(trackable.getName(), "H2")) {
            targetIndex = 19;
            
            kObjectScaleNormal = 155.0f;
            zZ = 0.0f;
            
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 95.0f;
            yY = 1305.0f;
        } else if (!strcmp(trackable.getName(), "H1")) {
            targetIndex = 20;
            
            kObjectScaleNormal = 80.0f;
            zZ = 0.0f;
            
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 310.0f;
            yY = -260.0f;
        } else if (!strcmp(trackable.getName(), "I1")) {
            targetIndex = 21;
            
            kObjectScaleNormal = 190.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = -20.0f;
            yY = 590.0f;
        } else if (!strcmp(trackable.getName(), "J1")) {
            targetIndex = 22;
            
            kObjectScaleNormal = 158.0f;
            zZ = 0.0f;
            
            vertices[0] = -5;
            vertices[1] = -10;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 10;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 10;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -10;
            vertices[11] = 0;
            
            xX = 8.0f;
            yY = -550.0f;
        } else if (!strcmp(trackable.getName(), "A-1")) {
            targetIndex = 23;

            kObjectScaleNormal = 50.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 50.0f;
            yY = -330.0f;
        } else if (!strcmp(trackable.getName(), "B-1")) {
            targetIndex = 24;

            kObjectScaleNormal = 50.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 150.0f;
            yY = -330.0f;
        } else if (!strcmp(trackable.getName(), "C-1")) {
            targetIndex = 25;
            
            kObjectScaleNormal = 50.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 40.0f;
            yY = 380.0f;
        } else if (!strcmp(trackable.getName(), "D-1")) {
            targetIndex = 26;

            kObjectScaleNormal = 50.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = -22.0f;
            yY = -300.0f;
        } else if (!strcmp(trackable.getName(), "F-1")) {
            targetIndex = 27;

            kObjectScaleNormal = 50.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 20.0f;
            yY = 350.0f;
        } else if (!strcmp(trackable.getName(), "G-1")) {
            targetIndex = 28;

            kObjectScaleNormal = 50.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 120.0f;
            yY = 350.0f;
        } else if (!strcmp(trackable.getName(), "H-1")) {
            targetIndex = 29;

            kObjectScaleNormal = 50.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 5.0f;
            yY = -210.0f;
        } else if (!strcmp(trackable.getName(), "I-1")) {
            targetIndex = 30;

            kObjectScaleNormal = 50.0f;
            zZ = 0.0f;
            
            vertices[0] = -20;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -20;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 20;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 20;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 250.0f;
            yY = 210.0f;
        } else if (!strcmp(trackable.getName(), "J-1")) {
            targetIndex = 31;

            kObjectScaleNormal = 50.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 10.0f;
            yY = 250.0f;
        } else if (!strcmp(trackable.getName(), "K1")) {
            targetIndex = 32;
            
            kObjectScaleNormal = 100.0f;
            zZ = 0.0f;
            
            vertices[0] = -5;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -5;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 5;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 5;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 16.0f;
            yY = 885.0f;
        } else if (!strcmp(trackable.getName(), "K-1")) {
            targetIndex = 33;
            
            kObjectScaleNormal = 50.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 0.0f;
            yY = -440.0f;
        } else if (!strcmp(trackable.getName(), "hermes")) {
            targetIndex = 34;
            
            kObjectScaleNormal = 29.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -20;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 20;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 20;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -20;
            vertices[11] = 0;
            
            xX = 225.0f;
            yY = 155.0f;
        } else if (!strcmp(trackable.getName(), "hermes2")) {
            targetIndex = 35;
            
            kObjectScaleNormal = 50.0f;
            zZ = 0.0f;
            
            vertices[0] = -10;
            vertices[1] = -5;
            vertices[2] = 0;
            
            vertices[3] = -10;
            vertices[4] = 5;
            vertices[5] = 0;
            
            vertices[6] = 10;
            vertices[7] = 5;
            vertices[8] = 0;
            
            vertices[9] = 10;
            vertices[10] = -5;
            vertices[11] = 0;
            
            xX = 0.0f;
            yY = -350.0f;
        } else if (!strcmp(trackable.getName(), "FixGear")) {
            isVideo = YES;
            playerIndex = 0;
        } else if (!strcmp(trackable.getName(), "BOMB1")) {
            isVideo = YES;
            playerIndex = 1;
        } else if (!strcmp(trackable.getName(), "BOMB2")) {
            isVideo = YES;
            playerIndex = 2;
        } else if (!strcmp(trackable.getName(), "EGG1")) {
            isVideo = YES;
            playerIndex = 3;
        } else if (!strcmp(trackable.getName(), "EGG2")) {
            isVideo = YES;
            playerIndex = 4;
        } else if (!strcmp(trackable.getName(), "TANK1")) {
            isVideo = YES;
            playerIndex = 5;
        } else if (!strcmp(trackable.getName(), "TANK3")) {
            isVideo = YES;
            playerIndex = 6;
        } else if (!strcmp(trackable.getName(), "USSOLDIER")) {
            isVideo = YES;
            playerIndex = 7;
        } else if (!strcmp(trackable.getName(), "JAPSOLDIER")) {
            isVideo = YES;
            playerIndex = 8;
        } else if (!strcmp(trackable.getName(), "REEL")) {
            isVideo = YES;
            playerIndex = 9;
        } else if (!strcmp(trackable.getName(), "glitch")) {
            isVideo = YES;
            playerIndex = 10;
        }
        
        NSLog(@"%s",trackable.getName());
        
        if (!isVideo) {
            OSApplicationUtils::translatePoseMatrix(xX, yY, zZ, &modelViewMatrix.data[0]);
            OSApplicationUtils::scalePoseMatrix(kObjectScaleNormal, kObjectScaleNormal, kObjectScaleNormal, &modelViewMatrix.data[0]);
            
            OSApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);
            
            glUseProgram(shaderProgramID);
            
            const GLfloat texices[] = {
                0, 0,
                0, 1,
                1, 1,
                1, 0
            };
            
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, vertices);
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, texices);
            
            glEnableVertexAttribArray(vertexHandle);
            glEnableVertexAttribArray(textureCoordHandle);
            
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            
            glActiveTexture(GL_TEXTURE0);
            
            glBindTexture(GL_TEXTURE_2D, augmentationTexture[targetIndex].textureID);
            glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
            glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
            
            GLubyte indices[] = {
                0, 1, 2,
                0, 2, 3,
            };
            
            glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]) , GL_UNSIGNED_BYTE, (const GLvoid*)indices);
            
            glDisableVertexAttribArray(vertexHandle);
            glDisableVertexAttribArray(textureCoordHandle);
            
        } else {
            // Mark this video (target) as active
            videoData[playerIndex].isActive = YES;
            
            // Get the target size (used to determine if taps are within the target)
            if (0.0f == videoData[playerIndex].targetPositiveDimensions.data[0] ||
                0.0f == videoData[playerIndex].targetPositiveDimensions.data[1]) {
                const Vuforia::ImageTarget& imageTarget = (const Vuforia::ImageTarget&)result->getTrackable();
                
                Vuforia::Vec3F size = imageTarget.getSize();
                videoData[playerIndex].targetPositiveDimensions.data[0] = size.data[0];
                videoData[playerIndex].targetPositiveDimensions.data[1] = size.data[1];
                
                // The pose delivers the centre of the target, thus the dimensions
                // go from -width / 2 to width / 2, and -height / 2 to height / 2
                videoData[playerIndex].targetPositiveDimensions.data[0] /= 2.0f;
                videoData[playerIndex].targetPositiveDimensions.data[1] /= 2.0f;
            }
            
            // Get the current trackable pose
            const Vuforia::Matrix34F& trackablePose = result->getPose();
            
            // This matrix is used to calculate the location of the screen tap
            videoData[playerIndex].modelViewMatrix = Vuforia::Tool::convertPose2GLMatrix(trackablePose);
            
            float aspectRatio;
            const GLvoid* texCoords;
            GLuint frameTextureID = 0;
            BOOL displayVideoFrame = YES;
            
            // Retain value between calls
            static GLuint videoTextureID[kNumVideoTargets] = {0};
            
            MEDIA_STATE currentStatus = [videoPlayerHelper[playerIndex] getStatus];
            
            if (currentStatus == READY || currentStatus == REACHED_END || currentStatus == PAUSED || currentStatus == STOPPED) {
                
#ifdef EXAMPLE_CODE_REMOTE_FILE
                // With remote files, single tap starts playback using the native player
                if (ERROR != currentStatus && NOT_READY != currentStatus) {
                    // Play the video
                    NSLog(@"Playing video with native player");
                    [videoPlayerHelper[playerIndex] play:YES fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
                }
#else
                // For the target the user touched
                if (ERROR != currentStatus && NOT_READY != currentStatus && PLAYING != currentStatus) {
                    // Play the video
                    NSLog(@"Playing video with on-texture player");
                    [videoPlayerHelper[playerIndex] play:playVideoFullScreen fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
                }
#endif
                
            }
            
            // NSLog(@"MEDIA_STATE for %d is %d", playerIndex, currentStatus);
            
            // --- INFORMATION ---
            // One could trigger automatic playback of a video at this point.  This
            // could be achieved by calling the play method of the VideoPlayerHelper
            // object if currentStatus is not PLAYING.  You should also call
            // getStatus again after making the call to play, in order to update the
            // value held in currentStatus.
            // --- END INFORMATION ---
            
            switch (currentStatus) {
                case PLAYING: {
                    // If the tracking lost timer is scheduled, terminate it
                    if (nil != trackingLostTimer) {
                        // Timer termination must occur on the same thread on which
                        // it was installed
                        [self performSelectorOnMainThread:@selector(terminateTrackingLostTimer) withObject:nil waitUntilDone:YES];
                    }
                    
                    // Upload the decoded video data for the latest frame to OpenGL
                    // and obtain the video texture ID
                    GLuint videoTexID = [videoPlayerHelper[playerIndex] updateVideoData];
                    
                    if (0 == videoTextureID[playerIndex]) {
                        videoTextureID[playerIndex] = videoTexID;
                    }
                    
                    // Fallthrough
                }
                case PAUSED:
                    if (0 == videoTextureID[playerIndex]) {
                        // No video texture available, display keyframe
                        displayVideoFrame = NO;
                    }
                    else {
                        // Display the texture most recently returned from the call
                        // to [videoPlayerHelper updateVideoData]
                        frameTextureID = videoTextureID[playerIndex];
                    }
                    
                    break;
                case READY:
                    videoTextureID[playerIndex] = 0;
                    displayVideoFrame = NO;
                    break;
                case REACHED_END:
                    videoTextureID[playerIndex] = 0;
                    displayVideoFrame = NO;
                    break;
                case STOPPED:
                    videoTextureID[playerIndex] = 0;
                    displayVideoFrame = NO;
                    break;
                default:
                    displayVideoFrame = NO;
                    break;
            }
            
            if (YES == displayVideoFrame) {
                // ---- Display the video frame -----
                aspectRatio = (float)[videoPlayerHelper[playerIndex] getVideoHeight] / (float)[videoPlayerHelper[playerIndex] getVideoWidth];
                texCoords = videoQuadTextureCoords;
            }
            else {
                // ----- Display the keyframe -----
//                Texture* t = videoAugmentationTexture[OBJECT_KEYFRAME_1 + playerIndex];
                Texture* t = videoAugmentationTexture[OBJECT_KEYFRAME_1];
                frameTextureID = [t textureID];
                aspectRatio = (float)[t height] / (float)[t width];
                texCoords = quadTexCoords;
            }
        
            // Get the current projection matrix
            Vuforia::Matrix44F projMatrix = vapp.projectionMatrix;
            
            // If the current status is valid (not NOT_READY or ERROR), render the
            // video quad with the texture we've just selected
            if (NOT_READY != currentStatus) {
                // Convert trackable pose to matrix for use with OpenGL
                Vuforia::Matrix44F modelViewMatrixVideo = Vuforia::Tool::convertPose2GLMatrix(trackablePose);
                Vuforia::Matrix44F modelViewProjectionVideo;
                
                if (playerIndex == 9) {
                    
                    NSLog(@"aspect ratio: %f", aspectRatio);
                    NSLog(@"size: %f", videoData[playerIndex].targetPositiveDimensions.data[0]);
                    
                    OSApplicationUtils::translatePoseMatrix(0.0f, 80.0f, 0.0f,
                                                            &modelViewMatrixVideo.data[0]);
                    
                    OSApplicationUtils::scalePoseMatrix(380,
                                                        380 * aspectRatio,
                                                        380,
                                                        &modelViewMatrixVideo.data[0]);
                    
                    OSApplicationUtils::multiplyMatrix(projMatrix.data,
                                                       &modelViewMatrixVideo.data[0] ,
                                                       &modelViewProjectionVideo.data[0]);
                    
                } else {
                    // normal
                    
                    OSApplicationUtils::scalePoseMatrix(videoData[playerIndex].targetPositiveDimensions.data[0],
                                                        videoData[playerIndex].targetPositiveDimensions.data[0] * aspectRatio,
                                                        videoData[playerIndex].targetPositiveDimensions.data[0],
                                                        &modelViewMatrixVideo.data[0]);
                    
                    OSApplicationUtils::multiplyMatrix(projMatrix.data,
                                                       &modelViewMatrixVideo.data[0] ,
                                                       &modelViewProjectionVideo.data[0]);
                }
                
//                // Blend the icon over the background
//                glEnable(GL_BLEND);
//                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                
                glUseProgram(shaderProgramID);
                
                glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, quadVertices);
                glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, quadNormals);
                glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
                
                glEnableVertexAttribArray(vertexHandle);
                glEnableVertexAttribArray(normalHandle);
                glEnableVertexAttribArray(textureCoordHandle);
                
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, frameTextureID);
                glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (GLfloat*)&modelViewProjectionVideo.data[0]);
                glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
                glDrawElements(GL_TRIANGLES, kNumQuadIndices, GL_UNSIGNED_SHORT, quadIndices);
                
                glDisableVertexAttribArray(vertexHandle);
                glDisableVertexAttribArray(normalHandle);
                glDisableVertexAttribArray(textureCoordHandle);
                
//                glUseProgram(videoShaderProgramID);
//                
//                glVertexAttribPointer(videoVertexHandle, 3, GL_FLOAT, GL_FALSE, 0, quadVertices);
//                glVertexAttribPointer(videoNormalHandle, 3, GL_FLOAT, GL_FALSE, 0, quadNormals);
//                glVertexAttribPointer(videoTextureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
//                
//                glEnableVertexAttribArray(videoVertexHandle);
//                glEnableVertexAttribArray(videoNormalHandle);
//                glEnableVertexAttribArray(videoTextureCoordHandle);
//                
//                glActiveTexture(GL_TEXTURE0);
//                glBindTexture(GL_TEXTURE_2D, frameTextureID);
//                glUniformMatrix4fv(videoMvpMatrixHandle, 1, GL_FALSE, (GLfloat*)&modelViewProjectionVideo.data[0]);
//                glUniform1i(videoTexSampler2DHandle, 0 /*GL_TEXTURE0*/);
//                glDrawElements(GL_TRIANGLES, kNumQuadIndices, GL_UNSIGNED_SHORT, quadIndices);
//                
//                glDisableVertexAttribArray(videoVertexHandle);
//                glDisableVertexAttribArray(videoNormalHandle);
//                glDisableVertexAttribArray(videoTextureCoordHandle);
                
                glUseProgram(0);
                
                
//                glDisable(GL_BLEND);
            }
            
            // If the current status is not PLAYING, render an icon
            if (PLAYING != currentStatus) {
                GLuint iconTextureID;
                
                switch (currentStatus) {
                    case READY:
                    case REACHED_END:
                    case PAUSED:
                    case STOPPED: {
                        // ----- Display play icon -----
                        iconTextureID = [videoAugmentationTexture[OBJECT_PLAY_ICON] textureID];
                        break;
                    }
                        
                    case ERROR: {
                        // ----- Display error icon -----
                        iconTextureID = [videoAugmentationTexture[OBJECT_ERROR_ICON] textureID];
                        break;
                    }
                        
                    default: {
                        // ----- Display busy icon -----
                        iconTextureID = [videoAugmentationTexture[OBJECT_BUSY_ICON] textureID];
                        break;
                    }
                }
                
                // Convert trackable pose to matrix for use with OpenGL
                Vuforia::Matrix44F modelViewMatrixButton = Vuforia::Tool::convertPose2GLMatrix(trackablePose);
                Vuforia::Matrix44F modelViewProjectionButton;
                
                //SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON_TRANSLATION, &modelViewMatrixButton.data[0]);
                OSApplicationUtils::translatePoseMatrix(0.0f, 0.0f, 5.0f, &modelViewMatrixButton.data[0]);
                
                OSApplicationUtils::scalePoseMatrix(videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON,
                                                        videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON,
                                                        videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON,
                                                        &modelViewMatrixButton.data[0]);
                
                OSApplicationUtils::multiplyMatrix(projMatrix.data,
                                                       &modelViewMatrixButton.data[0] ,
                                                       &modelViewProjectionButton.data[0]);
                
                glDepthFunc(GL_LEQUAL);
                
                glUseProgram(shaderProgramID);
                
                glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, quadVertices);
                glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, quadNormals);
                glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, quadTexCoords);
                
                glEnableVertexAttribArray(vertexHandle);
                glEnableVertexAttribArray(normalHandle);
                glEnableVertexAttribArray(textureCoordHandle);
                
                // Blend the icon over the background
                glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, iconTextureID);
                glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (GLfloat*)&modelViewProjectionButton.data[0] );
                glDrawElements(GL_TRIANGLES, kNumQuadIndices, GL_UNSIGNED_SHORT, quadIndices);
                
                glDisable(GL_BLEND);
                
                glDisableVertexAttribArray(vertexHandle);
                glDisableVertexAttribArray(normalHandle);
                glDisableVertexAttribArray(textureCoordHandle);
                
                glUseProgram(0);
                
                glDepthFunc(GL_LESS);
            }
        }
        
        OSApplicationUtils::checkGlError("EAGLView renderFrameVuforia");
    }
    
    for (int i = 0; i < kNumVideoTargets; ++i) {
        if (nil == trackingLostTimer && NO == videoData[i].isActive && PLAYING == [videoPlayerHelper[i] getStatus]) {
            [self performSelectorOnMainThread:@selector(createTrackingLostTimer) withObject:nil waitUntilDone:YES];
            break;
        }
    }
    
    [dataLock unlock];
    // ----- End synchronise data access -----
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glDisable(GL_BLEND);
    
    Vuforia::Renderer::getInstance().end();
    [self presentFramebuffer];
}

// Create the tracking lost timer
- (void)createTrackingLostTimer
{
    trackingLostTimer = [NSTimer scheduledTimerWithTimeInterval:TRACKING_LOST_TIMEOUT target:self selector:@selector(trackingLostTimerFired:) userInfo:nil repeats:NO];
}


// Terminate the tracking lost timer
- (void)terminateTrackingLostTimer
{
    [trackingLostTimer invalidate];
    trackingLostTimer = nil;
}


// Tracking lost timer fired, pause video playback
- (void)trackingLostTimerFired:(NSTimer*)timer
{
    // Tracking has been lost for TRACKING_LOST_TIMEOUT seconds, pause playback
    // (we can safely do this on all our VideoPlayerHelpers objects)
    for (int i = 0; i < kNumVideoTargets; ++i) {
        [videoPlayerHelper[i] pause];
    }
    trackingLostTimer = nil;
}

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void)initShaders {
    shaderProgramID = [OSApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                               fragmentShaderFileName:@"Simple.fragsh"];
    if (0 < shaderProgramID) {
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");
    }
    else {
        NSLog(@"Could not initialise augmentation shader");
    }
    
    videoShaderProgramID = [OSApplicationShaderUtils createProgramWithVertexShaderFileName:@"VideoAlpha.vertsh"
                                                                    fragmentShaderFileName:@"VideoAlpha.fragsh"];
    if (0 < videoShaderProgramID) {
        videoVertexHandle = glGetAttribLocation(videoShaderProgramID, "vertexPosition");
        videoNormalHandle = glGetAttribLocation(videoShaderProgramID, "vertexNormal");
        videoTextureCoordHandle = glGetAttribLocation(videoShaderProgramID, "vertexTexCoord");
        videoMvpMatrixHandle = glGetUniformLocation(videoShaderProgramID, "modelViewProjectionMatrix");
        videoTexSampler2DHandle  = glGetUniformLocation(videoShaderProgramID,"texSamplerOES");
    }
    else {
        NSLog(@"Could not initialise augmentation shader");
    }
}

- (void)createFramebuffer {
    if (context) {
        // Create default framebuffer object
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create colour renderbuffer and allocate backing store
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        GLint framebufferWidth;
        GLint framebufferHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
}

- (void)deleteFramebuffer {
    if (context) {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer) {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer) {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
        
        if (depthRenderbuffer) {
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}

- (void)setFramebuffer {
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    // it the first time this method is called (on the render thread)
    if (context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer) {
        // Perform on the main thread to ensure safe memory allocation for the
        // shared buffer.  Block until the operation is complete to prevent
        // simultaneous access to the OpenGL context
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}

- (BOOL)presentFramebuffer {
    // setFramebuffer must have been called before presentFramebuffer, therefore
    // we know the context is valid and has been set for this (render) thread
    
    // Bind the colour render buffer and present it
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}

@end

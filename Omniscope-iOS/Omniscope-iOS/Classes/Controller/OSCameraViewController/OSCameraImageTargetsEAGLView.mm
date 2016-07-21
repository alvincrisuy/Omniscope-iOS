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

#import "Vuforia.h"
#import "State.h"
#import "Tool.h"
#import "Renderer.h"
#import "TrackableResult.h"
#import "VideoBackgroundConfig.h"
#import "MultiTargetResult.h"

#import "OSCameraImageTargetsEAGLView.h"
#import "Texture.h"
#import "OSApplicationUtils.h"
#import "OSApplicationShaderUtils.h"

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
    };
    
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
            [self setContentScaleFactor:2.0f];
        }
        
        // Load the augmentation textures
        for (int i = 0; i < kNumAugmentationTextures; ++i) {
            augmentationTexture[i] = [[Texture alloc] initWithImageFile:[NSString stringWithCString:textureFilenames[i] encoding:NSASCIIStringEncoding]];
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
        
        offTargetTrackingEnabled = YES;
        
        [self initShaders];
    }
    
    return self;
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

- (void) setOffTargetTrackingMode:(BOOL) enabled {
    offTargetTrackingEnabled = enabled;
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
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {
        // Get the trackable
        const Vuforia::TrackableResult* result = state.getTrackableResult(i);
        
        const Vuforia::Trackable& trackable = result->getTrackable();
        
        //const Vuforia::Trackable& trackable = result->getTrackable();
        Vuforia::Matrix44F modelViewMatrix = Vuforia::Tool::convertPose2GLMatrix(result->getPose());
        
        // OpenGL 2
        Vuforia::Matrix44F modelViewProjection;
        
        int targetIndex = 0;
        float kObjectScaleNormal = 55.0f;
        GLfloat vertices[] = {  -5, -10, 0, // bottom left corner
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
        }
        
        OSApplicationUtils::translatePoseMatrix(xX, yY, zZ, &modelViewMatrix.data[0]);
        OSApplicationUtils::scalePoseMatrix(kObjectScaleNormal, kObjectScaleNormal, kObjectScaleNormal, &modelViewMatrix.data[0]);
        
        OSApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);
        
        //        float x = modelViewMatrix.data[12];
        //        float y = modelViewMatrix.data[13];
        //        float z = modelViewMatrix.data[14];
        //        float distance = sqrt(x*x + y*y + z*z);
        
        //        NSLog(@"DISTANCE: %f", distance);
        
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
        
        OSApplicationUtils::checkGlError("EAGLView renderFrameVuforia");
    }
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glDisable(GL_BLEND);
    
    Vuforia::Renderer::getInstance().end();
    [self presentFramebuffer];
}

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void)initShaders {
    shaderProgramID = [OSApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                               fragmentShaderFileName:@"Simple.fragsh"];
    //
    //    Vuforia::setHint(Vuforia::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, 5);
    //
    //    Vuforia::setHint(Vuforia::HINT_MAX_SIMULTANEOUS_OBJECT_TARGETS, 2);
    
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

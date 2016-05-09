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

#import "QCAR.h"
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
        "emoji_heaven.png",     // 1
//        "emoji1.png",           // 2
//        "emoji2.png",           // 3
//        "emoji3.png",           // 4
//        "emoji4.png",           // 5
//        "emoji5.png",           // 6
//        "emoji6.png",           // 7
//        "emoji7.png",           // 8
//        "emoji8.png",           // 9
//        "emoji9.png",           // 10
//        "emoji10.png",          // 11
//        "emoji11.png",          // 12
//        "emoji12.png",          // 13
//        "emoji13.png",          // 14
//        "emoji14.png",          // 15
//        "emoji15.png",          // 16
//        "emoji16.png",          // 17
        "emojis.png",           // 18
        "e1.png",               // 19
        "e2.png",               // 20
        "e3.png",               // 21
        "e4.png",               // 22
        "e5.png",               // 23
        "e6.png",               // 24
//        "e7.png",               // 25
//        "e8.png",               // 26
        "e9.png",               // 27
        "e10.png",              // 28
        "e11.png",              // 29
        "e12.png",              // 30
        "e13.png",              // 31
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


- (void)dealloc
{
    [self deleteFramebuffer];
    
    // Tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    for (int i = 0; i < kNumAugmentationTextures; ++i) {
        augmentationTexture[i] = nil;
    }
}


- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context) {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}


- (void)freeOpenGLESResources
{
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
// This method is called by QCAR when it wishes to render the current frame to
// the screen.
//
// *** QCAR will call this method periodically on a background thread ***
- (void)renderFrameQCAR
{
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Render video background and retrieve tracking state
    QCAR::State state = QCAR::Renderer::getInstance().begin();
    QCAR::Renderer::getInstance().drawVideoBackground();
    
    glEnable(GL_DEPTH_TEST);
    // We must detect if background reflection is active and adjust the culling direction.
    // If the reflection is active, this means the pose matrix has been reflected as well,
    // therefore standard counter clockwise face culling will result in "inside out" models.
    glDisable(GL_CULL_FACE);
    glEnable(GL_BLEND);
    
    glCullFace(GL_BACK);
    if(QCAR::Renderer::getInstance().getVideoBackgroundConfig().mReflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON)
        glFrontFace(GL_CW);  //Front camera
    else
        glFrontFace(GL_CCW);   //Back camera
    
//    if (state.getNumTrackableResults()) {
//        
//        const QCAR::TrackableResult* result = NULL;
//        int numResults = state.getNumTrackableResults();
//        
//        // Browse results searching for the MultiTargets
//        for (int j=0; j<numResults; j++) {
//            NSLog(@"index: %d", j);
//            result = state.getTrackableResult(j);
//            if (result->isOfType(QCAR::MultiTargetResult::getClassType())) {
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
//            QCAR::Renderer::getInstance().end();
//            [self presentFramebuffer];
//            return;
//        }
//        
//    }
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {
        // Get the trackable
        const QCAR::TrackableResult* result = state.getTrackableResult(i);
        
        const QCAR::Trackable& trackable = result->getTrackable();
        
        //const QCAR::Trackable& trackable = result->getTrackable();
        QCAR::Matrix44F modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(result->getPose());
        
        // OpenGL 2
        QCAR::Matrix44F modelViewProjection;
        
        int targetIndex = 0;
        float kObjectScaleNormal = 55.0f;
        GLfloat vertices[] = {  -5, -10, 0, // bottom left corner
            -5,  10, 0, // top left corner
            5,  10, 0, // top right corner
            5, -10, 0  // bottom right corner
        }; // bottom right corner
        
        float xX = 0.0f;
        float yY = 0.0f;
        
        if (!strcmp(trackable.getName(), "Track1")) {
            targetIndex = 0;
            kObjectScaleNormal = 20.0f;
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
        }
        
        OSApplicationUtils::translatePoseMatrix(xX, yY, kObjectScaleNormal, &modelViewMatrix.data[0]);
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
        
        OSApplicationUtils::checkGlError("EAGLView renderFrameQCAR");
    }
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glDisable(GL_BLEND);
    
    QCAR::Renderer::getInstance().end();
    [self presentFramebuffer];
}

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void)initShaders {
    shaderProgramID = [OSApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                                   fragmentShaderFileName:@"Simple.fragsh"];
//    
//    QCAR::setHint(QCAR::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, 5);
//    
//    QCAR::setHint(QCAR::HINT_MAX_SIMULTANEOUS_OBJECT_TARGETS, 2);
    
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

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

#define kNumAugmentationTextures 16

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
    
    BOOL offTargetTrackingEnabled;
}

@property (nonatomic, weak) OSApplicationSession * vapp;

- (id)initWithFrame:(CGRect)frame appSession:(OSApplicationSession *) app;

- (void)finishOpenGLESCommands;
- (void)freeOpenGLESResources;

- (void) setOffTargetTrackingMode:(BOOL) enabled;

@end

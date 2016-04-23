//
//  OSGLResourceHandler.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 09/03/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

@protocol OSGLResourceHandler

@required
- (void) freeOpenGLESResources;
- (void) finishOpenGLESCommands;

@end
//
//  OSApplicationShaderUtils.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 13/03/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSApplicationShaderUtils : NSObject

+ (int)createProgramWithVertexShaderFileName:(NSString*) vertexShaderFileName
                      fragmentShaderFileName:(NSString*) fragmentShaderFileName;

+ (int)createProgramWithVertexShaderFileName:(NSString*) vertexShaderFileName
                        withVertexShaderDefs:(NSString *) vertexShaderDefs
                      fragmentShaderFileName:(NSString *) fragmentShaderFileName
                      withFragmentShaderDefs:(NSString *) fragmentShaderDefs;

@end

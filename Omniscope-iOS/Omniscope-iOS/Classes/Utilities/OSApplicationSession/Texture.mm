//
//  Texture.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 13/03/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "Texture.h"
#import <UIKit/UIKit.h>

// Private method declarations
@interface Texture (PrivateMethods)
- (BOOL)loadImage:(NSString*)filename;
- (BOOL)copyImageDataForOpenGL:(CFDataRef)imageData;
@end


@implementation Texture

//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithImageFile:(NSString*)filename
{
    self = [super init];
    
    if (nil != self) {
        if (NO == [self loadImage:filename]) {
            NSLog(@"Failed to load texture image from file %@", filename);
            self = nil;
        }
    }
    
    return self;
}


- (void)dealloc
{
    if (_pngData) {
        delete[] _pngData;
    }
}


//------------------------------------------------------------------------------
#pragma mark - Private methods

- (BOOL)loadImage:(NSString*)filename
{
    BOOL ret = NO;
    
    // Build the full path of the image file
    NSString* fullPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
    
    // Create a UIImage with the contents of the file
    UIImage* uiImage = [UIImage imageWithContentsOfFile:fullPath];
    
    if (uiImage) {
        // Get the inner CGImage from the UIImage wrapper
        CGImageRef cgImage = uiImage.CGImage;
        
        // Get the image size
        _width = (int)CGImageGetWidth(cgImage);
        _height = (int)CGImageGetHeight(cgImage);
        
        // Record the number of channels
        channels = (int)CGImageGetBitsPerPixel(cgImage)/CGImageGetBitsPerComponent(cgImage);
        
        // Generate a CFData object from the CGImage object (a CFData object represents an area of memory)
        CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
        
        // Copy the image data for use by Open GL
        ret = [self copyImageDataForOpenGL: imageData];
        
        CFRelease(imageData);
    }
    
    return ret;
}


- (BOOL)copyImageDataForOpenGL:(CFDataRef)imageData
{
    if (_pngData) {
        delete[] _pngData;
    }
    
    NSLog(@"count: %ld", (long)_width * _height * channels);
    
    _pngData = new unsigned char[_width * _height * channels];
    const int rowSize = _width * channels;
    const unsigned char* pixels = (unsigned char*)CFDataGetBytePtr(imageData);
    
    // Copy the row data from bottom to top
    for (int i = 0; i < _height; ++i) {
        memcpy(_pngData + rowSize * i, pixels + rowSize * (_height - 1 - i), _width * channels);
    }
    
    return YES;
}

@end

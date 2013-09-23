//
//  UIImage+GBFancyCamera.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 29/08/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "UIImage+GBFancyCamera.h"

#import <QuartzCore/QuartzCore.h>

@implementation UIImage (GBFancyCamera)

+(UIImage *)imageWithSolidColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

-(UIImage *)rotateInRadians:(float)radians {
	// Create an ARGB bitmap context
	const size_t width = (size_t)CGImageGetWidth(self.CGImage);
	const size_t height = (size_t)CGImageGetHeight(self.CGImage);

	CGRect rotatedRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height), CGAffineTransformMakeRotation(radians));

	CGContextRef bmContext = CGBitmapContextCreate(NULL, (size_t)rotatedRect.size.width, (size_t)rotatedRect.size.height, 8/*Bits per component*/, (size_t)rotatedRect.size.width * 4, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    if (!bmContext) @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Could not create bitmapContext with width: %zu, height: %zu", width, height] userInfo:nil];

	// Image quality
	CGContextSetShouldAntialias(bmContext, true);
	CGContextSetAllowsAntialiasing(bmContext, true);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);

	// Rotation happen here (around the center)
	CGContextTranslateCTM(bmContext, +(rotatedRect.size.width / 2.0f), +(rotatedRect.size.height / 2.0f));
	CGContextRotateCTM(bmContext, radians);

	// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, CGRectMake(-(width / 2.0f), -(height / 2.0f), width, height), self.CGImage);

	// Create an image object from the context
	CGImageRef resultImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage *resultImage = [UIImage imageWithCGImage:resultImageRef scale:self.scale orientation:self.imageOrientation];

	// Cleanup
	CGImageRelease(resultImageRef);
	CGContextRelease(bmContext);

	return resultImage;
}

// Returns a rescaled copy of the image, taking into account its orientation
// The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
-(UIImage *)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality {
    BOOL drawTransposed;
    switch ( self.imageOrientation )
    {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            drawTransposed = YES;
            break;
        default:
            drawTransposed = NO;
    }
    
    CGAffineTransform transform = [self transformForOrientation:newSize];
    
    return [self resizedImage:newSize transform:transform drawTransposed:drawTransposed interpolationQuality:quality];
}

// Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
// The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
// If the new size is not integral, it will be rounded up
- (UIImage *)resizedImage:(CGSize)newSize
                transform:(CGAffineTransform)transform
           drawTransposed:(BOOL)transpose
     interpolationQuality:(CGInterpolationQuality)quality {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    CGImageRef imageRef = self.CGImage;
    
    // Fix for a colorspace / transparency issue that affects some types of
    // images. See here: http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/comment-page-2/#comment-39951
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap =CGBitmapContextCreate( NULL,
                                               newRect.size.width,
                                               newRect.size.height,
                                               8,
                                               0,
                                               colorSpace,
                                               kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast );
    
    CGColorSpaceRelease(colorSpace);
	
    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, transform);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, quality);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    
    return newImage;
}

// Returns an affine transform that takes into account the image orientation when drawing a scaled image
- (CGAffineTransform)transformForOrientation:(CGSize)newSize {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:           // EXIF = 3
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    return transform;
}

@end

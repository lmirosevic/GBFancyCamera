//
//  UIImage+Rotation.h
//  NYXImagesKit
//
//  Created by @Nyx0uf on 02/05/11.
//  Copyright 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "NYXImagesHelper.h"

#import <UIKit/UIKit.h>

@interface UIImage (NYX_Rotating)

-(UIImage *)rotateInRadians:(float)radians;

-(UIImage *)cropToRect:(CGRect)rect;
-(UIImage *)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality;
-(UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode bounds:(CGSize)bounds interpolationQuality:(CGInterpolationQuality)quality;
+(UIImage *)imageWithSolidColor:(UIColor *)color;

@end

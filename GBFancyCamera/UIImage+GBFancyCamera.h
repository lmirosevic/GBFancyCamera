//
//  UIImage+GBFancyCamera.h
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 29/08/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (GBFancyCamera)

+(UIImage *)imageWithSolidColor:(UIColor *)color;

-(UIImage *)rotateInRadians:(float)radians;

-(UIImage *)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality;

@end

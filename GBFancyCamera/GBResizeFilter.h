//
//  GBResizeFilter.h
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 06/09/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GPUImageFilter.h"

#define GBResizeFilterUnlimitedResolution CGFLOAT_MAX

@interface GBResizeFilter : GPUImageFilter

@property (assign, nonatomic) CGFloat       outputResolution;
@property (assign, nonatomic) CGSize        outputSize;

-(id)initWithOutputResolution:(CGFloat)resolution aspectRatio:(CGFloat)aspectRatio;
-(id)initWithOutputSize:(CGSize)outputSize;

@end

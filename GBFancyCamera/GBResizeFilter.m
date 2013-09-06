//
//  GBResizeFilter.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 06/09/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBResizeFilter.h"

@interface GBResizeFilter ()

@property (assign, nonatomic)       CGFloat aspectRatio;

@end

@implementation GBResizeFilter

#pragma mark - CA

-(void)setOutputResolution:(CGFloat)outputResolution {
    if (outputResolution < 0) @throw [NSException exceptionWithName:NSArgumentDomain reason:@"outputResolution must be positive" userInfo:nil];
    
    _outputResolution = outputResolution;
    
    if (outputResolution == GBResizeFilterUnlimitedResolution) {
        [self forceProcessingAtSizeRespectingAspectRatio:CGSizeZero];
    }
    else {
        CGFloat boxSide = sqrtf(outputResolution) * self.aspectRatio;
        [self forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(boxSide, boxSide)];
    }
}

#pragma mark - mem

-(id)initWithOutputResolution:(CGFloat)resolution cameraAspectRatio:(CGFloat)aspectRatio {
    if (self = [super init]) {
        self.outputResolution = resolution;
        self.aspectRatio = aspectRatio;
    }
    
    return self;
}

@end

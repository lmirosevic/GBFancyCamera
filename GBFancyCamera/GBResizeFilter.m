//
//  GBResizeFilter.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 06/09/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBResizeFilter.h"

@interface GBResizeFilter ()

@property (assign, nonatomic) CGFloat               aspectRatio;

@end

@implementation GBResizeFilter

#pragma mark - CA

-(void)setOutputResolution:(CGFloat)outputResolution {
    if (outputResolution < 0) @throw [NSException exceptionWithName:NSArgumentDomain reason:@"outputResolution must be positive" userInfo:nil];
    
    if (outputResolution == GBResizeFilterUnlimitedResolution) {
        self.outputSize = CGSizeZero;
    }
    else {
        CGFloat boxSide = sqrtf(outputResolution * self.aspectRatio);
        self.outputSize = CGSizeMake(boxSide, boxSide);
    }
}

-(CGFloat)outputResolution {
    return self.outputSize.width * self.outputSize.height;
}

-(void)setOutputSize:(CGSize)outputSize {
    if (outputSize.width < 0 || outputSize.height < 0) @throw [NSException exceptionWithName:NSArgumentDomain reason:@"outputSize must be positive in both dimensions" userInfo:nil];
    
    _outputSize = outputSize;
    
    [self forceProcessingAtSizeRespectingAspectRatio:outputSize];
}

#pragma mark - GBFancyCameraFilterProtocol

-(NSString *)localisedName {
    return NSLocalizedStringFromTableInBundle(@"Resizer", @"GBFancyCameraLocalizations", [[GBFancyCamera class] resourcesBundle], @"filter name");
}

#pragma mark - mem

-(id)initWithOutputResolution:(CGFloat)resolution aspectRatio:(CGFloat)aspectRatio {
    if (self = [super init]) {
        [self _commonResizeFilterInit];
        
        self.aspectRatio = aspectRatio;
        self.outputResolution = resolution;//relies on aspectRatio being set
    }
    
    return self;
}

-(id)initWithOutputSize:(CGSize)outputSize {
    if (self = [super init]) {
        [self _commonResizeFilterInit];
        
        self.outputSize = outputSize;
    }
    
    return self;
}

-(void)_commonResizeFilterInit {
//    self.shouldSmoothlyScaleOutput = YES;//foo
}

@end

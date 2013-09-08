//
//  GBSepiaFilter.h
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 06/09/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBFancyCamera.h"
#import "GBFancyCameraFilterProtocol.h"
#import "GPUImage.h"

@interface GBSepiaFilter : GPUImageSepiaFilter <GBFancyCameraFilterProtocol>

@end

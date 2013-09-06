//
//  GBFancyCamera.h
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 29/08/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GBFancyCameraFilters.h"
#import "GBFancyCameraFilterProtocol.h"

typedef enum {
    GBFancyCameraSourceNone,
    GBFancyCameraSourceCamera,
    GBFancyCameraSourceCameraRoll,
} GBFancyCameraSource;

typedef void(^GBFancyCameraCompletionBlock)(UIImage *originalImage, UIImage *processedImage, BOOL didTakePhoto, GBFancyCameraSource source, BOOL *shouldAutoDismiss);
#define GBUnlimitedImageResolution CGFLOAT_MAX

@protocol GBFanceCameraDelegate;

@interface GBFancyCamera : UIViewController

//if you set a delegate, he will be notified when a pic is taken or when taking is cancelled
@property (weak, nonatomic) id<GBFanceCameraDelegate>       delegate;

//set to an array of filter objects that inherit from GPUImageOutput and that conform to GBFancyCameraFilterProtocol & GPUImageInput
@property (strong, nonatomic) NSArray                       *filters;

//resize the output image
@property (assign, nonatomic) CGFloat                       outputImageResolution;//default: GBUnlimitedResolution

//get the singleton instance
+(GBFancyCamera *)sharedCamera;

//you can create many instances if you need to
-(id)init;

//block based photo snapping. will present the UI onto [[UIApplication sharedApplication].keyWindow.rootViewController if it isn't presented yet
-(void)takePhotoWithBlock:(GBFancyCameraCompletionBlock)block;

@end

@protocol GBFanceCameraDelegate <NSObject>

-(void)fancyCamera:(GBFancyCamera *)fancyCamera didTakePhotoWithOriginalImage:(UIImage *)originalImage processedImage:(UIImage *)processedImage fromSource:(GBFancyCameraSource)source;
-(void)fancyCameraDidCancelTakingPhoto:(GBFancyCamera *)fancyCamera;

@end
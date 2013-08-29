//
//  GBFancyCamera.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 29/08/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBFancyCamera.h"

#import "GPUImage.h"

static CGFloat const kBottomBarHeight =                     80;

typedef enum {
    GBFancyCameraStateCapturing,
    GBFancyCameraStateEditing
} GBFancyCameraState;

@interface GBFancyCamera ()

@property (assign, nonatomic) GBFancyCameraState            state;

@property (strong, nonatomic) GPUImageStillCamera           *stillCamera;

@end

@implementation GBFancyCamera

#pragma mark - CA

-(void)setState:(GBFancyCameraState)state {
    [self _transitionToState:state animated:NO];
}

#pragma mark - Life

-(void)viewDidLoad {
    [super viewDidLoad];

    //set up camera stuff
    self.stillCamera = [[GPUImageStillCamera alloc] init];
    GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x,
                                                                              self.view.bounds.origin.y,
                                                                              self.view.bounds.size.width,
                                                                              self.view.bounds.size.height - kBottomBarHeight)];
    GPUImageGammaFilter *filter = [[GPUImageGammaFilter alloc] init];
    
    
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [self.stillCamera addTarget:filter];
    [filter addTarget:filterView];
    [self.view addSubview:filterView];
    
    //add controls
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //turn on the camera
    [self.stillCamera startCameraCapture];
    
    //add the shutter on top and make it ready
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //animate the shutter away
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    //turn off camera capture
    
    //get rid of the shutter (idempotently)
}

//need to be able to handle different orientation, always, even if the app only claims to only support a single orientation

#pragma mark - Util

-(void)_capturePhoto {
    
}

-(void)_transitionToState:(GBFancyCameraState)state animated:(BOOL)animated {
    if (_state != state) {
        _state = state;//foo maybe do this at the bottom
    }
    
    
}

#pragma mark - Actions

@end

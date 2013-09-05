//
//  GBFancyCamera.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 29/08/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBFancyCamera.h"

#import "GPUImage.h"

static CGFloat const kBottomBarHeight =                             48;
static CGFloat const kBottomBarBottomOffset =                       0;
static CGFloat const kBarButtonsBottomCenterOffset =                2;
static CGFloat const kMainButtonBottomCenterOffset =                2;
static CGFloat const kMainButtonAcceptModeRightCenterMargin =       23;
static CGFloat const kRetakeButtonRightCenterMargin =               73;
static CGFloat const kCancelButtonLeftCenterMargin =                24;
static CGFloat const kCameraRollButtonRightCenterMargin =           24;

static CGFloat const kBarButtonsFanoutRadius =                      6;//defines how much bigger the button is than its image
static CGFloat const kMainButtonFanoutRadius =                      0;//defines how much bigger the button is than its image

static CGFloat const kFilterTrayHeight =                            79;
static CGFloat const kFilterTrayBottomOffsetOpen =                  44;
static CGFloat const kFilterTrayBottomOffsetClosed =                kBottomBarHeight + kBottomBarBottomOffset - kFilterTrayHeight - 0;

static UIEdgeInsets const kCameraViewportPadding =                  (UIEdgeInsets){0, 0, 40, 0};

static UIEdgeInsets const kFiltersScrollViewMargin =                (UIEdgeInsets){8, 0, 1, 0};//so it doesn't cover stuff or go too far
static UIEdgeInsets const kFiltersScrollViewContentInset =          (UIEdgeInsets){0, 4, 0, 50};//add some right padding, maybe some left

static CGSize const kThumbnailBoxSize =                             (CGSize){56, 70};
static UIEdgeInsets const kThumbnailBoxMargin =                     (UIEdgeInsets){4, 4, 0, 4};//collapsible

static CGFloat const kThumbnailBackgroundImageTopCenterMargin =     30;

static CGFloat const kImageTopCenterMargin =                        30;
static CGFloat const kImageCornerRadius =                           4;

#define kFilterNameFont                                             [UIFont fontWithName:@"HelveticaNeue-Medium" size:12]
#define kFilterNameTextColorOff                                     [UIColor colorWithWhite:1 alpha:0.76]
#define kFilterNameShadowColorOff                                   [UIColor colorWithWhite:0 alpha:1]
#define kFilterNameTextColorOn                                      [UIColor colorWithWhite:1 alpha:1]
#define kFilterNameShadowColorOn                                    [UIColor colorWithWhite:0 alpha:1]
static CGSize const kFilterNameShadowOffset =                       (CGSize){0, 1};
static CGFloat const kFilterNameTopCenterMargin =                   63;

#define kBarHeadingFont                                             [UIFont fontWithName:@"HelveticaNeue-Bold" size:20]
#define kBarHeadingShadowColor                                      [UIColor colorWithWhite:0 alpha:1]
static CGSize const kBarHeadingShadowOffset =                       (CGSize){0, 1};

static BOOL const kDefaultShouldAutoDismiss =                       YES;

typedef enum {
    GBFancyCameraStateCapturing,
    GBFancyCameraStateFilters
} GBFancyCameraState;

@interface GBFancyCamera ()

@property (assign, nonatomic) GBFancyCameraState                    state;

@property (strong, nonatomic) GPUImageStillCamera                   *stillCamera;

@property (strong, nonatomic) UIView                                *barContainerView;
@property (strong, nonatomic) UIImageView                           *barBackgroundImageView;

@property (strong, nonatomic) UIButton                              *mainButton;
@property (strong, nonatomic) UIButton                              *cancelButton;
@property (strong, nonatomic) UIButton                              *cameraRollButton;
@property (strong, nonatomic) UIButton                              *retakeButton;

@property (strong, nonatomic) UIView                                *filtersContainerView;
@property (strong, nonatomic) UIImageView                           *filtersBackgroundImageView;
@property (strong, nonatomic) UIScrollView                          *filtersScrollView;

@property (strong, nonatomic) UILabel                               *barHeadingLabel;

@property (strong, nonatomic) NSArray                               *thumbnailViews;

@property (assign, nonatomic) BOOL                                  isPresented;
@property (copy, nonatomic) GBFancyCameraCompletionBlock            completionBlock;
@property (strong, nonatomic) UIImage                               *originalImage;
@property (strong, nonatomic) UIImage                               *processedImage;

@end

@implementation GBFancyCamera

//foo tapping a filter thumb should scroll to him
//foo needs to handle case where there is no camera (e.g. simulator)
//up would be nice to be able to handle different orientation, always, even if the app only claims to only support a single orientation
//up would be nice to be able to switch camera and turn on flash
//foo dont forget image res

#pragma mark - Memory

+(GBFancyCamera *)sharedCamera {
    static GBFancyCamera *_sharedCamera;
    @synchronized(self) {
        if (!_sharedCamera) {
            _sharedCamera = [self new];
        }
    }
    
    return _sharedCamera;
}

-(id)init {
    if (self = [super init]) {

    }
    
    return self;
}

#pragma mark - CA

-(void)setState:(GBFancyCameraState)state {
    [self _transitionToState:state animated:NO];
}

-(UIImage *)processedImage {
    //if we didn't do any processing, just return the original
    if (_processedImage) {
        return _processedImage;
    }
    else {
        return self.originalImage;
    }
}

#pragma mark - Life

-(void)viewDidLoad {
    [super viewDidLoad];

    //full screen stuff
    self.view.backgroundColor = [UIColor blackColor];
    self.wantsFullScreenLayout = YES;
    
    //set up camera stuff
    self.stillCamera = [[GPUImageStillCamera alloc] init];//perhaps init this sooner so loading is faster
    GPUImageSepiaFilter *sepia = [GPUImageSepiaFilter new];
//    GPUImageGammaFilter *filter = [[GPUImageGammaFilter alloc] init];
    GPUImageView *targetView = [[GPUImageView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x + kCameraViewportPadding.left,
                                                                              self.view.bounds.origin.y + kCameraViewportPadding.top,
                                                                              self.view.bounds.size.width - (kCameraViewportPadding.left + kCameraViewportPadding.right),
                                                                              self.view.bounds.size.height - (kCameraViewportPadding.top + kCameraViewportPadding.bottom))];
    targetView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    targetView.autoresizesSubviews = YES;
    
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    targetView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;

    [self.stillCamera addTarget:sepia];
    [sepia addTarget:targetView];
//    [self.stillCamera addTarget:filter];
//    [filter addTarget:targetView];
    [self.view addSubview:targetView];
    
    /* Controls */
    
    //bar container
    self.barContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                     self.view.bounds.size.height - kBottomBarHeight - kBottomBarBottomOffset,
                                                                     self.view.bounds.size.width,
                                                                     kBottomBarHeight)];
    self.barContainerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.barContainerView];
    
    //bar background
    self.barBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,
                                                                                0,
                                                                                self.barContainerView.bounds.size.width,
                                                                                self.barContainerView.bounds.size.height)];
    self.barBackgroundImageView.image = [[UIImage imageNamed:@"photo-snapper-bar-bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    self.barBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.barContainerView addSubview:self.barBackgroundImageView];

    //cancel button
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *cancelImage = [UIImage imageNamed:@"snapper-icon-cancel"];
    CGSize cancelButtonSize = CGSizeMake(cancelImage.size.width + kBarButtonsFanoutRadius * 2,
                                   cancelImage.size.height + kBarButtonsFanoutRadius * 2);
    self.cancelButton.frame = CGRectMake(kCancelButtonLeftCenterMargin - cancelButtonSize.width / 2,
                                         (self.barContainerView.bounds.size.height - cancelButtonSize.height) / 2 + kBarButtonsBottomCenterOffset,
                                         cancelButtonSize.width,
                                         cancelButtonSize.height);
    [self.cancelButton setImage:cancelImage forState:UIControlStateNormal];
    self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.barContainerView addSubview:self.cancelButton];

    //camera roll button
    self.cameraRollButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cameraRollButton addTarget:self action:@selector(cameraRollAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *cameraRollImage = [UIImage imageNamed:@"snapper-icon-pics"];
    CGSize cameraRollButtonSize = CGSizeMake(cameraRollImage.size.width + kBarButtonsFanoutRadius * 2,
                                             cameraRollImage.size.height + kBarButtonsFanoutRadius * 2);
    self.cameraRollButton.frame = CGRectMake(self.barContainerView.bounds.size.width - (kCameraRollButtonRightCenterMargin + cameraRollButtonSize.width / 2),
                                             (self.barContainerView.bounds.size.height - cameraRollButtonSize.height) / 2 + kBarButtonsBottomCenterOffset,
                                             cameraRollButtonSize.width,
                                             cameraRollButtonSize.height);
    [self.cameraRollButton setImage:cameraRollImage forState:UIControlStateNormal];
    self.cameraRollButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.barContainerView addSubview:self.cameraRollButton];

    //main button
    self.mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.mainButton addTarget:self action:@selector(mainAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *mainButtonMainImage = [UIImage imageNamed:@"snap-button"];
    CGSize mainButtonSize = CGSizeMake(mainButtonMainImage.size.width + kMainButtonFanoutRadius * 2,
                                       mainButtonMainImage.size.height + kMainButtonFanoutRadius * 2);
    self.mainButton.frame = CGRectMake((self.barContainerView.bounds.size.width - mainButtonSize.width) / 2,
                                       (self.barContainerView.bounds.size.height - mainButtonSize.height) / 2 + kMainButtonBottomCenterOffset,
                                       mainButtonSize.width,
                                       mainButtonSize.height);
    [self.mainButton setBackgroundImage:mainButtonMainImage forState:UIControlStateNormal];
    self.mainButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.barContainerView addSubview:self.mainButton];
 
    //retake button
    self.retakeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.retakeButton addTarget:self action:@selector(retakeAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *retakeImage = [UIImage imageNamed:@"snapper-icon-retake"];
    CGSize retakeButtonSize = CGSizeMake(retakeImage.size.width + kBarButtonsFanoutRadius * 2,
                                         retakeImage.size.height + kBarButtonsFanoutRadius * 2);
    self.retakeButton.frame = CGRectMake(self.barContainerView.bounds.size.width - (kRetakeButtonRightCenterMargin + retakeButtonSize.width / 2),
                                         (self.barContainerView.bounds.size.height - retakeButtonSize.height) / 2 + kBarButtonsBottomCenterOffset,
                                         retakeButtonSize.width,
                                         retakeButtonSize.height);
    [self.retakeButton setImage:retakeImage forState:UIControlStateNormal];
    self.retakeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.barContainerView addSubview:self.retakeButton];
    
    //filter container
    self.filtersContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                        self.view.bounds.size.height - kFilterTrayHeight - kFilterTrayBottomOffsetOpen,
                                                                        self.view.bounds.size.width,
                                                                        kFilterTrayHeight)];
    self.filtersContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view insertSubview:self.filtersContainerView belowSubview:self.barContainerView];
    
    //filter background
    self.filtersBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,
                                                                                0,
                                                                                self.filtersContainerView.bounds.size.width,
                                                                                self.filtersContainerView.bounds.size.height)];
    self.filtersBackgroundImageView.image = [[UIImage imageNamed:@"mesh-tray"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    self.filtersBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.filtersContainerView addSubview:self.filtersBackgroundImageView];
    
    //filter scrollview
    self.filtersScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(kFiltersScrollViewMargin.left,
                                                                            kFiltersScrollViewMargin.top,
                                                                            self.filtersContainerView.bounds.size.width - (kFiltersScrollViewMargin.left + kFiltersScrollViewMargin.right),
                                                                            self.filtersContainerView.bounds.size.height - (kFiltersScrollViewMargin.top + kFiltersScrollViewMargin.bottom))];
    self.filtersScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.filtersScrollView.contentInset = kFiltersScrollViewContentInset;
    [self.filtersContainerView addSubview:self.filtersScrollView];
    
    //handles opacities, positions, etc
    [self _transitionToState:GBFancyCameraStateCapturing animated:NO];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //internal state
    self.isPresented = YES;
    
    //hide the status bar
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    //turn on the camera
    [self.stillCamera startCameraCapture];
    
    //add the shutter on top and make it ready
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //animate the shutter away
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //show the status bar, but only if it was previously shown
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    //internal state
    self.isPresented = NO;
    
    //clear this just in case
    self.completionBlock = nil;
    
    //make sure camera capture is off
    [self.stillCamera stopCameraCapture];
    
    //cleanup
    [self _cleanupHeavyStuff];
}

#pragma mark - API

-(void)takePhotoWithBlock:(GBFancyCameraCompletionBlock)block {
    //if we're not presented, present ourselves onto the main window
    if (!self.isPresented) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:self animated:YES completion:nil];
    }
    
    //remember the completion block
    self.completionBlock = block;
}

#pragma mark - util

-(void)_dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)_cameraRoll {
    //show camera roll picker
}

-(void)_retake {
    [self _transitionToState:GBFancyCameraStateCapturing animated:YES];
}

-(void)_finishedProcessingPhoto {
    [self _returnControlCancelled:NO];
}

-(void)_cancel {
    [self _returnControlCancelled:YES];
}

-(void)_capturePhoto {
    //takes photo
    
    //creates thumbnails
    
    //transitions stae
    [self _transitionToState:GBFancyCameraStateFilters animated:YES];
}

-(void)_returnControlCancelled:(BOOL)cancelled {
    //call block based method
    if (self.completionBlock) {
        BOOL shouldDismiss = kDefaultShouldAutoDismiss;
        
        if (cancelled) {
            self.completionBlock(nil, nil, NO, GBFancyCameraSourceNone, &shouldDismiss);
        }
        else {
            self.completionBlock(nil, nil, YES, 0, &shouldDismiss);//foo should get original, filtered and source somehow
        }
        self.completionBlock = nil;
        
        //dismiss if we need to
        if (shouldDismiss) {
            [self _dismiss];
        }
    }
    
    //call delegate methods
    if (self.delegate) {
        if (cancelled) {
            [self.delegate fancyCameraDidCancelTakingPhoto:self];
        }
        else {
            [self.delegate fancyCamera:self didTakePhotoWithOriginalImage:nil processedImage:nil fromSource:0];//foo should get original, filtered and source somehow
        }
    }
}

-(void)_transitionToState:(GBFancyCameraState)state animated:(BOOL)animated {
    if (_state != state) {
        //do the animation to move around buttons and stuff
        
        
        //remember state
        _state = state;
    }
}

-(void)_cleanupHeavyStuff {
    //ditch all hight memory stuff
    self.originalImage = nil;
    self.processedImage = nil;
    
    for (UIView *thumb in self.thumbnailViews) {
        [thumb removeFromSuperview];
    }
    self.thumbnailViews = nil;
}

#pragma mark - Actions

-(void)cancelAction:(id)sender {
    [self _cancel];
}

-(void)retakeAction:(id)sender {
    [self _retake];
}

-(void)mainAction:(id)sender {
    if (self.state == GBFancyCameraStateCapturing) {
        [self _capturePhoto];
    }
    else {
        [self _finishedProcessingPhoto];
    }
}

-(void)cameraRollAction:(id)sender {
    [self _cameraRoll];
}

@end

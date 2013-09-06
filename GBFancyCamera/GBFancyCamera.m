//
//  GBFancyCamera.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 29/08/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBFancyCamera.h"

#import "GPUImage.h"

static CGFloat const kCameraAspectRatio =                           4./3.;

static CGFloat const kBottomBarHeight =                             53;
static CGFloat const kBottomBarBottomMargin =                       0;
static CGFloat const kBarButtonsCenterOffset =                      2;
static CGFloat const kMainButtonCenterOffset =                      0;
static CGFloat const kMainButtonAcceptModeRightCenterMargin =       23;
static CGFloat const kRetakeButtonRightCenterMargin =               73;
static CGFloat const kCancelButtonLeftCenterMargin =                24;
static CGFloat const kCameraRollButtonRightCenterMargin =           24;

static CGFloat const kBarButtonsFanoutRadius =                      6;//defines how much bigger the button is than its image
static CGFloat const kMainButtonFanoutRadius =                      0;//defines how much bigger the button is than its image

static CGFloat const kFilterTrayHeight =                            89;
static CGFloat const kFilterTrayBottomMarginOpen =                  49;
static CGFloat const kFilterTrayBottomMarginClosed =                kBottomBarHeight + kBottomBarBottomMargin - kFilterTrayHeight - 0;

static UIEdgeInsets const kCameraViewportPadding =                  (UIEdgeInsets){0, 0, 40, 0};

static UIEdgeInsets const kFiltersScrollViewMargin =                (UIEdgeInsets){6, 0, 1, 0};//so it doesn't cover stuff or go too far
static UIEdgeInsets const kFiltersScrollViewContentInset =          (UIEdgeInsets){0, 2, 0, 50};//add some right padding, maybe some left

static CGSize const kThumbnailBoxSize =                             (CGSize){68, 74};
static UIEdgeInsets const kThumbnailBoxMargin =                     (UIEdgeInsets){4, 6, 0, 4};//collapsible

static CGFloat const kThumbnailBackgroundImageTopCenterMargin =     30;

static CGSize const kThumbnailImageSize =                           (CGSize){56, 56};
static CGFloat const kThumbnailImageTopCenterMargin =               30;
static CGFloat const kThumbnailImageCornerRadius =                  4;

static CGFloat const kFilterNameTopCenterMargin =                   68;
static CGSize const kFilterNameShadowOffset =                       (CGSize){0, 1};
static CGFloat const kFilterNameHeight =                            16;
#define kFilterNameFont                                             [UIFont fontWithName:@"ArialRoundedMTBold" size:10]
#define kFilterNameTextColorOff                                     [UIColor colorWithWhite:1 alpha:0.76]
#define kFilterNameShadowColorOff                                   [UIColor colorWithWhite:0 alpha:1]
#define kFilterNameTextColorOn                                      [UIColor colorWithWhite:1 alpha:1]
#define kFilterNameShadowColorOn                                    [UIColor colorWithWhite:0 alpha:1]

static CGFloat const kBarHeadingCenterOffset =                      2;
static CGSize const kBarHeadingShadowOffset =                       (CGSize){0, -1};
static CGFloat const kBarHeadingHorizontalPadding =                 88;
static CGFloat const kBarHeadingHeight =                            24;
#define kBarHeadingFont                                             [UIFont fontWithName:@"HelveticaNeue-Bold" size:20]
#define kBarHeadingTextColor                                        [UIColor colorWithWhite:1 alpha:1]
#define kBarHeadingShadowColor                                      [UIColor colorWithWhite:0 alpha:1]

static NSTimeInterval const kStateTransitionAnimationDuration =     0.3;

static BOOL const kDefaultShouldAutoDismiss =                       YES;
static CGFloat const kDefaultOutputImageResolution =                GBUnlimitedImageResolution;

typedef enum {
    GBFancyCameraStateCapturing,
    GBFancyCameraStateFilters
} GBFancyCameraState;

@protocol GBFilterViewDelegate;

@interface GBFilterView : UIView

@property (weak, nonatomic) id<GBFilterViewDelegate>                delegate;
@property (strong, nonatomic) UIImage                               *image;
@property (copy, nonatomic) NSString                                *title;
@property (assign, nonatomic) BOOL                                  isSelected;

@property (strong, nonatomic) UIImage                               *backgroundImageWhenSelected;
@property (strong, nonatomic) UIImage                               *backgroundImageWhenDeselected;

@property (strong, nonatomic) UIImageView                           *backgroundImageView;
@property (strong, nonatomic) UIImageView                           *imageView;
@property (strong, nonatomic) UILabel                               *titleLabel;

@property (strong, nonatomic) UITapGestureRecognizer                *tapGestureRecognizer;

@end

@protocol GBFilterViewDelegate <NSObject>
@required

-(void)didSelectFilterView:(GBFilterView *)filterView;

@end

@implementation GBFilterView

#pragma mark - CA

-(void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

-(NSString *)title {
    return self.titleLabel.text;
}

-(void)setImage:(UIImage *)image {
    self.imageView.image = image;
}

-(UIImage *)image {
    return self.imageView.image;
}

-(void)setBackgroundImageWhenSelected:(UIImage *)backgroundImageWhenSelected {
    _backgroundImageWhenSelected = backgroundImageWhenSelected;
    
    self.isSelected = self.isSelected;//causes the image to get refreshed
}

-(void)setBackgroundImageWhenDeselected:(UIImage *)backgroundImageWhenDeselected {
    _backgroundImageWhenDeselected = backgroundImageWhenDeselected;
    
    self.isSelected = self.isSelected;//causes the image to get refreshed
}

#pragma mark - life

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        //tap gesture
        self.userInteractionEnabled = YES;
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
        [self addGestureRecognizer:self.tapGestureRecognizer];
        
        //background imageview
        self.backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width / 2,
                                                                                 kThumbnailBackgroundImageTopCenterMargin,
                                                                                 0,
                                                                                 0)];
        self.backgroundImageView.userInteractionEnabled = NO;
        self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:self.backgroundImageView];
        
        //thumb
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.bounds.size.width - kThumbnailImageSize.width) / 2,
                                                                       kThumbnailImageTopCenterMargin - kThumbnailImageSize.height / 2,
                                                                       kThumbnailImageSize.width,
                                                                       kThumbnailImageSize.height)];
        self.imageView.userInteractionEnabled = NO;
        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        //foo rounded corners
        [self addSubview:self.imageView];
        
        //label
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                    kFilterNameTopCenterMargin - kFilterNameHeight / 2,
                                                                    self.bounds.size.width,
                                                                    kFilterNameHeight)];
        self.titleLabel.userInteractionEnabled = NO;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = kFilterNameFont;
        self.titleLabel.shadowOffset = kFilterNameShadowOffset;
        [self addSubview:self.titleLabel];
        
        //set images
        self.backgroundImageWhenSelected = [UIImage imageNamed:@"fancy-camera-filter-background-on"];
        self.backgroundImageWhenDeselected = [UIImage imageNamed:@"fancy-camera-filter-background-off"];
        
        //default selection
        self.isSelected = NO;
    }
    
    return self;
}

#pragma mark - UITapGestureRecognizer

-(void)didTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        self.isSelected = YES;
        [self.delegate didSelectFilterView:self];
    }
}

#pragma mark - API

-(void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    
    if (isSelected) {
        //label
        self.titleLabel.textColor = kFilterNameTextColorOn;
        self.titleLabel.shadowColor = kFilterNameShadowColorOn;

        //bg
        CGSize size = self.backgroundImageWhenSelected.size;
        self.backgroundImageView.frame = CGRectMake((self.bounds.size.width - size.width) / 2,
                                                    kThumbnailBackgroundImageTopCenterMargin - size.height / 2,
                                                    size.width,
                                                    size.height);
        self.backgroundImageView.image = self.backgroundImageWhenSelected;
    }
    else {
        //label
        self.titleLabel.textColor = kFilterNameTextColorOff;
        self.titleLabel.shadowColor = kFilterNameShadowColorOff;
        
        //bg
        CGSize size = self.backgroundImageWhenDeselected.size;
        self.backgroundImageView.frame = CGRectMake((self.bounds.size.width - size.width) / 2,
                                                    kThumbnailBackgroundImageTopCenterMargin - size.height / 2,
                                                    size.width,
                                                    size.height);
        self.backgroundImageView.image = self.backgroundImageWhenDeselected;
    }
}


@end

@interface GBFancyCamera () <GBFilterViewDelegate>

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

@property (strong, nonatomic) NSMutableArray                        *filterViews;

@property (assign, nonatomic) BOOL                                  isPresented;
@property (copy, nonatomic) GBFancyCameraCompletionBlock            completionBlock;
@property (strong, nonatomic) UIImage                               *originalImage;
@property (strong, nonatomic) UIImage                               *originalImageThumbnailSize;
@property (strong, nonatomic) UIImage                               *processedImage;
@property (strong, nonatomic) GBResizeFilter                        *resizerThumbnail;
@property (strong, nonatomic) GBResizeFilter                        *resizerMain;
@property (strong, nonatomic) GPUImageFilter                        *passthroughFilter;

@property (weak, nonatomic) GPUImageFilter                          *egressFilterThumbs;
@property (weak, nonatomic) GPUImageFilter                          *egressFilterMain;

@end

@implementation GBFancyCamera

//foo tapping a filter thumb should scroll to him
//foo needs to handle case where there is no camera (e.g. simulator)
//up would be nice to be able to handle different orientation, always, even if the app only claims to only support a single orientation
//up would be nice to be able to switch camera and turn on flash
//foo dont forget image res
//foo dont forget bundles for assets like images and translation strings

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
        self.outputImageResolution = kDefaultOutputImageResolution;
    }
    
    return self;
}

#pragma mark - CA

-(GBResizeFilter *)resizerThumbnail {
    if (!_resizerThumbnail) {
        _resizerThumbnail = [[GBResizeFilter alloc] initWithOutputSize:kThumbnailImageSize];
    }
    
    return _resizerThumbnail;
}

-(GBResizeFilter *)resizerMain {
    if (!_resizerMain) {
        _resizerMain = [[GBResizeFilter alloc] initWithOutputResolution:self.outputImageResolution aspectRatio:kCameraAspectRatio];
    }
    
    return _resizerMain;
}

-(void)setState:(GBFancyCameraState)state {
    [self _transitionUIToState:state animated:NO];
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
    self.stillCamera = [[GPUImageStillCamera alloc] init];
    self.passthroughFilter = [GPUImageFilter new];
    GPUImageView *previewView = [[GPUImageView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x + kCameraViewportPadding.left,
                                                                              self.view.bounds.origin.y + kCameraViewportPadding.top,
                                                                              self.view.bounds.size.width - (kCameraViewportPadding.left + kCameraViewportPadding.right),
                                                                              self.view.bounds.size.height - (kCameraViewportPadding.top + kCameraViewportPadding.bottom))];
    previewView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    previewView.autoresizesSubviews = YES;
    
    previewView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

    [self.stillCamera addTarget:self.passthroughFilter];
    [self.passthroughFilter addTarget:self.resizerMain];
    [self.resizerMain addTarget:previewView];
    
    [self.passthroughFilter addTarget:self.resizerThumbnail];
    
    //filters then get plugged into these ones
    self.egressFilterMain = self.resizerMain;
    self.egressFilterThumbs = self.resizerThumbnail;
    
    [self.view addSubview:previewView];
    
    /* Controls */
    
    //bar container
    self.barContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                     self.view.bounds.size.height - kBottomBarHeight - kBottomBarBottomMargin,
                                                                     self.view.bounds.size.width,
                                                                     kBottomBarHeight)];
    self.barContainerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.barContainerView];
    
    //bar background
    self.barBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,
                                                                                0,
                                                                                self.barContainerView.bounds.size.width,
                                                                                self.barContainerView.bounds.size.height)];
    self.barBackgroundImageView.image = [[UIImage imageNamed:@"fancy-camera-bar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    self.barBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.barContainerView addSubview:self.barBackgroundImageView];

    //cancel button
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *cancelImage = [UIImage imageNamed:@"fancy-camera-bar-button-icon-cancel"];
    CGSize cancelButtonSize = CGSizeMake(cancelImage.size.width + kBarButtonsFanoutRadius * 2,
                                   cancelImage.size.height + kBarButtonsFanoutRadius * 2);
    self.cancelButton.frame = CGRectMake(kCancelButtonLeftCenterMargin - cancelButtonSize.width / 2,
                                         (self.barContainerView.bounds.size.height - cancelButtonSize.height) / 2 + kBarButtonsCenterOffset,
                                         cancelButtonSize.width,
                                         cancelButtonSize.height);
    [self.cancelButton setImage:cancelImage forState:UIControlStateNormal];
    self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.barContainerView addSubview:self.cancelButton];

    //camera roll button
    self.cameraRollButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cameraRollButton addTarget:self action:@selector(cameraRollAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *cameraRollImage = [UIImage imageNamed:@"fancy-camera-bar-button-icon-camera-roll"];
    CGSize cameraRollButtonSize = CGSizeMake(cameraRollImage.size.width + kBarButtonsFanoutRadius * 2,
                                             cameraRollImage.size.height + kBarButtonsFanoutRadius * 2);
    self.cameraRollButton.frame = CGRectMake(self.barContainerView.bounds.size.width - (kCameraRollButtonRightCenterMargin + cameraRollButtonSize.width / 2),
                                             (self.barContainerView.bounds.size.height - cameraRollButtonSize.height) / 2 + kBarButtonsCenterOffset,
                                             cameraRollButtonSize.width,
                                             cameraRollButtonSize.height);
    [self.cameraRollButton setImage:cameraRollImage forState:UIControlStateNormal];
    self.cameraRollButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.barContainerView addSubview:self.cameraRollButton];

    //main button
    self.mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.mainButton addTarget:self action:@selector(mainAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *mainButtonMainImage = [UIImage imageNamed:@"fancy-camera-snap-button"];
    CGSize mainButtonSize = CGSizeMake(mainButtonMainImage.size.width + kMainButtonFanoutRadius * 2,
                                       mainButtonMainImage.size.height + kMainButtonFanoutRadius * 2);
    self.mainButton.frame = CGRectMake((self.barContainerView.bounds.size.width - mainButtonSize.width) / 2,
                                       (self.barContainerView.bounds.size.height - mainButtonSize.height) / 2 + kMainButtonCenterOffset,
                                       mainButtonSize.width,
                                       mainButtonSize.height);
    [self.mainButton setBackgroundImage:mainButtonMainImage forState:UIControlStateNormal];
    self.mainButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.mainButton.adjustsImageWhenDisabled = NO;
    [self.barContainerView addSubview:self.mainButton];
 
    //retake button
    self.retakeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.retakeButton addTarget:self action:@selector(retakeAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *retakeImage = [UIImage imageNamed:@"fancy-camera-bar-button-icon-retake"];
    CGSize retakeButtonSize = CGSizeMake(retakeImage.size.width + kBarButtonsFanoutRadius * 2,
                                         retakeImage.size.height + kBarButtonsFanoutRadius * 2);
    self.retakeButton.frame = CGRectMake(self.barContainerView.bounds.size.width - (kRetakeButtonRightCenterMargin + retakeButtonSize.width / 2),
                                         (self.barContainerView.bounds.size.height - retakeButtonSize.height) / 2 + kBarButtonsCenterOffset,
                                         retakeButtonSize.width,
                                         retakeButtonSize.height);
    [self.retakeButton setImage:retakeImage forState:UIControlStateNormal];
    self.retakeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.barContainerView addSubview:self.retakeButton];
    
    //filter container
    self.filtersContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                        self.view.bounds.size.height - kFilterTrayHeight - kFilterTrayBottomMarginOpen,
                                                                        self.view.bounds.size.width,
                                                                        kFilterTrayHeight)];
    self.filtersContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view insertSubview:self.filtersContainerView belowSubview:self.barContainerView];
    
    //filter background
    self.filtersBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,
                                                                                0,
                                                                                self.filtersContainerView.bounds.size.width,
                                                                                self.filtersContainerView.bounds.size.height)];
    self.filtersBackgroundImageView.image = [[UIImage imageNamed:@"fancy-camera-mesh-bar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
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
    
    //bar heading label
    self.barHeadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(kBarHeadingHorizontalPadding,
                                                                     (self.barContainerView.bounds.size.height - kBarHeadingHeight) / 2 + kBarHeadingCenterOffset,
                                                                     self.barContainerView.bounds.size.width - 2 * kBarHeadingHorizontalPadding,
                                                                     kBarHeadingHeight)];
    self.barHeadingLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.barHeadingLabel.backgroundColor = [UIColor clearColor];
    self.barHeadingLabel.font = kBarHeadingFont;
    self.barHeadingLabel.textAlignment = NSTextAlignmentCenter;
    self.barHeadingLabel.shadowOffset = kBarHeadingShadowOffset;
    self.barHeadingLabel.shadowColor = kBarHeadingShadowColor;
    self.barHeadingLabel.textColor = kBarHeadingTextColor;
    [self.barContainerView insertSubview:self.barHeadingLabel aboveSubview:self.barBackgroundImageView];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //internal state
    self.isPresented = YES;
    
    //hide the status bar
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    //turn on the camera
    [self.stillCamera startCameraCapture];
    
    //close the shutter on top and make it ready

    //maybe do some preloading here of filters etc.
    
    //prep
    [self _transitionToState:GBFancyCameraStateCapturing animated:NO forced:YES];
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
    [self.stillCamera startCameraCapture];
    [self _transitionUIToState:GBFancyCameraStateCapturing animated:YES];
}

-(void)_finishedProcessingPhoto {
    [self _returnControlCancelled:NO];
}

-(void)_cancel {
    [self _returnControlCancelled:YES];
}

-(void)_capturePhoto {
    self.mainButton.enabled = NO;
    
    //stop capture
    [self.stillCamera stopCameraCapture];
    
    //take photo
//    [self.stillCamera capturePhotoAsImageProcessedUpToFilter:self.egressFilterMain withCompletionHandler:^(UIImage *processedImage, NSError *error) {
//        self.originalImage = processedImage;
    
        //create thumbnails
        [self _createFilterViews];
        
        //transition state
        [self _transitionUIToState:GBFancyCameraStateFilters animated:YES];
        
        self.mainButton.enabled = YES;
//    }];
}

-(void)_createFilterViews {
    self.filtersScrollView.alwaysBounceHorizontal = YES;//foo
    self.filterViews = [NSMutableArray new];
    
    NSUInteger index = 0;
    for (GPUImageFilter<GBFancyCameraFilterProtocol> *filterObject in self.filters) {
        //filter the image using each of these filters in turn
        GBFilterView *filterView = [[GBFilterView alloc] initWithFrame:CGRectMake(kThumbnailBoxMargin.left + index * (kThumbnailBoxSize.width + MAX(kThumbnailBoxMargin.left, kThumbnailBoxMargin.right)),
                                                                                  kThumbnailBoxMargin.top,
                                                                                  kThumbnailBoxSize.width,
                                                                                  kThumbnailBoxSize.height)];
        filterView.delegate = self;
        filterView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        
        //filter name
        filterView.title = filterObject.localisedName;

        
        //plug in the filter to our egress point
        [self.egressFilterThumbs addTarget:filterObject];
        
        //get the image from it
        UIImage *filteredThumbImage = [self.egressFilterThumbs imageFromCurrentlyProcessedOutput];
        filterView.image = filteredThumbImage;
        
        //disconnect our filterobject
        [self.egressFilterThumbs removeTarget:filterObject];
        
        //add it to he scrollview
        [self.filtersScrollView addSubview:filterView];
        
        //stretch the scrollview
        self.filtersScrollView.contentSize = CGSizeMake(filterView.frame.origin.x + filterView.frame.size.width + kThumbnailBoxMargin.right,
                                                        self.filtersScrollView.bounds.size.height);
        
        //add it to our filterViews
        [self.filterViews addObject:filterView];
        
        index += 1;
    }
    
    //select the first one initially
    if (self.filters.count >= 1) {
        GBFilterView *firstFilter = self.filterViews[0];
        firstFilter.isSelected = YES;
    }
}

-(void)_destroyFilterViews {
    for (GBFilterView *aFilterView in self.filterViews) {
        [aFilterView removeFromSuperview];
    }
    self.filterViews = nil;
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

-(void)_transitionUIToState:(GBFancyCameraState)state animated:(BOOL)animated {
    [self _transitionToState:state animated:animated forced:NO];
}

-(void)_transitionToState:(GBFancyCameraState)state animated:(BOOL)animated forced:(BOOL)forced {
    if (_state != state || forced) {
        //do the animation to move around buttons and stuff
        NSTimeInterval duration = animated ? kStateTransitionAnimationDuration : 0;
        switch (state) {
            case GBFancyCameraStateCapturing: {
                [UIView animateWithDuration:duration delay:0 options:0 animations:^{
                    //main button
                    [self.mainButton setImage:[UIImage imageNamed:@"fancy-camera-snap-button-icon-camera"] forState:UIControlStateNormal];
                    self.mainButton.frame = CGRectMake((self.barContainerView.bounds.size.width - self.mainButton.frame.size.width) / 2,
                                                       (self.barContainerView.bounds.size.height - self.mainButton.frame.size.height) / 2 + kMainButtonCenterOffset,
                                                       self.mainButton.frame.size.width,
                                                       self.mainButton.frame.size.height);
                    
                    //retake button
                    self.retakeButton.alpha = 0;
                    
                    //camera roll button
                    self.cameraRollButton.alpha = 1;
                    
                    //filters
                    self.filtersContainerView.frame = CGRectMake(0,
                                                                 self.view.bounds.size.height - kFilterTrayHeight - kFilterTrayBottomMarginClosed,
                                                                 self.filtersContainerView.frame.size.width,
                                                                 self.filtersContainerView.frame.size.height);
                    //heading
                    self.barHeadingLabel.alpha = 0;
                } completion:nil];
            } break;
                
            case GBFancyCameraStateFilters: {
                [UIView animateWithDuration:duration delay:0 options:0 animations:^{
                    //main button
                    [self.mainButton setImage:[UIImage imageNamed:@"fancy-camera-snap-button-icon-tick"] forState:UIControlStateNormal];
                    self.mainButton.frame = CGRectMake(self.barContainerView.bounds.size.width - (kMainButtonAcceptModeRightCenterMargin + self.mainButton.frame.size.width / 2),
                                                       (self.barContainerView.bounds.size.height - self.mainButton.frame.size.height) / 2 + kMainButtonCenterOffset,
                                                       self.mainButton.frame.size.width,
                                                       self.mainButton.frame.size.height);
                    
                    //retake button
                    self.retakeButton.alpha = 1;
                    
                    //camera roll button
                    self.cameraRollButton.alpha = 0;
                    
                    //filters
                    self.filtersContainerView.frame = CGRectMake(0,
                                                                 self.view.bounds.size.height - kFilterTrayHeight - kFilterTrayBottomMarginOpen,
                                                                 self.filtersContainerView.frame.size.width,
                                                                 self.filtersContainerView.frame.size.height);
                    
                    //heading
                    self.barHeadingLabel.text = NSLocalizedString(@"Filters", @"filters state heading");
                    self.barHeadingLabel.alpha = 1;
                } completion:nil];
            } break;
        }
        
        //remember state
        _state = state;
    }
}

-(void)_cleanupHeavyStuff {
    //ditch all hight memory stuff
    self.originalImage = nil;
    self.processedImage = nil;

    [self _destroyFilterViews];
}

#pragma mark - GBFilterViewDelegate

-(void)didSelectFilterView:(GBFilterView *)filterView {
    //deselect all the other ones
    for (GBFilterView *anotherFilterView in self.filterViews) {
        if (anotherFilterView != filterView) {
            anotherFilterView.isSelected = NO;
        }
    }
    
    //change the currently displayed image to something else
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

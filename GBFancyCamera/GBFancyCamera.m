//
//  GBFancyCamera.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 29/08/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBFancyCamera.h"

//image library import
#import "GPUImage.h"

//system library imports
#import <QuartzCore/QuartzCore.h>

//image manipulation imports
#import "UIImage+GBFancyCamera.h"

//media picker imports
#import <MobileCoreServices/MobileCoreServices.h>

//view imports
#import "TapToFocusView.h"

//for identifying device
#import <sys/utsname.h>

static CGFloat const kCameraAspectRatio3G =                         4./3.;
static CGFloat const kCameraAspectRatio4Plus =                      16./9.;

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

static UIEdgeInsets const kCameraViewportPadding =                  (UIEdgeInsets){0, 0, 48, 0};

static UIEdgeInsets const kFiltersScrollViewMargin =                (UIEdgeInsets){6, 0, 1, 0};//so it doesn't cover stuff or go too far
static UIEdgeInsets const kFiltersScrollViewContentInset =          (UIEdgeInsets){0, 2, 0, 36};//add some right padding, maybe some left

static CGSize const kThumbnailBoxSize =                             (CGSize){68, 74};
static UIEdgeInsets const kThumbnailBoxMargin =                     (UIEdgeInsets){6, 2, 0, 2};//collapsible

static CGFloat const kThumbnailBackgroundImageTopCenterMargin =     30;

static CGSize const kThumbnailImageSize =                           (CGSize){56, 56};
static CGFloat const kThumbnailImageTopCenterMargin =               30;
static CGFloat const kThumbnailImageCornerRadius =                  3;

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

#define kNoCameraLabelTextColor                                     [UIColor whiteColor];
#define kNoCameraLabelFont                                          [UIFont fontWithName:@"HelveticaNeue-Bold" size:14]
static CGFloat const kNoCameraLabelHeight =                         80;
static CGFloat const kNoCameraLabelHorizontalMargin =               20;


static NSTimeInterval const kStateTransitionAnimationDuration =     0.3;

static BOOL const kDefaultShouldAutoDismiss =                       YES;
static CGFloat const kDefaultMaxOutputImageResolution =             GBUnlimitedImageResolution;
static BOOL const kDefaultIsCameraRollEnabled =                     YES;
static CGRect const kDefaultCropRegion =                            (CGRect){0,0,1.,1.};
static GBMotionDeviceOrientation const kDefaultForcedOrientation =  GBMotionDeviceOrientationUnknown;
static BOOL const kDefaultIsTapToFocusEnabled =                     YES;

typedef enum {
    GBFancyCameraStateCapturing,
    GBFancyCameraStateFilters
} GBFancyCameraState;

@protocol GBFilterViewDelegate;

@interface GBFilterView : UIView

@property (weak, nonatomic) id<GBFilterViewDelegate>                                            delegate;
@property (strong, nonatomic) UIImage                                                           *image;
@property (copy, nonatomic) NSString                                                            *title;
@property (assign, nonatomic) BOOL                                                              isSelected;
@property (strong, nonatomic) Class                                                             filterClass;

@property (strong, nonatomic) UIImage                                                           *backgroundImageWhenSelected;
@property (strong, nonatomic) UIImage                                                           *backgroundImageWhenDeselected;

@property (strong, nonatomic) UIImageView                                                       *backgroundImageView;
@property (strong, nonatomic) UIImageView                                                       *imageView;
@property (strong, nonatomic) UILabel                                                           *titleLabel;

@property (strong, nonatomic) UITapGestureRecognizer                                            *tapGestureRecognizer;

@end

@protocol GBFilterViewDelegate <NSObject>
@required

-(void)didSelectFilterView:(GBFilterView *)filterView;

@end

@interface GBFancyCamera () <GBFilterViewDelegate>

@property (assign, nonatomic) GBFancyCameraState                                                state;

@property (strong, nonatomic) GPUImageStillCamera                                               *stillCamera;

@property (strong, nonatomic) UIView                                                            *barContainerView;
@property (strong, nonatomic) UIImageView                                                       *barBackgroundImageView;

@property (strong, nonatomic) UIButton                                                          *mainButton;
@property (strong, nonatomic) UIButton                                                          *cancelButton;
@property (strong, nonatomic) UIButton                                                          *cameraRollButton;
@property (strong, nonatomic) UIButton                                                          *retakeButton;

@property (strong, nonatomic) UIView                                                            *filtersContainerView;
@property (strong, nonatomic) UIImageView                                                       *filtersBackgroundImageView;
@property (strong, nonatomic) UIScrollView                                                      *filtersScrollView;

@property (strong, nonatomic) UILabel                                                           *barHeadingLabel;

@property (strong, nonatomic) UILabel                                                           *noCameraLabel;

@property (strong, nonatomic) NSMutableArray                                                    *filterViews;

@property (assign, nonatomic) BOOL                                                              isPresented;

@property (assign, nonatomic) BOOL                                                              wasCapturingBeforeResignActive;

@property (copy, nonatomic) GBFancyCameraCompletionBlock                                        completionBlock;

@property (strong, nonatomic) UIImage                                                           *originalImage;
@property (strong, nonatomic) UIImage                                                           *processedImage;
@property (assign, nonatomic) GBFancyCameraSource                                               imageSource;

@property (strong, nonatomic) GPUImageCropFilter                                                *cropFilter;
@property (strong, nonatomic) GBResizeFilter                                                    *resizerMain;
@property (strong, nonatomic) GPUImageFilter                                                    *passthroughFilter;
@property (strong, nonatomic) GPUImageView                                                      *livePreviewView;
@property (strong, nonatomic) GPUImageOutput<GPUImageInput, GBFancyCameraFilterProtocol>        *currentFilter;
@property (weak, nonatomic) GPUImageFilter                                                      *liveEgressMain;
@property (strong, nonatomic) GPUImagePicture                                                   *imagePic;

@property (strong, nonatomic) GBMotionGestureHandler                                            orientationHandler;
@property (assign, nonatomic) GBMotionDeviceOrientation                                         deviceOrientation;

@property (strong, nonatomic) UITapGestureRecognizer                                            *tapGestureRecognizer;

@property (strong, nonatomic) TapToFocusView                                                    *tapToFocusView;

@end

@interface GBFilterView ()

@end

@interface GBFancyCamera () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

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
        self.imageView.layer.cornerRadius = kThumbnailImageCornerRadius;
        self.imageView.layer.masksToBounds = YES;
        [self addSubview:self.imageView];
        
        //title label
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
        self.backgroundImageWhenSelected = [UIImage imageNamed:BundledResource(@"fancy-camera-filter-background-on")];
        self.backgroundImageWhenDeselected = [UIImage imageNamed:BundledResource(@"fancy-camera-filter-background-off")];
        
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

@implementation GBFancyCamera

#pragma mark - CA

-(GBMotionGestureHandler)orientationHandler {
    if (!_orientationHandler) {
        __weak GBFancyCamera *weakSelf = self;
        _orientationHandler = ^(GBMotionGesture gesture, NSDictionary *info) {
            if (gesture == GBMotionGestureChangedDeviceOrientation) {
                if (weakSelf.forcedOrientation == GBMotionDeviceOrientationUnknown) {
                    weakSelf.deviceOrientation = (GBMotionDeviceOrientation)[info[kGBMotionDeviceOrientationKey] intValue];
                    if (weakSelf.state == GBFancyCameraStateCapturing) {
                        [UIView animateWithDuration:0.1 animations:^{
                            weakSelf.mainButton.transform = CGAffineTransformMakeRotation([weakSelf _rotationAngleForCurrentDeviceOrientation]);
                        }];
                    }
                }
            }
        };
    }
    
    return _orientationHandler;
}

-(void)setViewfinderOverlay:(UIView *)viewfinderOverlay {
    if (_viewfinderOverlay != viewfinderOverlay) {
        //remove the old one
        [_viewfinderOverlay removeFromSuperview];
        
        //configure the new one
        viewfinderOverlay.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        viewfinderOverlay.userInteractionEnabled = NO;
        
        //set the ivar
        _viewfinderOverlay = viewfinderOverlay;
        
        if (self.isViewLoaded) {
            [self _handleViewfinderOverlay];
        }
    }
}

-(void)setIsCameraRollEnabled:(BOOL)isCameraRollEnabled {
    _isCameraRollEnabled = isCameraRollEnabled;
    
    self.cameraRollButton.hidden = !isCameraRollEnabled;
}

-(void)setFilters:(NSArray *)filters {
    NSMutableArray *myFilters = [NSMutableArray new];
    
    //add in all the rest
    for (Class filterClass in filters) {
        if ([filterClass conformsToProtocol:@protocol(GBFancyCameraFilterProtocol)] &&
            [filterClass conformsToProtocol:@protocol(GPUImageInput)] &&
            [filterClass isSubclassOfClass:GPUImageOutput.class]) {
            [myFilters addObject:filterClass];
        }
        else {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Filter must conform to GBFancyCameraFilterProtocol and be a subclass of either GPUImageFilter or GPUImageFilterGroup" userInfo:nil];
        }
    }
    
    _filters = myFilters;
}

-(GBResizeFilter *)resizerMain {
    if (!_resizerMain) {
        _resizerMain = [[GBResizeFilter alloc] initWithOutputResolution:[self _maxOutputImageResolutionBeforeCropping] aspectRatio:[self.class cameraAspectRatio]];
    }
    
    return _resizerMain;
}

-(void)setState:(GBFancyCameraState)state {
    [self _transitionUIToState:state animated:NO];
}

-(void)setCropRegion:(CGRect)cropRegion {
    _cropRegion = cropRegion;
    
    self.cropFilter.cropRegion = cropRegion;
}

#pragma mark - Memory

static NSBundle *_resourcesBundle;
+(void)initialize {
    NSString *resourceBundlePath = [[NSBundle mainBundle] pathForResource:@"GBFancyCameraResources2" ofType:@"bundle"];
    _resourcesBundle = [NSBundle bundleWithPath:resourceBundlePath];
}

+(NSBundle *)resourcesBundle {
    return _resourcesBundle;
}

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
        //defaults
        self.maxOutputImageResolution = kDefaultMaxOutputImageResolution;
        self.isCameraRollEnabled = kDefaultIsCameraRollEnabled;
        self.cropRegion = kDefaultCropRegion;
        self.forcedOrientation = kDefaultForcedOrientation;
        self.isTapToFocusEnabled = kDefaultIsTapToFocusEnabled;
    }
    
    return self;
}

#pragma mark - Life

-(void)viewDidLoad {
    [super viewDidLoad];
    
    //clipping must be on because live preview view can sometimes spill
    self.view.clipsToBounds = YES;
    
    //full screen stuff
    self.view.backgroundColor = [UIColor blackColor];
    self.wantsFullScreenLayout = YES;
    
    //set up camera stuff
    self.stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
    self.cropFilter = [GPUImageCropFilter new];
    self.cropFilter.cropRegion = self.cropRegion;
    self.passthroughFilter = [GPUImageFilter new];
    CGRect viewPortFrame = CGRectMake(self.view.bounds.origin.x + kCameraViewportPadding.left,
                                      self.view.bounds.origin.y + kCameraViewportPadding.top,
                                      self.view.bounds.size.width - (kCameraViewportPadding.left + kCameraViewportPadding.right),
                                      self.view.bounds.size.height - (kCameraViewportPadding.top + kCameraViewportPadding.bottom));
    self.livePreviewView = [[GPUImageView alloc] initWithFrame:viewPortFrame];
    self.livePreviewView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    self.livePreviewView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    [self.stillCamera addTarget:self.passthroughFilter];
    [self.passthroughFilter addTarget:self.resizerMain];
    
    [self.stillCamera startCameraCapture];
    
    //filters then get plugged into this one
    self.liveEgressMain = self.resizerMain;
    
    //add the livePreviewView
    [self.view addSubview:self.livePreviewView];
    
    //tap to focus view
    self.tapToFocusView = [TapToFocusView new];
    [self.view insertSubview:self.tapToFocusView aboveSubview:self.livePreviewView];
    
    /* Controls */
    
    //tap gesture recognizer
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_didTapToFocus:)];
    [self.livePreviewView addGestureRecognizer:self.tapGestureRecognizer];
    
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
    self.barBackgroundImageView.image = [[UIImage imageNamed:BundledResource(@"fancy-camera-bar")] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    self.barBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.barContainerView addSubview:self.barBackgroundImageView];
    
    //cancel button
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *cancelImage = [UIImage imageNamed:BundledResource(@"fancy-camera-bar-button-icon-cancel")];
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
    UIImage *cameraRollImage = [UIImage imageNamed:BundledResource(@"fancy-camera-bar-button-icon-camera-roll")];
    CGSize cameraRollButtonSize = CGSizeMake(cameraRollImage.size.width + kBarButtonsFanoutRadius * 2,
                                             cameraRollImage.size.height + kBarButtonsFanoutRadius * 2);
    self.cameraRollButton.frame = CGRectMake(self.barContainerView.bounds.size.width - (kCameraRollButtonRightCenterMargin + cameraRollButtonSize.width / 2),
                                             (self.barContainerView.bounds.size.height - cameraRollButtonSize.height) / 2 + kBarButtonsCenterOffset,
                                             cameraRollButtonSize.width,
                                             cameraRollButtonSize.height);
    [self.cameraRollButton setImage:cameraRollImage forState:UIControlStateNormal];
    self.cameraRollButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.barContainerView addSubview:self.cameraRollButton];
    self.isCameraRollEnabled = self.isCameraRollEnabled;//this triggers the side effects
    
    //main button
    self.mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.mainButton addTarget:self action:@selector(mainAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *mainButtonMainImage = [UIImage imageNamed:BundledResource(@"fancy-camera-snap-button")];
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
    UIImage *retakeImage = [UIImage imageNamed:BundledResource(@"fancy-camera-bar-button-icon-retake")];
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
    self.filtersBackgroundImageView.image = [[UIImage imageNamed:BundledResource(@"fancy-camera-mesh-bar")] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    self.filtersBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.filtersContainerView addSubview:self.filtersBackgroundImageView];
    
    //filter scrollview
    self.filtersScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(kFiltersScrollViewMargin.left,
                                                                            kFiltersScrollViewMargin.top,
                                                                            self.filtersContainerView.bounds.size.width - (kFiltersScrollViewMargin.left + kFiltersScrollViewMargin.right),
                                                                            self.filtersContainerView.bounds.size.height - (kFiltersScrollViewMargin.top + kFiltersScrollViewMargin.bottom))];
    self.filtersScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.filtersScrollView.contentInset = kFiltersScrollViewContentInset;
    self.filtersScrollView.showsHorizontalScrollIndicator = NO;
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
    
    //no camera label
    self.noCameraLabel = [[UILabel alloc] initWithFrame:CGRectMake(kNoCameraLabelHorizontalMargin,
                                                                   (self.view.bounds.size.height - kBottomBarHeight - kNoCameraLabelHeight) / 2,
                                                                   self.view.bounds.size.width - 2*kNoCameraLabelHorizontalMargin,
                                                                   kNoCameraLabelHeight)];
    self.noCameraLabel.backgroundColor = [UIColor clearColor];
    self.noCameraLabel.textAlignment = NSTextAlignmentCenter;
    self.noCameraLabel.numberOfLines = 8;
    self.noCameraLabel.font = kNoCameraLabelFont;
    self.noCameraLabel.textColor = kNoCameraLabelTextColor;
    [self.view addSubview:self.noCameraLabel];
    
    //capture pausing when going to background
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:NULL];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //orientation based on GBMotion
    if (self.forcedOrientation == GBMotionDeviceOrientationUnknown) {
        self.deviceOrientation = [GBMotion sharedMotion].deviceOrientation;
    }
    //orientation forcing
    else {
        self.deviceOrientation = self.forcedOrientation;
    }
    
    [[GBMotion sharedMotion] addHandler:self.orientationHandler];
    
    if (!self.presentedViewController) {
        //internal state
        self.isPresented = YES;
        
        //hide the status bar
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        
        //connect the main thing
        [self.liveEgressMain addTarget:self.livePreviewView];
        
        //turn on the camera
        self.livePreviewView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        [self.stillCamera resumeCameraCapture];
        [self _setFocusAndExposureAtPoint:CGPointMake(0.5, 0.5)];
        
        //prep
        [self _transitionToState:GBFancyCameraStateCapturing animated:NO forced:YES];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //animate the shutter away
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[GBMotion sharedMotion] removeHandler:self.orientationHandler];
    
    if (!self.presentedViewController) {
        //show the status bar, but only if it was previously shown
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (!self.presentedViewController) {
        //internal state
        self.isPresented = NO;
        
        //clear this just in case
        self.completionBlock = nil;
        
        //make sure camera capture is off
        [self.stillCamera pauseCameraCapture];
    }
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.stillCamera stopCameraCapture];
    [self _cleanupHeavyStuff];
}

#pragma mark - API

+(CGFloat)cameraAspectRatio {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    if ([machineName isEqualToString:@"iPhone1,2"] || [machineName isEqualToString:@"iPhone2,1"]) {
        return kCameraAspectRatio3G;
    }
    else {
        return kCameraAspectRatio4Plus;
    }
}

-(void)takePhotoWithBlock:(GBFancyCameraCompletionBlock)block {
    //if we're not presented, present ourselves onto the main window
    if (!self.isPresented) {
        [TopmostViewController() presentViewController:self animated:YES completion:nil];
    }
    
    //remember the completion block
    self.completionBlock = block;
}

#pragma mark - utils

static UIViewController * TopmostViewController() {
    return TopmostViewControllerWithRootViewController([UIApplication sharedApplication].keyWindow.rootViewController);
}

static UIViewController * TopmostViewControllerWithRootViewController(UIViewController *rootViewController) {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)rootViewController;
        return TopmostViewControllerWithRootViewController(tabBarController.selectedViewController);
    }
    else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController;
        return TopmostViewControllerWithRootViewController(navigationController.visibleViewController);
    }
    else if (rootViewController.presentedViewController) {
        UIViewController *presentedViewController = rootViewController.presentedViewController;
        return TopmostViewControllerWithRootViewController(presentedViewController);
    }
    else {
        return rootViewController;
    }
}

-(void)_setFocusAndExposureAtPoint:(CGPoint)point {
    AVCaptureDevice *inputCamera = self.stillCamera.inputCamera;
    
    if ([inputCamera lockForConfiguration:nil]) {
        //focus
        if ([inputCamera isFocusPointOfInterestSupported]) {
            [inputCamera setFocusPointOfInterest:point];
            
            if ([inputCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [inputCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            else if ([inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                [inputCamera setFocusMode:AVCaptureFocusModeAutoFocus];
            }
        }
        
        //exposure
        if ([inputCamera isExposurePointOfInterestSupported]) {
            [inputCamera setExposurePointOfInterest:point];
            
            if ([inputCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [inputCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            else if ([inputCamera isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
                [inputCamera setExposureMode:AVCaptureExposureModeAutoExpose];
            }
        }
        
        //unlock configuration
        [inputCamera unlockForConfiguration];
    }
}

-(CGFloat)_maxOutputImageResolutionBeforeCropping {
    //if it's set to max resolution, just return that
    if (self.maxOutputImageResolution == GBUnlimitedImageResolution) {
        return self.maxOutputImageResolution;
    }
    //otherwise, calculate the desired resolution of the raw image feed so that after cropping we end up with the desired output image resolution
    else {
        CGFloat scalingFactor = self.cropRegion.size.width * self.cropRegion.size.height;
        return self.maxOutputImageResolution / scalingFactor;
    }
}

-(BOOL)_areFiltersEnabled {
    return (self.filters.count >= 1);
}

-(BOOL)_devicHasCamera {
    return [self.stillCamera isBackFacingCameraPresent];
}

-(CGFloat)_rotationAngleForCurrentDeviceOrientation {
    switch (self.deviceOrientation) {
            case GBMotionDeviceOrientationPortraitUpsideDown: {
                return M_PI;
            } break;
            
            case GBMotionDeviceOrientationLandscapeRight: {
                return M_PI_2;
            } break;
            
            case GBMotionDeviceOrientationLandscapeLeft: {
                return -M_PI_2;
            } break;
            
            case GBMotionDeviceOrientationPortrait:
            case GBMotionDeviceOrientationUnknown: {
                return 0;
            } break;
    }
}

-(void)_dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)_handleViewfinderOverlay {
    //add it to the view hierarch if it hasn't already been added
    if (self.isViewLoaded && self.viewfinderOverlay.superview != self.view) {
        [self.view insertSubview:self.viewfinderOverlay aboveSubview:self.tapToFocusView];
        
        self.viewfinderOverlay.frame = CGRectMake(self.livePreviewView.frame.origin.x,
                                                  self.view.bounds.origin.y + kCameraViewportPadding.top,
                                                  self.livePreviewView.frame.size.width,
                                                  self.livePreviewView.frame.size.height);
    }
    
    //manage the showing and hiding
    if ((self.state == GBFancyCameraStateCapturing) && [self _devicHasCamera]) {
        self.viewfinderOverlay.alpha = 1;
    }
    else {
        self.viewfinderOverlay.alpha = 0;
    }
}

-(void)_handleNoCameraLabel {
    NSString *noCameraText = NSLocalizedStringFromTableInBundle(@"No camera available.", @"GBFancyCameraLocalizations", self.class.resourcesBundle, @"no camera string");
    if (self.isCameraRollEnabled) noCameraText = [noCameraText stringByAppendingString:[NSString stringWithFormat:@"\n%@", NSLocalizedStringFromTableInBundle(@"You can still use the camera roll.", @"GBFancyCameraLocalizations", self.class.resourcesBundle, @"no camera string")]];
    self.noCameraLabel.text = noCameraText;
    
    //handle no camera
    BOOL showNoCameraLabel = ((self.state == GBFancyCameraStateCapturing) && ![self _devicHasCamera]);
    self.noCameraLabel.hidden = !showNoCameraLabel;
}

-(void)_acceptPhoto {
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:self.originalImage];

    //create a new filter object because the other one is already hooked up and in use for the preview
    GPUImageOutput<GBFancyCameraFilterProtocol, GPUImageInput> *filterObject = [self.currentFilter.class new];
    
    [stillImageSource addTarget:filterObject];
    
    [filterObject useNextFrameForImageCapture];
    [stillImageSource processImage];
    UIImage *filteredImage = [filterObject imageFromCurrentFramebuffer];

    self.processedImage = filteredImage;
    
    [self _returnControlSuccessfulCapture:YES];
    [self _cleanupHeavyStuff];
}

-(void)_cancel {
    [self _returnControlSuccessfulCapture:NO];
    [self _cleanupHeavyStuff];
}

-(void)_capturePhoto {
    //if it has a cam do the right thing
    if ([self _devicHasCamera]) {
        self.mainButton.enabled = NO;
        
        //take photo
        [self.stillCamera capturePhotoAsImageProcessedUpToFilter:self.liveEgressMain withCompletionHandler:^(UIImage *processedImage, NSError *error) {
            UIImage *rotatedImage = [processedImage rotateInRadians:[self _rotationAngleForCurrentDeviceOrientation]];
            
            [self _obtainedNewImage:rotatedImage fromSource:GBFancyCameraSourceCamera];
            
            self.mainButton.enabled = YES;
        }];
    }
    //otherwise redirect to the camera roll
    else {
        [self _cameraRoll];
    }
}

-(void)_cameraRoll {
    if ([self _canShowSystemMediaBrowser]) {
        self.cameraRollButton.enabled = NO;
        [self _showSystemMediaBrowser];
    }
    else {
        self.noCameraLabel.text = NSLocalizedStringFromTableInBundle(@"Camera roll not available.", @"GBFancyCameraLocalizations", self.class.resourcesBundle, @"camera roll not available");
    }
}

-(void)_retake {
    //cleanup heavy
    [self _cleanupHeavyStuff];
    
    //reconnect live feed
    [self.liveEgressMain addTarget:self.livePreviewView];
    
    //continue capturing
    self.livePreviewView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    [self.stillCamera resumeCameraCapture];
    
    [self _transitionUIToState:GBFancyCameraStateCapturing animated:YES];
}

-(void)_obtainedNewImage:(UIImage *)image fromSource:(GBFancyCameraSource)source {
    self.originalImage = image;
    self.imageSource = source;
    
    //create thumbnails
    [self _createFilterViews];
    
    //transition state
    [self _transitionUIToState:GBFancyCameraStateFilters animated:YES];
}

-(void)_createFilterViews {
    self.filtersScrollView.alwaysBounceHorizontal = YES;
    self.filterViews = [NSMutableArray new];
    
    //if no filters are set, just set the default to GBNoFilter
    NSArray *filters;
    if ([self _areFiltersEnabled]) {
        filters = self.filters;
    }
    else {
        filters = @[GBNoFilter.class];
    }
    
    NSUInteger index = 0;
    for (Class filterClass in filters) {
        GPUImageOutput<GBFancyCameraFilterProtocol, GPUImageInput> *filterObject = [filterClass new];
        
        //filter the image using each of these filters in turn
        GBFilterView *filterView = [[GBFilterView alloc] initWithFrame:CGRectMake(kThumbnailBoxMargin.left + index * (kThumbnailBoxSize.width + MAX(kThumbnailBoxMargin.left, kThumbnailBoxMargin.right)),
                                                                                  kThumbnailBoxMargin.top,
                                                                                  kThumbnailBoxSize.width,
                                                                                  kThumbnailBoxSize.height)];
        filterView.filterClass = filterClass;
        filterView.delegate = self;
        filterView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        
        //filter name
        filterView.title = filterObject.localisedName;
        
        UIImage *filteredImage = [filterObject imageByFilteringImage:self.originalImage];
        filterView.image = filteredImage;
        
        //add it to the scrollview
        [self.filtersScrollView addSubview:filterView];
        
        //stretch the scrollview
        self.filtersScrollView.contentSize = CGSizeMake(filterView.frame.origin.x + filterView.frame.size.width + kThumbnailBoxMargin.right,
                                                        self.filtersScrollView.bounds.size.height);
        
        //add it to our filterViews
        [self.filterViews addObject:filterView];
        
        index += 1;
    }
    
    //select the first one initially
    GBFilterView *firstFilterView = self.filterViews[0];
    firstFilterView.isSelected = YES;
    [self _applyFilterWithClass:firstFilterView.filterClass];
}

-(void)_applyFilterWithClass:(Class)filterClass {
    GPUImageOutput<GBFancyCameraFilterProtocol, GPUImageInput> *filterObject = [filterClass new];
    self.currentFilter = filterObject;
    [self.liveEgressMain removeAllTargets];
    [self.cropFilter removeAllTargets];
    
    self.imagePic = [[GPUImagePicture alloc] initWithImage:self.originalImage];
    [self.imagePic addTarget:self.cropFilter];
    [self.cropFilter addTarget:filterObject];
    [filterObject addTarget:self.livePreviewView];
    self.livePreviewView.fillMode = kGPUImageFillModePreserveAspectRatio;
    
    [self.imagePic processImage];
}

-(void)_destroyFilterViews {
    for (GBFilterView *aFilterView in self.filterViews) {
        [aFilterView removeFromSuperview];
    }
    self.filterViews = nil;
}

-(void)_returnControlSuccessfulCapture:(BOOL)succesfulCapture {
    //call delegate methods
    if (self.delegate) {
        if (succesfulCapture) {
            [self.delegate fancyCamera:self didTakePhotoWithOriginalImage:self.originalImage processedImage:self.processedImage fromSource:self.imageSource filterClass:self.currentFilter.class];
        }
        else {
            [self.delegate fancyCameraDidCancelTakingPhoto:self];
        }
    }
    
    //call block based method
    if (self.completionBlock) {
        BOOL shouldDismiss = kDefaultShouldAutoDismiss;
        
        if (succesfulCapture) {
            self.completionBlock(self.originalImage, self.processedImage, YES, self.imageSource, self.currentFilter.class, &shouldDismiss);
        }
        else {
            self.completionBlock(nil, nil, NO, GBFancyCameraSourceNone, nil, &shouldDismiss);
        }
        self.completionBlock = nil;
        
        //dismiss if we need to
        if (shouldDismiss) {
            [self _dismiss];
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
                //resume capturing
                [self.stillCamera resumeCameraCapture];
                
                //rotate button back to device orientation
                self.mainButton.transform = CGAffineTransformMakeRotation([self _rotationAngleForCurrentDeviceOrientation]);
                
                //animations
                [UIView animateWithDuration:duration delay:0 options:0 animations:^{
                    //viewport
                    [self _setLivePreviewFrameWhenShowingBottomBar:NO];
                    
                    //main button
                    [self.mainButton setImage:[UIImage imageNamed:BundledResource(@"fancy-camera-snap-button-icon-camera")] forState:UIControlStateNormal];
                    self.mainButton.frame = CGRectMake((self.barContainerView.bounds.size.width - self.mainButton.frame.size.width) / 2,
                                                       (self.barContainerView.bounds.size.height - self.mainButton.frame.size.height) / 2 + kMainButtonCenterOffset,
                                                       self.mainButton.frame.size.width,
                                                       self.mainButton.frame.size.height);
                    
                    //retake button
                    self.retakeButton.alpha = 0;
                    
                    //camera roll button
                    self.cameraRollButton.alpha = 1;
                    
                    //filters
                    [self _setFiltersFrameToShowFilters:NO];
                    
                    //heading
                    self.barHeadingLabel.alpha = 0;
                } completion:nil];
            } break;
            
            case GBFancyCameraStateFilters: {
                //pause capturing
                [self.stillCamera pauseCameraCapture];
                
                //rotate button to defailt
                self.mainButton.transform = CGAffineTransformIdentity;
                
                //animations
                [UIView animateWithDuration:duration delay:0 options:0 animations:^{
                    //viewport
                    [self _setLivePreviewFrameWhenShowingBottomBar:[self _areFiltersEnabled]];
                    
                    //main button
                    [self.mainButton setImage:[UIImage imageNamed:BundledResource(@"fancy-camera-snap-button-icon-tick")] forState:UIControlStateNormal];
                    self.mainButton.frame = CGRectMake(self.barContainerView.bounds.size.width - (kMainButtonAcceptModeRightCenterMargin + self.mainButton.frame.size.width / 2),
                                                       (self.barContainerView.bounds.size.height - self.mainButton.frame.size.height) / 2 + kMainButtonCenterOffset,
                                                       self.mainButton.frame.size.width,
                                                       self.mainButton.frame.size.height);
                    
                    //retake button
                    self.retakeButton.alpha = 1;
                    
                    //camera roll button
                    self.cameraRollButton.alpha = 0;
                    
                    //filters
                    [self _setFiltersFrameToShowFilters:[self _areFiltersEnabled]];
                    
                    //heading
                    NSString *barHeadingText;
                    
                    if ([self _areFiltersEnabled]) {
                        barHeadingText = NSLocalizedStringFromTableInBundle(@"Filters", @"GBFancyCameraLocalizations", self.class.resourcesBundle, @"filters state heading");
                    }
                    else {
                        barHeadingText = NSLocalizedStringFromTableInBundle(@"Preview", @"GBFancyCameraLocalizations", self.class.resourcesBundle, @"preview state heading");
                    }
                    
                    self.barHeadingLabel.text = barHeadingText;
                    self.barHeadingLabel.alpha = 1;
                } completion:nil];
            } break;
        }
        
        //remember state
        _state = state;
        
        //handle no camera label
        [self _handleNoCameraLabel];
        
        //handle viewfinder overlay
        [self _handleViewfinderOverlay];
    }
}

-(void)_setFiltersFrameToShowFilters:(BOOL)shouldShowFilters {
    if (shouldShowFilters) {
        self.filtersContainerView.frame = CGRectMake(0,
                                                     self.view.bounds.size.height - kFilterTrayHeight - kFilterTrayBottomMarginOpen,
                                                     self.filtersContainerView.frame.size.width,
                                                     self.filtersContainerView.frame.size.height);
    }
    else {
        self.filtersContainerView.frame = CGRectMake(0,
                                                     self.view.bounds.size.height - kFilterTrayHeight - kFilterTrayBottomMarginClosed,
                                                     self.filtersContainerView.frame.size.width,
                                                     self.filtersContainerView.frame.size.height);
    }
}

-(void)_setLivePreviewFrameWhenShowingBottomBar:(BOOL)isShowingBottomBar {
    if (isShowingBottomBar) {
        self.livePreviewView.frame = CGRectMake(self.livePreviewView.frame.origin.x,
                                                (self.view.bounds.size.height - (kFilterTrayHeight + kFilterTrayBottomMarginOpen) - self.livePreviewView.frame.size.height) / 2,
                                                self.livePreviewView.frame.size.width,
                                                self.livePreviewView.frame.size.height);
    }
    else {
        self.livePreviewView.frame = CGRectMake(self.livePreviewView.frame.origin.x,
                                                self.view.bounds.origin.y + kCameraViewportPadding.top,
                                                self.livePreviewView.frame.size.width,
                                                self.livePreviewView.frame.size.height);
    }
}

-(void)_cleanupHeavyStuff {
    //ditch all hight memory stuff
    self.originalImage = nil;
    self.processedImage = nil;
    self.imagePic = nil;
    
    [self.currentFilter removeAllTargets];
    self.currentFilter = nil;
    
    [self _destroyFilterViews];
    
    //clear live preview view
    [self.livePreviewView setNeedsDisplay];
    
    //reset output if camera isn't available (if one is available, then the new camera feed will purge whats in there currently, if there is no camera feed however, then we need to manually clear it by pushing through a black image)
    if (![self _devicHasCamera]) {
        GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithSolidColor:[UIColor blackColor]]];
        [pic addTarget:self.livePreviewView];
        [pic processImage];
        [pic removeAllTargets];
    }
}

-(UIImage *)_processCameraRollImage:(UIImage *)originalImage {
    CGFloat originalResolution = originalImage.size.width * originalImage.size.height;
    
    //if the max resolution is bigger than the image, just return the original image
    if ([self _maxOutputImageResolutionBeforeCropping] >= originalResolution) {
        return originalImage;
    }
    //otherwise resize it
    else {
        //first resize it to a better size
        CGFloat scalingFactor = pow([self _maxOutputImageResolutionBeforeCropping] / originalResolution, 0.5);
        CGSize newSize = CGSizeMake(roundf(originalImage.size.width * scalingFactor), roundf(originalImage.size.height * scalingFactor));
        
        //scale and rotate image
        UIImage *scaledAndRotatedImage = [originalImage resizedImage:newSize interpolationQuality:kCGInterpolationMedium];
        
        return scaledAndRotatedImage;
    }
}

#pragma mark - System media picker util

-(BOOL)_canShowSystemMediaBrowser {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        return YES;
    }
    else {
        return NO;
    }
}

-(void)_showSystemMediaBrowser {
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.mediaTypes = @[(NSString *)kUTTypeImage];
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    
    //iOS 7 (handle color of status bar
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    }
    
    [self.stillCamera pauseCameraCapture];
    [self presentViewController:mediaUI animated:YES completion:nil];
}

#pragma mark - UITapGestureRecognizer

-(void)_didTapToFocus:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.isTapToFocusEnabled && self.state == GBFancyCameraStateCapturing && [self _devicHasCamera]) {
            //find position in view
            CGPoint pointInView = CGPointMake(self.livePreviewView.bounds.size.width / 2., self.livePreviewView.bounds.size.height / 2.);//TODO, for now just using the center
            CGPoint pointInSuperview = [self.tapToFocusView.superview convertPoint:pointInView fromView:self.livePreviewView];
            
            //display visual indicator at point in view
            [self.tapToFocusView animateAtPointInSuperview:pointInSuperview];
            
            //find normalised position in camera coordinate
            CGPoint pointInCamera = CGPointMake(0.5, 0.5);//TODO for now just using the center

            //set focus on the camera
            [self _setFocusAndExposureAtPoint:pointInCamera];
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    
    UIImage *resizedAndRotatedImage = [self _processCameraRollImage:image];
    
    [self _obtainedNewImage:resizedAndRotatedImage fromSource:GBFancyCameraSourceCameraRoll];
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    self.cameraRollButton.enabled = YES;
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self.stillCamera resumeCameraCapture];
    self.cameraRollButton.enabled = YES;
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
}

#pragma mark - GBFilterViewDelegate

-(void)didSelectFilterView:(GBFilterView *)filterView {
    //deselect all the other ones
    for (GBFilterView *anotherFilterView in self.filterViews) {
        if (anotherFilterView != filterView) {
            anotherFilterView.isSelected = NO;
        }
    }
    
    //create filter
    [self _applyFilterWithClass:filterView.filterClass];
}

#pragma mark - App resign/restore active hooks

-(void)applicationWillResignActive {
    self.wasCapturingBeforeResignActive = self.stillCamera.isCapturing;
    
    if (self.stillCamera.isCapturing) {
        [self.stillCamera pauseCameraCapture];
    }
}

-(void)applicationDidBecomeActive {
    if (self.wasCapturingBeforeResignActive && !self.stillCamera.isCapturing) {
        [self.stillCamera resumeCameraCapture];
    }
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
        [self _acceptPhoto];
    }
}

-(void)cameraRollAction:(id)sender {
    [self _cameraRoll];
}

@end

//
//  TapToFocusView.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 05/03/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import "TapToFocusView.h"

static CGFloat const kDefaultLineWidth =                        1.;
static CGFloat const kDefaultNotchDepth =                       5.;
#define kDefaultLineColor                                       ([UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0])
static CGSize const kDefaultBigSize =                           (CGSize){125, 125};
static CGSize const kDefaultSmallSize =                         (CGSize){65, 65};
static NSTimeInterval const kDefaultResizeAnimationDuration =   0.25;
static NSTimeInterval const kDefaultRestAnimationDuration =     1.2;
static CGFloat const kDefaultWobbleMaxAlpha =                   0.9;
static CGFloat const kDefaultWobbleMinAlpha =                   0.65;
static NSTimeInterval const kDefaultWobbleAnimationInterval =   0.1;
static NSTimeInterval const kDefaultFadeOutAnimationDuration =  0.1;

@implementation TapToFocusView

#pragma mark - Life

-(id)init {
    if (self = [super init]) {
        //defaults
        self.lineWidth = kDefaultLineWidth;
        self.notchDepth = kDefaultNotchDepth;
        self.lineColor = kDefaultLineColor;
        self.bigSize = kDefaultBigSize;
        self.smallSize = kDefaultSmallSize;
        self.resizeAnimationDuration = kDefaultResizeAnimationDuration;
        self.restAnimationDuration = kDefaultRestAnimationDuration;
        self.wobbleMaxAlpha = kDefaultWobbleMaxAlpha;
        self.wobbleMinAlpha = kDefaultWobbleMinAlpha;
        self.wobbleAnimationInterval = kDefaultWobbleAnimationInterval;
        self.fadeOutAnimationDuration = kDefaultFadeOutAnimationDuration;
        
        //config
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.userInteractionEnabled = NO;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0;
    }
    
    return self;
}

-(void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    //set up
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    CGContextSetLineWidth(context, self.lineWidth);
    
    //add box
    CGRect outline = CGRectMake(self.lineWidth / 2.,
                                self.lineWidth / 2.,
                                self.bounds.size.width - self.lineWidth,
                                self.bounds.size.height - self.lineWidth);
    CGContextAddRect(context, outline);
    
    //add notches
    CGPoint topCenter = CGPointMake(self.bounds.size.width / 2., self.lineWidth);
    CGPoint rightCenter = CGPointMake(self.bounds.size.width - self.lineWidth, self.bounds.size.height / 2.);
    CGPoint bottomCenter = CGPointMake(self.bounds.size.width / 2., self.bounds.size.height - self.lineWidth);
    CGPoint leftCenter = CGPointMake(self.lineWidth, self.bounds.size.height / 2.);
    CGContextMoveToPoint(context, topCenter.x, topCenter.y);
    CGContextAddLineToPoint(context, topCenter.x, topCenter.y + self.notchDepth);
    CGContextMoveToPoint(context, rightCenter.x, rightCenter.y);
    CGContextAddLineToPoint(context, rightCenter.x - self.notchDepth, rightCenter.y);
    CGContextMoveToPoint(context, bottomCenter.x, bottomCenter.y);
    CGContextAddLineToPoint(context, bottomCenter.x, bottomCenter.y - self.notchDepth);
    CGContextMoveToPoint(context, leftCenter.x, leftCenter.y);
    CGContextAddLineToPoint(context, leftCenter.x + self.notchDepth, leftCenter.y);
    
    //draw
    CGContextStrokePath(context);
}

#pragma mark - API

-(void)animateAtPointInSuperview:(CGPoint)point {
    if (!self.superview) @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"TapToFocusView does not have a superview, it must not be nil" userInfo:nil];

    [self setNeedsDisplay];
    
    CGRect startFrame = CGRectMake(point.x - self.bigSize.width / 2.,
                                   point.y - self.bigSize.height / 2.,
                                   self.bigSize.width,
                                   self.bigSize.height);
    CGRect endFrame = CGRectMake(point.x - self.smallSize.width / 2.,
                                 point.y - self.smallSize.height / 2.,
                                 self.smallSize.width,
                                 self.smallSize.height);
        
    self.frame = startFrame;
    self.alpha = self.wobbleMaxAlpha;
    
    //set up the wobble animation
    [UIView animateWithDuration:self.wobbleAnimationInterval delay:0 options:(UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat) animations:^{
        self.alpha = self.wobbleMinAlpha;
    } completion:nil];
    
    //set up the resize animation
    [UIView animateWithDuration:self.resizeAnimationDuration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.frame = endFrame;
    } completion:^(BOOL finished) {
        double delayInSeconds = self.restAnimationDuration;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.layer removeAllAnimations];//turns off the wobble animation
            [UIView animateWithDuration:self.fadeOutAnimationDuration delay:0 options:0 animations:^{
                self.alpha = 0;
            } completion:nil];
        });
    }];
}

@end

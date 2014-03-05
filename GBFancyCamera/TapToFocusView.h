//
//  TapToFocusView.h
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 05/03/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TapToFocusView : UIView

@property (assign, nonatomic) CGFloat           lineWidth;                  //default: 1
@property (assign, nonatomic) CGFloat           notchDepth;                 //default: 5
@property (strong, nonatomic) UIColor           *lineColor;                 //default: rgba(1.0, 0.8, 0.0, 1.0)
@property (assign, nonatomic) CGSize            bigSize;                    //default: (CGSize){125, 125}
@property (assign, nonatomic) CGSize            smallSize;                  //default: (CGSize){65, 65}
@property (assign, nonatomic) NSTimeInterval    resizeAnimationDuration;    //default: 0.25
@property (assign, nonatomic) NSTimeInterval    restAnimationDuration;      //default: 1.2
@property (assign, nonatomic) CGFloat           wobbleMaxAlpha;             //default: 0.9
@property (assign, nonatomic) CGFloat           wobbleMinAlpha;             //default: 0.65
@property (assign, nonatomic) NSTimeInterval    wobbleAnimationInterval;    //default: 0.1
@property (assign, nonatomic) NSTimeInterval    fadeOutAnimationDuration;   //default: 0.1

-(id)init;//designated initializer

-(void)animateAtPointInSuperview:(CGPoint)point;

@end

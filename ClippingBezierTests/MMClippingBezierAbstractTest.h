//
//  MMClippingBezierAbstractTest.h
//  ClippingBezier
//
//  Created by Adam Wulf on 11/20/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClippingBezier.h"
@import PerformanceBezier;
#import <XCTest/XCTest.h>
#import "UIBezierPath+SamplePaths.h"

@interface MMClippingBezierAbstractTest : XCTestCase

- (CGFloat)round:(CGFloat)val to:(int)digits;

- (BOOL)point:(CGPoint)p1 isNearTo:(CGPoint)p2;

- (BOOL)checkTanPoint:(CGFloat)f1 isLessThan:(CGFloat)f2;
- (BOOL)check:(CGFloat)f1 isLessThan:(CGFloat)f2 within:(CGFloat)marginOfError;
- (BOOL)check:(CGFloat)f1 isEqualTo:(CGFloat)f2 within:(CGFloat)marginOfError;

@end

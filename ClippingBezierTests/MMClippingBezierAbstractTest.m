//
//  MMClippingBezierAbstractTest.m
//  ClippingBezier
//
//  Created by Adam Wulf on 11/20/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MMClippingBezierAbstractTest.h"
#import "ClippingBezier.h"
#import "PerformanceBezier.h"


#define kIntersectionPointPrecision .1

@implementation MMClippingBezierAbstractTest

- (CGFloat)round:(CGFloat)val to:(int)digits
{
    double factor = pow(10, digits);
    return roundf(val * factor) / factor;
}

- (BOOL)point:(CGPoint)p1 isNearTo:(CGPoint)p2
{
    CGFloat xDiff = ABS(p2.x - p1.x);
    CGFloat yDiff = ABS(p2.y - p1.y);
    return xDiff < kIntersectionPointPrecision && yDiff < kIntersectionPointPrecision;
}


- (BOOL)check:(CGFloat)f1 isLessThan:(CGFloat)f2 within:(CGFloat)marginOfError
{
    if (f1 <= (f2 * (1.0f + marginOfError))) {
        return YES;
    }
    NSLog(@"float value %f is > %f", f1, f2);
    return NO;
}

- (BOOL)check:(CGFloat)f1 isEqualTo:(CGFloat)f2 within:(CGFloat)marginOfError
{
    if (ABS(f1 - f2) < marginOfError) {
        return YES;
    }
    NSLog(@"float value %f is != %f within %f", f1, f2, marginOfError);
    return NO;
}

- (BOOL)checkTanPoint:(CGFloat)f1 isLessThan:(CGFloat)f2
{
    return [self check:f1 isLessThan:f2 within:.2];
}

@end

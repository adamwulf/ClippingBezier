//
//  UIBezierPath+SamplePaths.m
//  ClippingExampleApp
//
//  Created by Adam Wulf on 5/8/20.
//

#import "UIBezierPath+SamplePaths.h"

@implementation UIBezierPath (SamplePaths)

+ (UIBezierPath *)splitterPath
{
    UIBezierPath *path = path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(12.000000, 16.970563)];
    [path addLineToPoint:CGPointMake(208.000000, 16.970563)];
    [path addLineToPoint:CGPointMake(208.000000, 128.000000)];
    [path addLineToPoint:CGPointMake(12.000000, 128.000000)];
    [path closePath];

    return path;
}

+ (UIBezierPath *)splittingPath
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(12.000000, 32.000000)];
    [path addCurveToPoint:CGPointMake(12.000000, 32.000000) controlPoint1:CGPointMake(12.000000, 32.000000) controlPoint2:CGPointMake(12.000000, 32.000000)];
    [path addLineToPoint:CGPointMake(12.000000, 12.000000)];
    [path addLineToPoint:CGPointMake(12.000000, 128.000000)];
    [path addCurveToPoint:CGPointMake(12.000000, 128.000000) controlPoint1:CGPointMake(12.000000, 128.000000) controlPoint2:CGPointMake(12.000000, 128.000000)];
    [path addLineToPoint:CGPointMake(208.000000, 128.000000)];
    [path addLineToPoint:CGPointMake(208.000000, 128.000000)];
    [path addCurveToPoint:CGPointMake(208.000000, 128.000000) controlPoint1:CGPointMake(208.000000, 128.000000) controlPoint2:CGPointMake(208.000000, 128.000000)];
    [path addLineToPoint:CGPointMake(208.000000, 32.000000)];
    [path addLineToPoint:CGPointMake(208.000000, 32.000000)];
    [path addCurveToPoint:CGPointMake(208.000000, 32.000000) controlPoint1:CGPointMake(208.000000, 32.000000) controlPoint2:CGPointMake(208.000000, 32.000000)];
    [path addLineToPoint:CGPointMake(220.000000, 32.000000)];
    [path addLineToPoint:CGPointMake(220.000000, 32.000000)];
    [path addCurveToPoint:CGPointMake(211.514719, 28.485281) controlPoint1:CGPointMake(216.817402, 32.000000) controlPoint2:CGPointMake(213.765155, 30.735718)];
    [path addLineToPoint:CGPointMake(200.000000, 16.970563)];
    [path addLineToPoint:CGPointMake(190.828427, 26.142136)];
    [path addLineToPoint:CGPointMake(190.828427, 26.142136)];
    [path addCurveToPoint:CGPointMake(176.686292, 32.000000) controlPoint1:CGPointMake(187.077700, 29.892863) controlPoint2:CGPointMake(181.990621, 32.000000)];
    [path addLineToPoint:CGPointMake(12.000000, 32.000000)];
    [path closePath];

    return path;
}

@end

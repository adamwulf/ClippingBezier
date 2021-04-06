//
//  UIBezierPath+GeometryExtras.h
//  ClippingBezier
//
//  Created by Adam Wulf on 2/1/15.
//  Copyright (c) 2015 Adam Wulf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (GeometryExtras)

- (CGPoint)closestPointOnPathTo:(CGPoint)point;

- (UIBezierPath *)bezierPathByTrimmingFromClosestPointOnPathFrom:(CGPoint)pointNearTheCurve to:(CGPoint)toPoint;

- (BOOL)containsDuplicateAndReversedSubpaths;

- (CGPoint)pointOnPathAtElement:(NSInteger)elementIndex andTValue:(CGFloat)tVal;

/// Path elements that do not change the location of the curve at all are considered 0 effective-t-distance. For instance,
/// closing a path that has already arrived back at the moveTo location will have an effective-t-distance of 0 for any tValue
/// in that closePath element. See the GeometryTests for examples.
- (CGFloat)effectiveTDistanceFromElement:(NSInteger)elementIndex1 andTValue:(CGFloat)tVal1 toElement:(NSInteger)elementIndex2 andTValue:(CGFloat)tVal2;

@end

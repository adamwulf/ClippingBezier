//
//  UIBezierPath+GeometryExtras.h
//  ClippingBezier
//
//  Created by Adam Wulf on 2/1/15.
//  Copyright (c) 2015 Adam Wulf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (GeometryExtras)

-(CGPoint) closestPointOnPathTo:(CGPoint)point;

-(UIBezierPath*) bezierPathByTrimmingFromClosestPointOnPathFrom:(CGPoint)pointNearTheCurve to:(CGPoint)toPoint;

-(BOOL) containsDuplicateAndReversedSubpaths;

- (CGPoint) pointOnPathAtElement:(NSInteger)elementIndex andTValue:(CGFloat)tVal;

@end

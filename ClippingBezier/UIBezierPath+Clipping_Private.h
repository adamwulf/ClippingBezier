//
//  UIBezierPath+Clipping.h
//  ClippingBezier
//
//  Created by Adam Wulf on 9/10/13.
//  Copyright (c) 2013 Milestone Made LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DKUIBezierPathClippingResult.h"
#import "DKUIBezierPathShape.h"

@interface UIBezierPath (MMClipping_Private)

// for tests

+ (NSArray *)redAndBlueSegmentsForShapeBuildingCreatedFrom:(UIBezierPath *)shapePath bySlicingWithPath:(UIBezierPath *)scissorPath andNumberOfBlueShellSegments:(NSUInteger *)numberOfBlueShellSegments;

+ (NSArray *)removeIdenticalRedSegments:(NSArray *)redSegments andBlueSegments:(NSArray *)blueSegments;

- (DKUIBezierPathClippingResult *)clipUnclosedPathToClosedPath:(UIBezierPath *)closedPath usingIntersectionPoints:(NSArray *)intersectionPoints andBeginsInside:(BOOL)beginsInside;

+ (CGFloat)maxDistForEndPointTangents;

+ (NSArray *)findIntersectionsBetweenBezier:(CGPoint[4])bez1 andBezier:(CGPoint[4])bez2;

- (NSArray *)shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:(UIBezierPath *)scissorPath;

- (NSArray *)uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:(UIBezierPath *)scissorPath;

- (NSArray<DKUIBezierPathShape *> *)allUniqueShapesWithPath:(UIBezierPath *)scissors;

- (NSArray<DKUIBezierPathShape *> *)uniqueGluedShapesWithPath:(UIBezierPath *)scissors;

+ (CGPoint)fillCGPoints:(CGPoint *)bez withElement:(CGPathElement)element givenElementStartingPoint:(CGPoint)startPoint andSubPathStartingPoint:(CGPoint)pathStartPoint;

@end

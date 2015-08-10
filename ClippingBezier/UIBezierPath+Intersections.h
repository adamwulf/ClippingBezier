//
//  UIBezierPath+Intersections.h
//  ClippingBezier
//
//  Created by Adam Wulf on 2/1/15.
//  Copyright (c) 2015 Adam Wulf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DKIntersectionOfPaths.h"

@interface UIBezierPath (Intersections)

// boolean operations for an unclosed path on a closed path
- (NSArray*) pathsFromSelfIntersections;
-(void) addPathElement:(CGPathElement)element;

+(CGPoint) endPointForPathElement:(CGPathElement)element;


+(DKIntersectionOfPaths*) firstIntersectionBetween:(UIBezierPath*)myFlatPath
                                           andPath:(UIBezierPath*)otherFlatPath;

+(NSArray*) calculateIntersectionAndDifferenceBetween:(UIBezierPath*)myUnclosedPath
                                              andPath:(UIBezierPath*)otherClosedPath;

+(CGRect) boundsForElement:(CGPathElement)element withStartPoint:(CGPoint)startPoint andSubPathStartingPoint:(CGPoint)pathStartingPoint;

+(CGPoint) intersects2D:(CGPoint)p1 to:(CGPoint)p2 andLine:(CGPoint)p3 to:(CGPoint)p4;


@end

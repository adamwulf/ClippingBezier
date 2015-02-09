//
//  UIBezierPath+Intersections.h
//  DrawKit-iOS
//
//  Created by Adam Wulf on 2/1/15.
//  Copyright (c) 2015 Adam Wulf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (Intersections)

// boolean operations for an unclosed path on a closed path
- (NSArray*) pathsFromSelfIntersections;
-(void) addPathElement:(CGPathElement)element;

+(CGPoint) endPointForPathElement:(CGPathElement)element;


+(struct IntersectionOfPaths) firstIntersectionBetween:(UIBezierPath*)myFlatPath and:(UIBezierPath*)otherFlatPath;
+(NSArray*) calculateIntersectionAndDifferenceBetween:(UIBezierPath*)myUnclosedPath and:(UIBezierPath*)otherClosedPath;

+(CGRect) boundsForElement:(CGPathElement)element withStartPoint:(CGPoint)startPoint andSubPathStartingPoint:(CGPoint)pathStartingPoint;

+(CGPoint) intersects2D:(CGPoint)p1 to:(CGPoint)p2 andLine:(CGPoint)p3 to:(CGPoint)p4;


@end

//
//  DKUIBezierPathIntersectionPoint.h
//  ClippingBezier
//
//  Created by Adam Wulf on 9/11/13.
//  Copyright (c) 2013 Milestone Made LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DKUIBezierPathIntersectionPoint : NSObject

@property (readonly) NSInteger elementIndex1;
@property (readonly) NSInteger elementCount1;
@property (readonly) CGFloat tValue1;
@property (readonly) NSInteger elementIndex2;
@property (readonly) NSInteger elementCount2;
@property (readonly) CGFloat tValue2;
@property (readonly) CGPoint* bez1;
@property (readonly) CGPoint* bez2;
// the distance from the start of path1 that we find this intersection
@property (readonly) CGFloat lenAtInter1;
// the distance from the start of path2 that we find this intersection
@property (readonly) CGFloat lenAtInter2;
// the length of the entire path1, along which this intersection lies
@property (assign) CGFloat pathLength1;
// the length of the entire path2, along which this intersection lies
@property (assign) CGFloat pathLength2;
//
// this signals that a segment with this intersection as the boundary
// might cross from outside to inside the closed shape
// this is only a hint, and should be verified by the segment
@property (readonly) BOOL mayCrossBoundary;

+(id) intersectionAtElementIndex:(NSInteger)index1 andTValue:(CGFloat)tValue1 withElementIndex:(NSInteger)index2 andTValue:(CGFloat)tValue2 andElementCount1:(NSInteger)elementCount1 andElementCount2:(NSInteger)elementCount2 andLengthUntilPath1Loc:(CGFloat)len1 andLengthUntilPath2Loc:(CGFloat)len2;

-(DKUIBezierPathIntersectionPoint*) flipped;

-(CGPoint) location1;
-(CGPoint) location2;

-(BOOL) matchesElementEndpointWithIntersection:(DKUIBezierPathIntersectionPoint*)obj;

// will return YES if the input intersection's tvalue2 matches
// my tvalue 1, or vice versa
-(BOOL) crossMatchesIntersection:(DKUIBezierPathIntersectionPoint*)otherInter;

-(BOOL) isEqualToIntersection:(id)object;

-(BOOL) isCloseToIntersection:(DKUIBezierPathIntersectionPoint*)otherIntersection withPrecision:(CGFloat)precision;

@end

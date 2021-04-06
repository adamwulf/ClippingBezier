//
//  DKUIBezierPathIntersectionPoint+Private.h
//  ClippingBezier
//
//  Created by Adam Wulf on 11/15/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//


@interface DKUIBezierPathIntersectionPoint (Private)

- (id)initWithElementIndex:(NSInteger)index1 andTValue:(CGFloat)_tValue1 withElementIndex:(NSInteger)index2 andTValue:(CGFloat)_tValue2 andElementCount1:(NSInteger)_elementCount1 andElementCount2:(NSInteger)_elementCount2 andLengthUntilPath1Loc:(CGFloat)_lenAtInter1 andLengthUntilPath2Loc:(CGFloat)_lenAtInter2;

- (void)setMayCrossBoundary:(BOOL)mayCrossBoundary;

@end

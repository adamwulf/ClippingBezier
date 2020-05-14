//
//  DKUIBezierUnmatchedPathIntersectionPoint.m
//  ClippingBezier
//
//  Created by Adam Wulf on 12/30/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import "DKUIBezierUnmatchedPathIntersectionPoint.h"
#import "DKUIBezierPathIntersectionPoint+Private.h"

static NSUInteger uniqueIntersectionIdGeneration = 0;

@implementation DKUIBezierUnmatchedPathIntersectionPoint {
    NSUInteger uniqueUnmatchedIntersectionId;
}

@synthesize uniqueUnmatchedIntersectionId;

+ (id)intersectionAtElementIndex:(NSInteger)index1 andTValue:(CGFloat)_tValue1 withElementIndex:(NSInteger)index2 andTValue:(CGFloat)_tValue2 andElementCount1:(NSInteger)_elementCount1 andElementCount2:(NSInteger)_elementCount2 andLengthUntilPath1Loc:(CGFloat)_lenAtInter1 andLengthUntilPath2Loc:(CGFloat)_lenAtInter2
{
    return [[DKUIBezierUnmatchedPathIntersectionPoint alloc] initWithElementIndex:index1 andTValue:_tValue1 withElementIndex:index2 andTValue:_tValue2 andElementCount1:_elementCount1 andElementCount2:_elementCount2 andLengthUntilPath1Loc:_lenAtInter1 andLengthUntilPath2Loc:_lenAtInter2];
}

- (id)initWithElementIndex:(NSInteger)index1 andTValue:(CGFloat)_tValue1 withElementIndex:(NSInteger)index2 andTValue:(CGFloat)_tValue2 andElementCount1:(NSInteger)_elementCount1 andElementCount2:(NSInteger)_elementCount2 andLengthUntilPath1Loc:(CGFloat)_lenAtInter1 andLengthUntilPath2Loc:(CGFloat)_lenAtInter2
{
    if (self = [super initWithElementIndex:index1
                                 andTValue:_tValue1
                          withElementIndex:index2
                                 andTValue:_tValue2
                          andElementCount1:_elementCount1
                          andElementCount2:_elementCount2
                    andLengthUntilPath1Loc:_lenAtInter1
                    andLengthUntilPath2Loc:_lenAtInter2]) {
        @synchronized([DKUIBezierUnmatchedPathIntersectionPoint class])
        {
            [self setUniqueId:uniqueIntersectionIdGeneration];
            uniqueIntersectionIdGeneration++;
        }
    }
    return self;
}

- (void)setUniqueId:(NSUInteger)uid
{
    uniqueUnmatchedIntersectionId = uid;
}


- (BOOL)crossMatchesIntersection:(DKUIBezierPathIntersectionPoint *)otherInter
{
    return NO;
}

- (DKUIBezierPathIntersectionPoint *)flipped
{
    DKUIBezierUnmatchedPathIntersectionPoint *ret = [DKUIBezierUnmatchedPathIntersectionPoint intersectionAtElementIndex:self.elementIndex2
                                                                                                               andTValue:self.tValue2
                                                                                                        withElementIndex:self.elementIndex1
                                                                                                               andTValue:self.tValue1
                                                                                                        andElementCount1:self.elementCount2
                                                                                                        andElementCount2:self.elementCount1
                                                                                                  andLengthUntilPath1Loc:self.lenAtInter2
                                                                                                  andLengthUntilPath2Loc:self.lenAtInter1];
    ret.bez1[0] = self.bez2[0];
    ret.bez1[1] = self.bez2[1];
    ret.bez1[2] = self.bez2[2];
    ret.bez1[3] = self.bez2[3];
    ret.bez2[0] = self.bez1[0];
    ret.bez2[1] = self.bez1[1];
    ret.bez2[2] = self.bez1[2];
    ret.bez2[3] = self.bez1[3];
    ret.mayCrossBoundary = self.mayCrossBoundary;
    ret.pathLength1 = self.pathLength2;
    ret.pathLength2 = self.pathLength1;
    [ret setUniqueId:self.uniqueUnmatchedIntersectionId];
    return ret;
}


- (BOOL)isEqualToIntersection:(id)object
{
    if ([object isKindOfClass:[DKUIBezierUnmatchedPathIntersectionPoint class]]) {
        DKUIBezierUnmatchedPathIntersectionPoint *other = (DKUIBezierUnmatchedPathIntersectionPoint *)object;
        if (other.uniqueUnmatchedIntersectionId == self.uniqueUnmatchedIntersectionId &&
            [super isEqualToIntersection:object]) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash
{
    NSUInteger prime = 31;
    NSUInteger result = [super hash];
    result = prime * result + (self.uniqueUnmatchedIntersectionId) ? 1231 : 1237;
    return result;
}


@end

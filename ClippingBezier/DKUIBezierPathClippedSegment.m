//
//  DKUIBezierPathClippedSegment.m
//  LooseLeaf
//
//  Created by Adam Wulf on 10/7/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import "DKUIBezierPathClippedSegment.h"
#import "PerformanceBezier.h"
#import "DKVector.h"
#import "UIBezierPath+Clipping.h"
#import "UIBezierPath+Trimming.h"

@implementation DKUIBezierPathClippedSegment {
    DKUIBezierPathIntersectionPoint *startIntersection;
    DKUIBezierPathIntersectionPoint *endIntersection;
    UIBezierPath *pathSegment;
    UIBezierPath *reversedPathSegment;
    UIBezierPath *fullPath;

    __weak DKUIBezierPathClippedSegment *reversedFrom;
    __weak DKUIBezierPathClippedSegment *flippedFrom;
    BOOL isReversed;
}

@synthesize startIntersection;
@synthesize endIntersection;
@synthesize pathSegment;
@synthesize fullPath;
@synthesize isReversed;
@synthesize isFlipped;

- (void)setIsReversed:(BOOL)r
{
    isReversed = r;
}
- (void)setReversedFrom:(DKUIBezierPathClippedSegment *)r
{
    reversedFrom = r;
}
- (void)setFlippedFrom:(DKUIBezierPathClippedSegment *)r
{
    flippedFrom = r;
}
- (void)setIsFlipped:(BOOL)f
{
    isFlipped = f;
}

+ (DKUIBezierPathClippedSegment *)clippedPairWithStart:(DKUIBezierPathIntersectionPoint *)_tStart andEnd:(DKUIBezierPathIntersectionPoint *)_tEnd andPathSegment:(UIBezierPath *)segment fromFullPath:(UIBezierPath *)_fullPath
{
    return [[DKUIBezierPathClippedSegment alloc] initWithStart:_tStart andEnd:_tEnd andPathSegment:segment fromFullPath:_fullPath];
}

- (id)initWithStart:(DKUIBezierPathIntersectionPoint *)_tStart andEnd:(DKUIBezierPathIntersectionPoint *)_tEnd andPathSegment:(UIBezierPath *)segment fromFullPath:(UIBezierPath *)_fullPath
{
    if (self = [super init]) {
        startIntersection = _tStart;
        endIntersection = _tEnd;
        pathSegment = segment;
        fullPath = _fullPath;
    }
    return self;
}

- (UIBezierPath *)pathSegment
{
    if ([self isReversed]) {
        if (!reversedPathSegment) {
            reversedPathSegment = [pathSegment bezierPathByReversingPath];
        }
        return reversedPathSegment;
    }
    return pathSegment;
}

- (DKUIBezierPathClippedSegment *)flippedRedBlueSegment
{
    return [self flippedSegment];
}

- (DKUIBezierPathClippedSegment *)flippedSegment
{
    if (flippedFrom) {
        return flippedFrom;
    }
    DKUIBezierPathClippedSegment *flippedSeg = [DKUIBezierPathClippedSegment clippedPairWithStart:[startIntersection flipped] andEnd:[endIntersection flipped] andPathSegment:pathSegment fromFullPath:fullPath];
    [flippedSeg setIsReversed:self.isReversed];
    [flippedSeg setIsFlipped:!self.isFlipped];
    [flippedSeg setFlippedFrom:self];
    [self setFlippedFrom:flippedFrom];
    return flippedSeg;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[Segment: p1(%d:%f => %d:%f) p2(%d:%f => %d:%f)]",
                                      (int)startIntersection.elementIndex1, startIntersection.tValue1, (int)endIntersection.elementIndex1, endIntersection.tValue1,
                                      (int)startIntersection.elementIndex2, startIntersection.tValue2, (int)endIntersection.elementIndex2, endIntersection.tValue2];
}

- (BOOL)canBePrependedTo:(DKUIBezierPathClippedSegment *)otherPath
{
    if (otherPath.startIntersection == self.endIntersection) {
        return YES;
    }
    if (otherPath.startIntersection.elementIndex1 == 0 &&
        otherPath.startIntersection.tValue1 == 0 &&
        self.endIntersection.elementIndex1 == fullPath.elementCount - 1 &&
        self.endIntersection.tValue1 == 1) {
        return YES;
    }
    return NO;
}

- (DKUIBezierPathClippedSegment *)prependTo:(DKUIBezierPathClippedSegment *)otherSegment
{
    UIBezierPath *combinedPathSegment = [self.pathSegment copy];
    [combinedPathSegment appendPathRemovingInitialMoveToPoint:otherSegment.pathSegment];
    return [DKUIBezierPathClippedSegment clippedPairWithStart:self.startIntersection
                                                       andEnd:otherSegment.endIntersection
                                               andPathSegment:combinedPathSegment
                                                 fromFullPath:self.fullPath];
}

- (DKUIBezierPathClippedSegment *)reversedSegment
{
    if (reversedFrom) {
        return reversedFrom;
    }
    DKUIBezierPathClippedSegment *ret = [DKUIBezierPathClippedSegment clippedPairWithStart:self.endIntersection andEnd:self.startIntersection andPathSegment:pathSegment fromFullPath:self.fullPath];
    [ret setIsReversed:!isReversed];
    [ret setIsFlipped:self.isFlipped];
    [ret setReversedFrom:self];
    [self setReversedFrom:ret];
    return ret;
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:[DKUIBezierPathClippedSegment class]]) {
        return NO;
    }
    // Don't call reversedSegment, as we don't want to generate a reversed segment if we don't need it.
    DKUIBezierPathClippedSegment *asSeg = (DKUIBezierPathClippedSegment *)object;
    if (reversedFrom == object) {
        return YES;
    }
    if (asSeg->reversedFrom == self) {
        return YES;
    }
    if (reversedFrom && asSeg->reversedFrom == reversedFrom) {
        return YES;
    }

    if (![[self startIntersection] isEqual:[object startIntersection]] || ![[self endIntersection] isEqual:[object endIntersection]]) {
        return NO;
    }

    // at this point our intersections are the same, see if our paths are the same too
    return [[self pathSegment] isEqualToBezierPath:[object pathSegment]];
}

- (BOOL)isEqualToSegment:(DKUIBezierPathClippedSegment *)otherSegment
{
    return [otherSegment isKindOfClass:[DKUIBezierPathClippedSegment class]] &&
        [self.startIntersection isEqualToIntersection:otherSegment.startIntersection] &&
        [self.endIntersection isEqualToIntersection:otherSegment.endIntersection] &&
        self.isReversed == otherSegment.isReversed;
}

- (NSUInteger)hash
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + [startIntersection hash];
    result = prime * result + [endIntersection hash];
    result = prime * result + ((isReversed) ? 1231 : 1237);
    return result;
}


/**
 * calculates the angle between this segment's endpoint and the
 * otherInter's startpoint
 */
- (CGFloat)angleBetween:(DKUIBezierPathClippedSegment *)otherInter
{
    return [[self endVector] angleBetween:[otherInter startVector]];
}

- (DKVector *)endVector
{
    return [self.pathSegment tangentNearEnd].tangent;
}

- (DKVector *)startVector
{
    return [self.pathSegment tangentNearStart].tangent;
}


@end

//
//  UIBezierPath+Clipping.m
//  ClippingBezier
//
//  Created by Adam Wulf on 9/10/13.
//  Copyright (c) 2013 Milestone Made LLC. All rights reserved.
//
//
// much of the clipping code was originally bezier-utils.cpp
// in inkscape, licensed under Mozilla Public License Version 1.1
//


#pragma mark - UIBezier Clipping

#import "UIBezierPath+Clipping.h"
#include "interval.h"
#include <vector>
#import "DKUIBezierPathClippingResult.h"
#import "DKUIBezierPathIntersectionPoint.h"
#import "DKUIBezierPathClippedSegment.h"
#import "DKUIBezierPathIntersectionPoint+Private.h"
#import "DKUIBezierUnmatchedPathIntersectionPoint.h"
#include "bezierclip.hxx"
#import "DKUIBezierPathShape.h"
#import "UIBezierPath+Intersections.h"
#import "UIBezierPath+Trimming.h"
#import "UIBezierPath+Ahmed.h"
#import "PerformanceBezier.h"
#import "ClippingBezier.h"
#include "point.h"
#include "NearestPoint.h"
#include "bezier-clipping.h"

typedef struct Coeffs {
    CGFloat a3; // t^3
    CGFloat a2; // t^2
    CGFloat a1; // t
    CGFloat a0; // constant
} Coeffs;

using namespace Geom;

#define kUIBezierClippingPrecision 0.0005
#define kUIBezierClosenessPrecision 0.5

@implementation UIBezierPath (Clipping)

#pragma mark - Segment Comparison

// segment test count is the product
// of the two path's element count
static NSInteger segmentTestCount = 0;
// segment compare count is the number
// of segments that are actually tested
// for intersections, and is a subset
// of segmentTestCount
static NSInteger segmentCompareCount = 0;

+ (void)resetSegmentTestCount
{
    segmentTestCount = 0;
}

+ (NSInteger)segmentTestCount
{
    return segmentTestCount;
}

+ (void)resetSegmentCompareCount
{
    segmentCompareCount = 0;
}

+ (NSInteger)segmentCompareCount
{
    return segmentCompareCount;
}


#pragma mark - Intersection Finding

+ (BOOL)isBezierColinear:(CGPoint *)bezier
{
    CGFloat dist1 = [UIBezierPath distanceOfPointToLine:bezier[1] start:bezier[0] end:bezier[3]];

    if (dist1 != 0) {
        return NO;
    }

    CGFloat dist2 = [UIBezierPath distanceOfPointToLine:bezier[2] start:bezier[0] end:bezier[3]];

    return dist2 == 0;
}

/**
 * this will return all intersections points between
 * the self path and the input closed path.
 */
- (NSArray<DKUIBezierPathIntersectionPoint *> *)findIntersectionsWithClosedPath:(UIBezierPath *)closedPath andBeginsInside:(BOOL *)beginsInside
{
    // hold our bezier information for the curves we compare
    CGPoint bez1_[4];
    CGPoint bez2_[4];
    // pointer versions of the array, since [] can't be passed to blocks
    CGPoint *bez1 = bez1_;
    CGPoint *bez2 = bez2_;

    //
    // we're going to make this method generic, and iterate
    // over the flat path first, if available.
    // this means our algorithm will care about
    // path1 vs path2, not self vs closedPath
    UIBezierPath *path1;
    UIBezierPath *path2;
    // if the closed path is flat, it's significantly faster
    // to iterate over it first than it is to iterate over it last.
    // track if we've flipped the paths we're working with, so
    // that we'll return the intersections in the proper path's
    // element/tvalue first
    BOOL didFlipPathNumbers = NO;
    if ([closedPath isFlat]) {
        path1 = closedPath;
        path2 = self;
        didFlipPathNumbers = YES;
    } else {
        path1 = self;
        path2 = closedPath;
    }
    NSInteger elementCount1 = path1.elementCount;
    NSInteger elementCount2 = path2.elementCount;


    // track if the path1Element begins inside or
    // outside the closed path. this will help us track
    // if intersection points actually change where the curve
    // lands
    __block CGPoint lastPath1Point = CGPointNotFound;
    // this array will hold all of the intersection data as we
    // find them
    NSMutableArray<DKUIBezierPathIntersectionPoint *> *foundIntersections = [NSMutableArray array];


    __block CGPoint path1StartingPoint = path1.firstPoint;

    // first, confirm that the paths have a possibility of intersecting
    // at all by comparing their bounds
    CGRect path1Bounds = [path1 bounds];
    CGRect path2Bounds = [path2 bounds];
    // expand the bounds by 1px, just so we're sure to see overlapping bounds for tangent paths
    path1Bounds = CGRectInset(path1Bounds, -1, -1);
    path2Bounds = CGRectInset(path2Bounds, -1, -1);

    if (CGRectIntersectsRect(path1Bounds, path2Bounds)) {
        // track the number of segment comparisons we have to do
        // this tracks our worst case of how many segment rects intersect
        segmentTestCount += ([path1 elementCount] * [path2 elementCount]);
        // at this point, we know there's at least a possibility that
        // the curves intersect, but we don't know for sure until
        // we loop over elements and try to find them specifically
        //
        // to find intersections, we'll loop over our path first,
        // and for each element inside us, we'll loop over the closed shape
        // to see if we've moved in/out of the closed shape

        [path1 iteratePathWithBlock:^(CGPathElement path1Element, NSUInteger path1ElementIndex) {
            // must call this before fillCGPoints, since our call to fillCGPoints will update lastPath1Point
            CGRect path1ElementBounds = [UIBezierPath boundsForElement:path1Element withStartPoint:lastPath1Point andSubPathStartingPoint:path1StartingPoint];
            // expand the bounds by 1px, just so we're sure to see overlapping bounds for tangent paths
            path1ElementBounds = CGRectInset(path1ElementBounds, -1, -1);
            lastPath1Point = [UIBezierPath fillCGPoints:bez1
                                            withElement:path1Element
                              givenElementStartingPoint:lastPath1Point
                                andSubPathStartingPoint:path1StartingPoint];
            // only look for intersections if it's not a moveto point.
            // this way our bez1 array will be filled with a valid
            // bezier curve
            if (path1Element.type != kCGPathElementMoveToPoint) {
                __block CGPoint lastPath2Point = CGPointNotFound;

                if (CGRectIntersectsRect(path1ElementBounds, path2Bounds)) {
                    // at this point, we know that path1's element intersections somewhere within
                    // all of path 2, so we'll iterate over path2 and find as many intersections
                    // as we can
                    __block CGPoint path2StartingPoint = path2.firstPoint;
                    // big iterating over path2 to find all intersections with this element from path1
                    [path2 iteratePathWithBlock:^(CGPathElement path2Element, NSUInteger path2ElementIndex) {
                        // must call this before fillCGPoints, since that will update lastPath1Point
                        CGRect path2ElementBounds = [UIBezierPath boundsForElement:path2Element withStartPoint:lastPath2Point andSubPathStartingPoint:path2StartingPoint];
                        // expand the bounds by 1px, just so we're sure to see overlapping bounds for tangent paths
                        path2ElementBounds = CGRectInset(path2ElementBounds, -1, -1);
                        lastPath2Point = [UIBezierPath fillCGPoints:bez2
                                                        withElement:path2Element
                                          givenElementStartingPoint:lastPath2Point
                                            andSubPathStartingPoint:path2StartingPoint];
                        if (path2Element.type != kCGPathElementMoveToPoint) {
                            if (CGRectIntersectsRect(path1ElementBounds, path2ElementBounds)) {
                                // track the number of segment comparisons we have to do
                                // this tracks our worst case of how many segment rects intersect
                                segmentCompareCount++;

                                // at this point, we have two valid bezier arrays populated
                                // into bez1 and bez2. calculate if they intersect at all
                                NSArray *intersections;
                                if ((path1Element.type == kCGPathElementAddLineToPoint || path1Element.type == kCGPathElementCloseSubpath) &&
                                    (path2Element.type == kCGPathElementAddLineToPoint || path2Element.type == kCGPathElementCloseSubpath)) {
                                    // in this case, the two elements are both lines, so they can intersect at
                                    // only 1 place.
                                    // TODO: should i return two intersections if they're tangent?
                                    CGPoint intersection = [UIBezierPath intersects2D:bez1[0] to:bez1[3] andLine:bez2[0] to:bez2[3]];
                                    if (!CGPointEqualToPoint(intersection, CGPointNotFound)) {
                                        CGFloat path1TValue = [UIBezierPath distance:bez1[0] p2:intersection] / [UIBezierPath distance:bez1[0] p2:bez1[3]];
                                        CGFloat path2TValue = [UIBezierPath distance:bez2[0] p2:intersection] / [UIBezierPath distance:bez2[0] p2:bez2[3]];
                                        if (path1TValue >= 0 && path1TValue <= 1 &&
                                            path2TValue >= 0 && path2TValue <= 1) {
                                            intersections = [NSArray arrayWithObject:[NSValue valueWithCGPoint:CGPointMake(path2TValue, path1TValue)]];
                                        } else {
                                            // doesn't intersect within allowed T values
                                        }
                                    }
                                } else {
                                    // at least one of the curves is a proper bezier, so use our
                                    // bezier intersection algorithm to find possibly multiple intersections
                                    // between these curves
                                    if (path1Element.type == kCGPathElementAddCurveToPoint &&
                                        (path2Element.type == kCGPathElementAddLineToPoint || path2Element.type == kCGPathElementCloseSubpath) &&
                                        ![UIBezierPath isBezierColinear:bez1]) {
                                        CGPoint lineP1 = bez2[0];
                                        CGPoint lineP2 = bez2[3];
                                        intersections = [UIBezierPath findIntersectionsBetweenBezier:bez1 andLineFrom:lineP1 to:lineP2 flipped:true];
                                    } else if (path2Element.type == kCGPathElementAddCurveToPoint &&
                                               (path1Element.type == kCGPathElementAddLineToPoint || path1Element.type == kCGPathElementCloseSubpath) &&
                                               ![UIBezierPath isBezierColinear:bez2]) {
                                        CGPoint lineP1 = bez1[0];
                                        CGPoint lineP2 = bez1[3];
                                        intersections = [UIBezierPath findIntersectionsBetweenBezier:bez2 andLineFrom:lineP1 to:lineP2 flipped:false];
                                    } else {
                                        intersections = [UIBezierPath findIntersectionsBetweenBezier:bez1 andBezier:bez2];
                                    }
                                }
                                // loop through the intersections that we've found, and add in
                                // some context that we can save for each one.
                                for (NSValue *val in intersections) {
                                    CGPoint i = [val CGPointValue];
                                    CGFloat tValue1 = i.y;
                                    CGFloat tValue2 = i.x;
                                    // estimated length along each curve until the intersection is hit
                                    CGFloat lenTillPath1Inter = [path1 lengthOfPathThroughElement:path1ElementIndex tValue:tValue1 withAcceptableError:kUIBezierClosenessPrecision];
                                    CGFloat lenTillPath2Inter = [path2 lengthOfPathThroughElement:path2ElementIndex tValue:tValue2 withAcceptableError:kUIBezierClosenessPrecision];

                                    DKUIBezierPathIntersectionPoint *inter = [DKUIBezierPathIntersectionPoint intersectionAtElementIndex:path1ElementIndex
                                                                                                                               andTValue:tValue1
                                                                                                                        withElementIndex:path2ElementIndex
                                                                                                                               andTValue:tValue2
                                                                                                                        andElementCount1:elementCount1
                                                                                                                        andElementCount2:elementCount2
                                                                                                                  andLengthUntilPath1Loc:lenTillPath1Inter
                                                                                                                  andLengthUntilPath2Loc:lenTillPath2Inter];
                                    // store the two paths that the intersection relates to. these are
                                    // the paths that match each of the CGPathElements that we used to
                                    // find the intersection
                                    inter.bez1[0] = bez1[0];
                                    inter.bez1[1] = bez1[1];
                                    inter.bez1[2] = bez1[2];
                                    inter.bez1[3] = bez1[3];
                                    inter.bez2[0] = bez2[0];
                                    inter.bez2[1] = bez2[1];
                                    inter.bez2[2] = bez2[2];
                                    inter.bez2[3] = bez2[3];

                                    if (didFlipPathNumbers) {
                                        // we flipped the order that we're looking through paths,
                                        // so we need to flip the intersection indexes so that
                                        // bez1 is always the unclosed path and bez2 is always closed
                                        inter = [inter flipped];
                                    }

                                    // add to our output!
                                    [foundIntersections addObject:inter];
                                }
                            }
                        } else {
                            // it's a moveto element, so update our starting
                            // point for this subpath within the full path
                            path2StartingPoint = path2Element.points[0];
                        }
                    }];
                }
            } else {
                // it's a moveto element, so update our starting
                // point for this subpath within the full path
                path1StartingPoint = path1Element.points[0];
            }
        }];

        // make sure we have the points sorted by the intersection location
        // inside of self instead of inside the closed curve
        [foundIntersections sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ([obj1 elementIndex1] < [obj2 elementIndex1]) {
                return NSOrderedAscending;
            } else if ([obj1 elementIndex1] == [obj2 elementIndex1] &&
                       [obj1 tValue1] < [obj2 tValue1]) {
                return NSOrderedAscending;
            }
            return NSOrderedDescending;
        }];

        [foundIntersections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DKUIBezierPathIntersectionPoint *intersection = obj;
            if (!didFlipPathNumbers) {
                intersection.pathLength1 = [path1 length];
                intersection.pathLength2 = [path2 length];
            } else {
                intersection.pathLength1 = [path2 length];
                intersection.pathLength2 = [path1 length];
            }
        }];

        // save all of our intersections, we may need this reference
        // later if we filter out too many intersections as duplicates
        NSArray *allFoundIntersections = foundIntersections;

        // iterate over the intersections and filter out duplicates
        __block DKUIBezierPathIntersectionPoint *lastInter = [foundIntersections lastObject];
        foundIntersections = [NSMutableArray arrayWithArray:[foundIntersections filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(id obj, NSDictionary *bindings) {
            DKUIBezierPathIntersectionPoint *intersection = obj;
            BOOL isDistinctIntersection = ![obj matchesElementEndpointWithIntersection:lastInter];
            CGPoint interLoc = intersection.location1;
            CGPoint lastLoc = lastInter.location1;
            CGPoint interLoc2 = intersection.location2;
            CGPoint lastLoc2 = lastInter.location2;


            if (isDistinctIntersection) {
                if ((ABS(interLoc.x - lastLoc.x) < kUIBezierClosenessPrecision &&
                     ABS(interLoc.y - lastLoc.y) < kUIBezierClosenessPrecision) ||
                    (ABS(interLoc2.x - lastLoc2.x) < kUIBezierClosenessPrecision &&
                     ABS(interLoc2.y - lastLoc2.y) < kUIBezierClosenessPrecision)) {
                    // the points are close, but they might not necessarily be the same intersection.
                    // for instance, a curve could be a very very very sharp V, and the intersection could
                    // be slicing through the middle of the V to look like an ∀
                    // the distance between the intersections along the - might be super small,
                    // but along the V is much much further and should count as two intersections

                    BOOL closeLocation1 = [lastInter isCloseToIntersection:intersection withPrecision:kUIBezierClosenessPrecision];
                    BOOL closeLocation2 = [[lastInter flipped] isCloseToIntersection:[intersection flipped] withPrecision:kUIBezierClosenessPrecision];

                    isDistinctIntersection = !closeLocation1 || !closeLocation2;
                }
                // if we still think it's distinct, then also compare the effective t-values
                if (isDistinctIntersection) {
                    CGFloat closeT1 = [self effectiveTDistanceFromElement:[lastInter elementIndex1]
                                                                andTValue:[lastInter tValue1]
                                                                toElement:[intersection elementIndex1]
                                                                andTValue:[intersection tValue1]];

                    CGFloat closeT2 = [closedPath effectiveTDistanceFromElement:[lastInter elementIndex2]
                                                                      andTValue:[lastInter tValue2]
                                                                      toElement:[intersection elementIndex2]
                                                                      andTValue:[intersection tValue2]];

                    if (ABS(closeT1) < kUIBezierClippingPrecision && ABS(closeT2) < kUIBezierClippingPrecision) {
                        // The points are not actually very far apart at all in terms of t-distance. only bother to check
                        // pixel closeness if our t-values are at all far apart.
                        isDistinctIntersection = NO;
                    }
                }
            }
            if (isDistinctIntersection) {
                lastInter = obj;
            }
            return isDistinctIntersection;
        }]]];

        if (![foundIntersections count] && [allFoundIntersections count]) {
            // we accidentally filter out all of the points, because
            // they all matched
            // so add just 1 back in
            [foundIntersections addObject:[allFoundIntersections firstObject]];
        } else {
            // sort exact match intersections out of the flipped intersections
            // [MMClippingBezierIntersectionTests testLineNearBoundary]
            NSMutableArray *originallyFoundIntersections = [NSMutableArray arrayWithArray:foundIntersections];
            [foundIntersections sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                if ([obj1 elementIndex2] < [obj2 elementIndex2]) {
                    return NSOrderedAscending;
                } else if ([obj1 elementIndex2] == [obj2 elementIndex2] &&
                           [obj1 tValue2] < [obj2 tValue2]) {
                    return NSOrderedAscending;
                }
                return NSOrderedDescending;
            }];

            __block DKUIBezierPathIntersectionPoint *lastInter = nil;
            [foundIntersections enumerateObjectsUsingBlock:^(DKUIBezierPathIntersectionPoint *obj, NSUInteger idx, BOOL *stop) {
                if ([[lastInter flipped] matchesElementEndpointWithIntersection:[obj flipped]]) {
                    [originallyFoundIntersections removeObject:obj];
                };
                lastInter = obj;
            }];
            // this way, the sort order of the original foundIntersections
            // is maintained, and is also filtered to exclude intersections
            // that exactly match their flipped state
            foundIntersections = originallyFoundIntersections;
        }

        //
        // next i need to filter all of the intersections to
        // remove false positives. it's possible that we detected multiple
        // points that shouldn't be considered true intersections.
        //
        // for instance, intersections that occur at a tangent should be
        // removed. also, if self intersects the shape along a straight line,
        // then many intersection points will be found instead of just the
        // end points.
        if ([closedPath isClosed]) {
            // we only need to check for boundary crossing if
            // the path is closed, otherwise they're all moving from
            // "outside" to "outside" the shape
            //
            // know if we're inside or outside the closed shape when we
            // begin. then only save the intersections that will move us
            // in/out of the shape, and ignore any intersections that
            // don't change in/out
            //
            // this means we need to *ignore* tangents to circles,
            // but may accept tangents to squares if the line
            // is "in" the shape during the tangent
            DKUIBezierPathIntersectionPoint *firstIntersection = [foundIntersections firstObject];
            DKUIBezierPathIntersectionPoint *lastIntersection = [foundIntersections lastObject];
            BOOL isInside = [closedPath containsPoint:self.firstPoint];
            if (isInside && firstIntersection.elementIndex1 != 1 && firstIntersection.tValue1 != 0) {
                // double check that the first line segment is actually inside, and
                // not just tangent at self.firstPoint
                CGFloat firstTValue = firstIntersection.tValue1 / 2;
                CGPoint *bezToUseForNextPoint = firstIntersection.bez1;
                CGPoint locationAfterIntersection = [UIBezierPath pointAtT:firstTValue forBezier:bezToUseForNextPoint];
                isInside = isInside && [closedPath containsPoint:locationAfterIntersection];
            }
            if (beginsInside) {
                *beginsInside = isInside;
            }
            if (lastIntersection == [foundIntersections firstObject]) {
                // make sure not to compare the first and last intersection
                // if they're the same
                lastIntersection = nil;
            }
            for (int i = 0; i < [foundIntersections count]; i++) {
                DKUIBezierPathIntersectionPoint *intersection = [foundIntersections objectAtIndex:i];

                DKUIBezierPathIntersectionPoint *nextIntersection = nil;
                if (i < [foundIntersections count] - 1) {
                    nextIntersection = [foundIntersections objectAtIndex:i + 1];
                }

                CGPoint *bezToUseForNextPoint = intersection.bez1;
                // if the next intersection isn't in the same element, then we
                // can test a point halfway between our intersection and the end
                // of the element to see if we're inside/outside the closed shape
                CGFloat nextTValue = (intersection.tValue1 + 1.0) / 2.0;
                if (nextIntersection && nextIntersection.elementIndex1 == intersection.elementIndex1) {
                    // welp, our next intersection is inside the same element,
                    // so average our intersection points to see if we're inside/
                    // outside the shape
                    nextTValue = (intersection.tValue1 + nextIntersection.tValue1) / 2.0;
                }
                if (nextTValue == intersection.tValue1) {
                    // our "next" value to check is the same as the point we're
                    // already looking at. so look at the next element instead
                    if (nextIntersection) {
                        nextTValue = nextIntersection.tValue1 / 2;
                        bezToUseForNextPoint = nextIntersection.bez1;
                    } else {
                        // no next intersection, check if we have a next element
                        if (intersection.elementIndex1 < [self elementCount] - 1) {
                            nextTValue = 1;
                            // since the next element is entirely within the next segment,
                            // we can just use it as a point bezier
                            CGPathElement ele = [self elementAtIndex:intersection.elementIndex1 + 1];
                            if (ele.type != kCGPathElementCloseSubpath) {
                                bezToUseForNextPoint[0] = ele.points[0];
                                bezToUseForNextPoint[1] = ele.points[0];
                                bezToUseForNextPoint[2] = ele.points[0];
                                bezToUseForNextPoint[3] = ele.points[0];
                            } else {
                                CGPoint p = CGPointZero;
                                CGPathElement ele = [self elementAtIndex:intersection.elementIndex1];
                                if (ele.type == kCGPathElementMoveToPoint || ele.type == kCGPathElementAddLineToPoint) {
                                    p = ele.points[0];
                                } else if (ele.type == kCGPathElementAddQuadCurveToPoint) {
                                    p = ele.points[1];
                                } else if (ele.type == kCGPathElementAddCurveToPoint) {
                                    p = ele.points[2];
                                }
                                bezToUseForNextPoint[0] = p;
                                bezToUseForNextPoint[1] = p;
                                bezToUseForNextPoint[2] = p;
                                bezToUseForNextPoint[3] = p;
                            }
                        }
                    }
                }

                // this will give us a point that comes after the intersection
                // to tell is us if we're inside or outside the shape
                CGPoint locationAfterIntersection = [UIBezierPath pointAtT:nextTValue forBezier:bezToUseForNextPoint];

                // find out if we're inside or outside after this intersection,
                // and if we're at a tangent
                BOOL endsInTangent = NO;
                if (!nextIntersection && intersection.tValue1 == 1 && intersection.elementIndex1 == self.elementCount - 1) {
                    endsInTangent = YES;
                }
                BOOL isInsideAfterIntersection = [closedPath containsPoint:locationAfterIntersection];

                if (!endsInTangent) {
                    // we found an intersection that crosses the boundary of the shape,
                    // so mark it as such
                    intersection.mayCrossBoundary = isInside != isInsideAfterIntersection;
                }

                // setup for next iteration of loop
                lastIntersection = intersection;
                isInside = isInsideAfterIntersection;
            }
        }

        return [foundIntersections copy];
    }

    return [NSArray array];
}


#pragma mark - Segment Finding


/**
 * This method will clip out the intersection and the difference
 * of self compared to the closed path input. This method only
 * clips the segments themselves, it does not
 *
 * IMPORTANT:
 * this method should only be sent single paths without any additional subpaths.
 * otherwise, the returned numberOfIntersectionSegments / numberOfDifferenceSegments
 * will be wrong
 */
- (DKUIBezierPathClippingResult *)clipUnclosedPathToClosedPath:(UIBezierPath *)closedPath usingIntersectionPoints:(NSArray *)intersectionPoints andBeginsInside:(BOOL)beginsInside
{
    __block UIBezierPath *currentIntersectionSegment = [self buildEmptyPath];

    //
    // first, the base case:
    // closed path with 1 or fewer intersections, or no intersections at all
    if (([self isClosed] && [intersectionPoints count] <= 1) || [intersectionPoints count] == 0) {
        DKUIBezierPathClippingResult *ret = nil;
        if ([self isClosed] && [intersectionPoints count] == 1) {
            // single
            DKUIBezierPathIntersectionPoint *onlyIntersection = [intersectionPoints firstObject];

            // goal here is to split the path in half, at the intersection point.
            // portionOfBezierPathStartingAtT0 is from t=0 to t=intersection
            // portionOfBezierPathStartingAtIntersectionPoint is t=intersection to t=end
            UIBezierPath *portionOfBezierPathStartingAtT0 = [self buildEmptyPath];
            UIBezierPath *portionOfBezierPathStartingAtIntersectionPoint = [self buildEmptyPath];
            // as we iterate over the path, we'll add path elements to this path
            __block UIBezierPath *actingPathToAddTo = portionOfBezierPathStartingAtT0;

            __block CGPoint selfPathStartingPoint = self.firstPoint;
            __block CGPoint startingPoint = self.firstPoint;
            [self iteratePathWithBlock:^(CGPathElement element, NSUInteger elementIndex) {
                if (element.type == kCGPathElementMoveToPoint) {
                    selfPathStartingPoint = element.points[0];
                }
                if (elementIndex == onlyIntersection.elementIndex1) {
                    // split on this element
                    CGPoint bez[4];
                    // track our initial bezier curve
                    startingPoint = [UIBezierPath fillCGPoints:bez
                                                   withElement:element
                                     givenElementStartingPoint:startingPoint
                                       andSubPathStartingPoint:selfPathStartingPoint];
                    CGPoint left[4];
                    CGPoint right[4];
                    [UIBezierPath subdivideBezier:bez intoLeft:left andRight:right atT:onlyIntersection.tValue1];
                    // we've split this element into two paths,
                    // one for the left/right of the intersection point.

                    // add the left to our path
                    [actingPathToAddTo addCurveToPoint:left[3] controlPoint1:left[1] controlPoint2:left[2]];
                    // from now on, add all elements to the after intersection path
                    actingPathToAddTo = portionOfBezierPathStartingAtIntersectionPoint;
                    [actingPathToAddTo moveToPoint:right[0]];
                    [actingPathToAddTo addCurveToPoint:right[3] controlPoint1:right[1] controlPoint2:right[2]];
                } else {
                    // the intersection isn't inside this element, so just
                    // add it to our path
                    if (element.type == kCGPathElementCloseSubpath) {
                        // if it's a close element, we need to add it as a line
                        // back to the path starting point. this is because
                        // our new path will have a different starting point, so the
                        // close path would effectivley line-to the wrong point.
                        // we'll explicitly line-to there instead, but only if
                        // our path hasn't already landed at that point.
                        if (!CGPointEqualToPoint(startingPoint, selfPathStartingPoint)) {
                            // dont add a line to a point if we're already at that point
                            [actingPathToAddTo addLineToPoint:selfPathStartingPoint];
                        }
                    } else {
                        [actingPathToAddTo addPathElement:element];
                    }
                }
                if (element.type != kCGPathElementCloseSubpath) {
                    // update our starting point for the next element
                    // TODO: handle close elements as a LineTo the most recent MoveTo
                    startingPoint = element.points[[UIBezierPath numberOfPointsForElement:element] - 1];
                }
            }];

            // we're a closed path, so we need to stay a closed path and
            // begin our loop at the intersection point. so start from the intersection,
            // add add the rest of the path back around to it.
            [portionOfBezierPathStartingAtIntersectionPoint appendPathRemovingInitialMoveToPoint:portionOfBezierPathStartingAtT0];

            //
            // Looking below at the final if statement in this method,
            // we'll swap this clipping result to be an intersection
            // if the path contains the point. for now, we'll just assume
            // difference...
            NSArray *differenceSegments = [NSArray arrayWithObject:[DKUIBezierPathClippedSegment clippedPairWithStart:onlyIntersection
                                                                                                               andEnd:onlyIntersection
                                                                                                       andPathSegment:portionOfBezierPathStartingAtIntersectionPoint
                                                                                                         fromFullPath:self]];
            ret = [[DKUIBezierPathClippingResult alloc] initWithIntersection:[self buildEmptyPath]
                                                                 andSegments:[NSArray array]
                                                               andDifference:[portionOfBezierPathStartingAtIntersectionPoint copy]
                                                                 andSegments:differenceSegments
                                                         andShellIntSegments:0
                                                        andShellDiffSegments:1];


        } else {
            // it's closed or unclosed with 0 intersections
            DKUIBezierUnmatchedPathIntersectionPoint *startOfBlue = [DKUIBezierUnmatchedPathIntersectionPoint intersectionAtElementIndex:0 andTValue:0 withElementIndex:NSNotFound andTValue:0 andElementCount1:self.elementCount andElementCount2:closedPath.elementCount andLengthUntilPath1Loc:self.length andLengthUntilPath2Loc:0];
            DKUIBezierUnmatchedPathIntersectionPoint *endOfBlue = [DKUIBezierUnmatchedPathIntersectionPoint intersectionAtElementIndex:self.elementCount - 1 andTValue:1 withElementIndex:NSNotFound andTValue:0 andElementCount1:self.elementCount andElementCount2:closedPath.elementCount andLengthUntilPath1Loc:self.length andLengthUntilPath2Loc:0];
            NSArray *differenceSegments = [NSArray arrayWithObject:[DKUIBezierPathClippedSegment clippedPairWithStart:startOfBlue
                                                                                                               andEnd:endOfBlue
                                                                                                       andPathSegment:[self copy]
                                                                                                         fromFullPath:self]];
            ret = [[DKUIBezierPathClippingResult alloc] initWithIntersection:[self buildEmptyPath]
                                                                 andSegments:[NSArray array]
                                                               andDifference:[self copy]
                                                                 andSegments:differenceSegments
                                                         andShellIntSegments:0
                                                        andShellDiffSegments:1];
        }
        if ([closedPath isClosed] && ![intersectionPoints count] && [closedPath containsPoint:self.firstPoint]) {
            // above, we built all clipping results as differences. now reverse them to
            // intersections if the path contains the points. this ensures that the
            // difference vs intersection is always correct.
            ret = [[DKUIBezierPathClippingResult alloc] initWithIntersection:ret.entireDifferencePath
                                                                 andSegments:ret.differenceSegments
                                                               andDifference:ret.entireIntersectionPath
                                                                 andSegments:ret.intersectionSegments
                                                         andShellIntSegments:ret.numberOfShellDifferenceSegments
                                                        andShellDiffSegments:ret.numberOfShellIntersectionSegments];
        }

        return ret;
    }

    //
    // from here, it's closed with 2+ intersections, or
    // it's unclosed with 1+ intersections.
    //

    // get the array of all intersections
    NSMutableArray *tValuesOfIntersectionPoints = [NSMutableArray arrayWithArray:intersectionPoints];

    NSMutableArray *originalTValuesOfIntersectionPoints = [tValuesOfIntersectionPoints mutableCopy];
    NSInteger countOfIntersections = [tValuesOfIntersectionPoints count];
    //
    // track special case if we start at an intersection
    BOOL firstIntersectionIsStartOfPath = [[tValuesOfIntersectionPoints firstObject] elementIndex1] == 1 && [[tValuesOfIntersectionPoints firstObject] tValue1] == 0;

    // collect the intersecting and difference segments
    NSMutableArray *intersectionSegments = [NSMutableArray array];
    NSMutableArray *differenceSegments = [NSMutableArray array];

    // during our algorithm, we'll always add to the intersection
    // and not the difference. whenever we hit an intersection, we'll
    // just swap the intersection/difference pointers so that we'll
    // continually toggle which array we're adding to.
    __block NSMutableArray *actingintersectionSegments = intersectionSegments;
    __block NSMutableArray *actingdifferenceSegments = differenceSegments;

    CGPoint firstPoint = self.firstPoint;
    if (![closedPath containsPoint:firstPoint] || !beginsInside || ![closedPath isClosed]) {
        // if we're starting outside the closedPath,
        // the init our paths to the correct side
        // so our output will be a proper intersection
        // vs difference
        actingintersectionSegments = differenceSegments;
        actingdifferenceSegments = intersectionSegments;
    }

    NSMutableArray *firstIntersectionSegments = actingintersectionSegments;

    // most recent tValue that we've looked at as we traverse over the path. begin with the start point
    __block DKUIBezierPathIntersectionPoint *lastTValue = nil;
    DKUIBezierPathIntersectionPoint *firstTValue = [originalTValuesOfIntersectionPoints firstObject];
    if ([self isClosed]) {
        // if we're closed, then the last intersection we've looked at
        // is the last intersection in the path. from there, it loops
        // around back through the start of the path
        lastTValue = [originalTValuesOfIntersectionPoints lastObject];
    } else {
        // of unclosed paths, the "most recent" intersection is the non-intersection
        // of the start of the path. not sure why we're not using firstIntersectionIsStartOfPath
        lastTValue = [DKUIBezierUnmatchedPathIntersectionPoint intersectionAtElementIndex:0 andTValue:0 withElementIndex:NSNotFound andTValue:0 andElementCount1:self.elementCount andElementCount2:closedPath.elementCount andLengthUntilPath1Loc:0 andLengthUntilPath2Loc:0];
    }
    if (firstTValue.elementIndex1 == 1 && firstTValue.tValue1 == 0) {
        // we start on an intersection, so use this as the "last"
        // tvalue, so that it will begin the first segment.
        lastTValue = firstTValue;
    }


    // the last point is always the end of the path

    DKUIBezierUnmatchedPathIntersectionPoint *endOfTheLine = [DKUIBezierUnmatchedPathIntersectionPoint intersectionAtElementIndex:self.elementCount - 1 andTValue:1 withElementIndex:NSNotFound andTValue:0 andElementCount1:self.elementCount andElementCount2:closedPath.elementCount andLengthUntilPath1Loc:self.length andLengthUntilPath2Loc:0];

    CGPoint selfPathStartingPoint = self.firstPoint;

    __block BOOL closedPathIsPoint = NO;

    __block BOOL lastElementIsClosePath = NO;
    __block CGPoint startingPoint = CGPointNotFound;
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentElementIndex) {
        if (![tValuesOfIntersectionPoints count] || currentElementIndex != [[tValuesOfIntersectionPoints firstObject] elementIndex1]) {
            // no intersection between these two elements, so add the
            // element to the output
            if (element.type == kCGPathElementCloseSubpath) {
                if (CGPointEqualToPoint(currentIntersectionSegment.lastPoint, self.firstPoint)) {
                    // track if the closePathElement actually gives us a line segment,
                    // or if the rest of the path was already visually closed
                    closedPathIsPoint = YES;
                }
                // TODO: future optimization here would be to skip the line-to
                // if the path is already at the self.firstPoint...
                [currentIntersectionSegment addLineToPoint:self.firstPoint];
                if (currentElementIndex == self.elementCount - 1) {
                    lastElementIsClosePath = YES;
                }
            } else {
                // no intersection, just add the element
                [currentIntersectionSegment addPathElement:element];
            }
        } else {
            // they intersect, so this will change our intersection vs difference.
            // also, we may have multiple intersections inside the same element, so
            // we'll handle that too

            CGPoint bez[4];
            // track our initial bezier curve
            startingPoint = [UIBezierPath fillCGPoints:bez
                                           withElement:element
                             givenElementStartingPoint:startingPoint
                               andSubPathStartingPoint:selfPathStartingPoint];

            BOOL hasRight = YES;
            while ([[tValuesOfIntersectionPoints firstObject] elementIndex1] == currentElementIndex) {
                // get the T-value of the intersection in self's element.
                // if this element had been split before, then this tValue may
                // have been adjust from the origin tvalue intersection
                CGFloat tValue = [[tValuesOfIntersectionPoints firstObject] tValue1];
                if (tValue == 1) {
                    hasRight = NO;
                }

                // split us into left/right
                CGPoint left[4];
                CGPoint right[4];
                [UIBezierPath subdivideBezier:bez intoLeft:left andRight:right atT:tValue];

                // add the path element to the intersection
                if (tValue > 0) {
                    // if the tValue is 0, then the intersection really happened at the
                    // end of the last element, so we don't need to add a curve to a single point
                    // here. instead just skip it and only add a curve that has a size larger
                    // than a single point.
                    if (element.type != kCGPathElementAddLineToPoint && element.type != kCGPathElementCloseSubpath) {
                        [currentIntersectionSegment addCurveToPoint:left[3] controlPoint1:left[1] controlPoint2:left[2]];
                    } else {
                        [currentIntersectionSegment addLineToPoint:left[3]];
                    }
                }

                // currTValue is always the unadjusted tvalue of the intersection
                // between the curves
                DKUIBezierPathIntersectionPoint *currTValue = [originalTValuesOfIntersectionPoints objectAtIndex:0];
                if (currTValue != lastTValue) {
                    // just in case the first intersection is exactly
                    // on a boundary, then we'll want to skip creating a segment
                    // that is exactly 1 px large (distance of 0)
                    [actingintersectionSegments addObject:[DKUIBezierPathClippedSegment clippedPairWithStart:lastTValue
                                                                                                      andEnd:currTValue
                                                                                              andPathSegment:currentIntersectionSegment
                                                                                                fromFullPath:self]];
                }
                lastTValue = currTValue;
                if ([[tValuesOfIntersectionPoints firstObject] mayCrossBoundary]) {
                    // this intersection causes a boundary crossing, so switch
                    // our intersection and difference
                    // swap inside/outside
                    NSMutableArray *swap = actingintersectionSegments;
                    actingintersectionSegments = actingdifferenceSegments;
                    actingdifferenceSegments = swap;
                } else {
                    // the intersection does not cross the boundary of the
                    // shape
                }
                if (hasRight || currentElementIndex != self.elementCount - 1) {
                    // don't add the trailing moveTo if there won't
                    // be any more segments to add to it
                    currentIntersectionSegment = [self buildEmptyPath];
                    [currentIntersectionSegment moveToPoint:left[3]];
                }


                // now remove this intersection since it's been
                // processed. as we loop back around the while loop
                // this'll let us continually use the [tValuesOfIntersectionPoints firstObject]
                // to process through all intersections in this element.
                [tValuesOfIntersectionPoints removeObjectAtIndex:0];
                [originalTValuesOfIntersectionPoints removeObjectAtIndex:0];

                // and scale the remaining intersection
                // T values for this element index.
                // we've essentially cut the element in half,
                // so the old intersection T values need to be
                // scaled to the new element's size
                for (int i = 0; i < [tValuesOfIntersectionPoints count]; i++) {
                    DKUIBezierPathIntersectionPoint *oldInter = [tValuesOfIntersectionPoints objectAtIndex:i];
                    if ([oldInter elementIndex1] == currentElementIndex) {
                        // this intersection matches the current element that
                        // we just split, so adjust it's T values
                        CGFloat oldT = [oldInter tValue1];
                        CGFloat adjustedTValue = (oldT - tValue) / (1.0 - tValue);
                        if (oldT == 1 || oldT == 0) {
                            // save if its on a boundary for rounding error
                            adjustedTValue = oldT;
                        }
                        // create a new intersection, and replace it in the array
                        DKUIBezierPathIntersectionPoint *newInter = [DKUIBezierPathIntersectionPoint intersectionAtElementIndex:oldInter.elementIndex1
                                                                                                                      andTValue:adjustedTValue
                                                                                                               withElementIndex:oldInter.elementIndex2
                                                                                                                      andTValue:oldInter.tValue2
                                                                                                               andElementCount1:oldInter.elementIndex1
                                                                                                               andElementCount2:oldInter.elementIndex2
                                                                                                         andLengthUntilPath1Loc:oldInter.lenAtInter1
                                                                                                         andLengthUntilPath2Loc:oldInter.lenAtInter2];
                        [newInter setMayCrossBoundary:oldInter.mayCrossBoundary];
                        newInter.pathLength1 = oldInter.pathLength1;
                        newInter.pathLength2 = oldInter.pathLength2;
                        [tValuesOfIntersectionPoints replaceObjectAtIndex:i withObject:newInter];
                    }
                }

                // now move us over to the right side of what we just chopped
                // and loop to deal with this half (if needed).
                // if this was the last intersection in this element, then
                // the loop will exit and we'll deal w/ the right half of the
                // split below.
                bez[0] = right[0];
                bez[1] = right[1];
                bez[2] = right[2];
                bez[3] = right[3];
            }
            // if the intersection was at t=1, then there is
            // no righthand side to add to the intersection,
            // so just skip past adding a curve element
            if (hasRight) {
                // ok, we've processed all intersections for this element,
                // now add what's left of this element to the curve
                // TODO: what happens if the element intersects at the end of the element at T = 1?
                if (element.type != kCGPathElementAddLineToPoint && element.type != kCGPathElementCloseSubpath) {
                    [currentIntersectionSegment addCurveToPoint:bez[3] controlPoint1:bez[1] controlPoint2:bez[2]];
                } else {
                    [currentIntersectionSegment addLineToPoint:bez[3]];
                }
                // and now loop back around to the next element and begin
                // the process all over for the rest of the path.
            }
        }

        if (element.type != kCGPathElementCloseSubpath) {
            // update our starting point for the next element
            // NOTE: we don't handle close subpaths / move-to's and
            // resetting the startpoint because this method only
            // handles paths with a single subpath. multiple subpaths
            // are not supported here. use redAndGreenAndBlueSegmentsCreatedFrom
            // or similar instead for multiple subpaths.
            startingPoint = element.points[[UIBezierPath numberOfPointsForElement:element] - 1];
        }
    }];


    if (lastTValue.tValue1 == 1 && ((closedPathIsPoint && lastElementIsClosePath && lastTValue.elementIndex1 == self.elementCount - 2) ||
                                    (!lastElementIsClosePath && lastTValue.elementIndex1 == self.elementCount - 1))) {
        // the last intersection is at the very very end of the curve,
        // so we've already added the appropriate segment for it. there's
        // nothing left on the right hand side of the intersection to use
        // as another segment
    } else if (![self isClosed] || (countOfIntersections <= 2 && firstIntersectionIsStartOfPath)) {
        // if the path is closed, then section of the curve from the last intersection
        // wrapped to the first intersection has already been added to the first segment
        // so only add this last segment if it's not closed
        [actingintersectionSegments addObject:[DKUIBezierPathClippedSegment clippedPairWithStart:lastTValue
                                                                                          andEnd:endOfTheLine
                                                                                  andPathSegment:currentIntersectionSegment
                                                                                    fromFullPath:self]];
    } else if ([self isClosed]) {
        // if we're closed, then the last loops around
        // through the first - they're actually the same segment.
        // this will merge the two segments and replace them in our output.
        if ([firstIntersectionSegments count]) {
            DKUIBezierPathClippedSegment *firstSeg = [firstIntersectionSegments firstObject];
            [currentIntersectionSegment appendPathRemovingInitialMoveToPoint:firstSeg.pathSegment];
            DKUIBezierPathClippedSegment *newSeg = [DKUIBezierPathClippedSegment clippedPairWithStart:firstSeg.startIntersection
                                                                                               andEnd:firstSeg.endIntersection
                                                                                       andPathSegment:currentIntersectionSegment
                                                                                         fromFullPath:firstSeg.fullPath];
            [firstIntersectionSegments replaceObjectAtIndex:0 withObject:newSeg];
        }
    }

    // now calculate the full intersection and difference paths
    UIBezierPath *intersection = [self buildEmptyPath];
    UIBezierPath *difference = [self buildEmptyPath];
    for (DKUIBezierPathClippedSegment *seg in intersectionSegments) {
        if ([seg.pathSegment elementCount] > 1) {
            [intersection appendPath:seg.pathSegment];
        }
    }
    for (DKUIBezierPathClippedSegment *seg in differenceSegments) {
        if ([seg.pathSegment elementCount] > 1) {
            [difference appendPath:seg.pathSegment];
        }
    }

    return [[DKUIBezierPathClippingResult alloc] initWithIntersection:intersection
                                                          andSegments:intersectionSegments
                                                        andDifference:difference
                                                          andSegments:differenceSegments
                                                  andShellIntSegments:[intersectionSegments count]
                                                 andShellDiffSegments:[differenceSegments count]];
}


/**
 * this will calculate the red and green segments for a path, and will respect and account for all
 * subpaths in the input scissor path
 *
 * since this method may be called from both sides of a cut - ie, using the shape as scissor and vice versa
 * it needs to accept the intersections as input so that they're used exactly the same for both cuts
 */
+ (DKUIBezierPathClippingResult *)redAndGreenSegmentsCreatedFrom:(UIBezierPath *)shapePath bySlicingWithPath:(UIBezierPath *)scissorPath withIntersections:(NSArray *)_scissorToShapeIntersections
{
    // We'll clip twice, once clipping by the scissors to get the intersection/difference of the
    // scissor path compared to the shape
    NSMutableArray *scissorToShapeIntersections = [NSMutableArray arrayWithArray:_scissorToShapeIntersections];

    //
    // these will track the full intersection and difference
    // objects used to generate a full DKUIBezierPathClippingResult
    // over the entire scissor path, not just each subpath
    UIBezierPath *entireScissorIntersection = [scissorPath buildEmptyPath];
    UIBezierPath *entireScissorDifference = [scissorPath buildEmptyPath];
    NSMutableArray *intersectionSegments = [NSMutableArray array];
    NSMutableArray *differenceSegments = [NSMutableArray array];

    //
    // if the scissor is sent in with multiple subpaths,
    // then we need to determine it's intersection and difference
    // for each subpath individually.
    //
    // as we iterate through the subpaths, we'll clip each subpath
    // individually, and then update the resulting segments
    // with the correct full path intersection object
    //
    // track all of the intersections that are used when clipping
    // with subpaths. we'll use this array to map subpath intersections
    // to full path intersections
    NSMutableArray *allSubpathToShapeIntersections = [NSMutableArray array];
    NSUInteger elementCountForPreviousSubpaths = 0;
    CGFloat pathLengthForPreviousSubpaths = 0;
    //
    // as we iterate over the subpaths, if an intersection point represents a non-intersection,
    // then we need to adjust that as well to show the correct element count
    DKUIBezierPathIntersectionPoint * (^adjustedNonIntersection)(DKUIBezierPathIntersectionPoint *inter) =
        ^DKUIBezierPathIntersectionPoint *(DKUIBezierPathIntersectionPoint *inter)
    {
        // this block will accept an intersection, and will return a new intersection that has
        // adjusted the elementCount and lenAtInter1 to reflect all previous subpaths so far
        //
        // this is useful when manually adjusting for unmatched intersections that do not appear in
        // scissorToShapeIntersections, and so cannot be simply mapped to
        DKUIBezierPathIntersectionPoint *ret = [DKUIBezierUnmatchedPathIntersectionPoint intersectionAtElementIndex:inter.elementIndex1 + elementCountForPreviousSubpaths
                                                                                                          andTValue:inter.tValue1
                                                                                                   withElementIndex:inter.elementIndex2
                                                                                                          andTValue:inter.tValue2
                                                                                                   andElementCount1:[scissorPath elementCount]
                                                                                                   andElementCount2:inter.elementCount2
                                                                                             andLengthUntilPath1Loc:inter.lenAtInter1 + pathLengthForPreviousSubpaths
                                                                                             andLengthUntilPath2Loc:inter.lenAtInter2];
        ret.bez1[0] = inter.bez1[0];
        ret.bez1[1] = inter.bez1[1];
        ret.bez1[2] = inter.bez1[2];
        ret.bez1[3] = inter.bez1[3];
        ret.bez2[0] = inter.bez2[0];
        ret.bez2[1] = inter.bez2[1];
        ret.bez2[2] = inter.bez2[2];
        ret.bez2[3] = inter.bez2[3];
        ret.mayCrossBoundary = inter.mayCrossBoundary;
        ret.pathLength1 = [scissorPath length];
        ret.pathLength2 = inter.pathLength2;
        return ret;
    };
    DKUIBezierPathClippedSegment * (^adjustNonIntersectionPointForSegment)(DKUIBezierPathClippedSegment *) =
        ^DKUIBezierPathClippedSegment *(DKUIBezierPathClippedSegment *seg)
    {
        // this block will inspect the input segment and determine if
        // either of its intersections represent a non-intersection with the shape.
        //
        // if so, it will adjust those intersection objects to reflect the
        // subpath location in the complete scissor path, and will return
        // a properly adjusted segment
        DKUIBezierPathIntersectionPoint *altStartInter = nil;
        DKUIBezierPathIntersectionPoint *altEndInter = nil;
        if ([seg.startIntersection isKindOfClass:[DKUIBezierUnmatchedPathIntersectionPoint class]]) {
            altStartInter = adjustedNonIntersection(seg.startIntersection);
        }
        if ([seg.endIntersection isKindOfClass:[DKUIBezierUnmatchedPathIntersectionPoint class]]) {
            altEndInter = adjustedNonIntersection(seg.endIntersection);
        }

        if (altStartInter || altEndInter) {
            return [DKUIBezierPathClippedSegment clippedPairWithStart:altStartInter ? altStartInter : seg.startIntersection
                                                               andEnd:altEndInter ? altEndInter : seg.endIntersection
                                                       andPathSegment:seg.pathSegment
                                                         fromFullPath:scissorPath];
        }
        return seg;
    };


    NSUInteger numberOfShellIntersectionSegments = 0;
    NSUInteger numberOfShellDifferenceSegments = 0;
    BOOL hasCountedShellSegments = NO;
    //
    // for all subpaths in the scissors, clip each subpath to the shape
    // and be sure to adjust all intersection points to map directly to the
    // overall scissor path instead of just the subpath.
    for (UIBezierPath *subScissors in [scissorPath subPaths]) {
        BOOL beginsInside1_alt = NO;
        // find intersections within only this subpath
        NSMutableArray *subpathToShapeIntersections = [NSMutableArray arrayWithArray:[subScissors findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside1_alt]];
        // find all segments for only this subpath
        DKUIBezierPathClippingResult *subpathClippingResult = [subScissors clipUnclosedPathToClosedPath:shapePath usingIntersectionPoints:subpathToShapeIntersections andBeginsInside:beginsInside1_alt];

        // track our subpath intersections, so that we can map
        // them back to full path intersections
        [allSubpathToShapeIntersections addObjectsFromArray:subpathToShapeIntersections];
        // update the entire difference/intersection paths
        [entireScissorIntersection appendPath:subpathClippingResult.entireIntersectionPath];
        [entireScissorDifference appendPath:subpathClippingResult.entireDifferencePath];

        // and track the segments for this subpath.
        // we'll update the segment intersections after this loop
        for (DKUIBezierPathClippedSegment *seg in subpathClippingResult.intersectionSegments) {
            [intersectionSegments addObject:adjustNonIntersectionPointForSegment(seg)];
        }
        for (DKUIBezierPathClippedSegment *seg in subpathClippingResult.differenceSegments) {
            [differenceSegments addObject:adjustNonIntersectionPointForSegment(seg)];
        }

        // track where we are in the context of the full path.
        // this is useful for adjusting non-matching intersection points
        elementCountForPreviousSubpaths += [subScissors elementCount];
        pathLengthForPreviousSubpaths += [subScissors length];
        if (!hasCountedShellSegments) {
            numberOfShellIntersectionSegments = [intersectionSegments count];
            numberOfShellDifferenceSegments = [differenceSegments count];
            hasCountedShellSegments = YES;
        }
    }

    //
    // at this point, we have the correct entireScissorIntersection and entireScissorDifference,
    // and we can also map the subpath intersection objects to full path intersection objects.
    //
    // next, we need to update the segments so that each segment has the correct fullpath intersection
    // object to work with
    NSMutableArray *correctedIntersectionSegments = [NSMutableArray array];
    NSMutableArray *correctedDifferenceSegments = [NSMutableArray array];

    // It's possible for allSubpathToShapeIntersections to be offset from scissorToShapeIntersections
    // if an intersection point maps to the very beginning of a closed path, it could be represented by
    // the start of the moveTo, start of the element after the move to, end of the move to, or end
    // of the closePath, or beginning of the close path if the path otherwise ended on the start point.
    // to rectify this, align the indexes of allSubpathToShapeIntersections and scissorToShapeIntersections
    for (NSInteger i = 0; i < [allSubpathToShapeIntersections count]; i++) {
        DKUIBezierPathIntersectionPoint *inter = allSubpathToShapeIntersections[i];
        NSInteger stsindex = [scissorToShapeIntersections indexOfObject:inter];
        if (stsindex != NSNotFound && stsindex != i) {
            // align the indexes
            [allSubpathToShapeIntersections addObjectsFromArray:[allSubpathToShapeIntersections subarrayWithRange:NSMakeRange(0, i)]];
            [allSubpathToShapeIntersections removeObjectsInRange:NSMakeRange(0, i)];

            [scissorToShapeIntersections addObjectsFromArray:[scissorToShapeIntersections subarrayWithRange:NSMakeRange(0, stsindex)]];
            [scissorToShapeIntersections removeObjectsInRange:NSMakeRange(0, stsindex)];

            break;
        }
    }

    //
    // now, all of the intersectionSegments and differenceSegments are correct
    // for their respective subpaths. we need to create new segment objects
    // to represent these segments that will adjust them into the full path's
    // list of intersections.
    void (^fixSegmentIntersections)(NSArray *, NSMutableArray *) = ^(NSArray *segmentsToFix, NSMutableArray *output) {
        for (DKUIBezierPathClippedSegment *seg in segmentsToFix) {
            NSUInteger indx;
            DKUIBezierPathIntersectionPoint *correctedStartIntersection = seg.startIntersection;
            indx = [allSubpathToShapeIntersections indexOfObject:seg.startIntersection];
            if (indx != NSNotFound) {
                // we found an intersection in the full scissor path that we can map to,
                // so use that for the start
                correctedStartIntersection = [scissorToShapeIntersections objectAtIndex:indx];
            }
            DKUIBezierPathIntersectionPoint *correctedEndIntersection = seg.endIntersection;
            indx = [allSubpathToShapeIntersections indexOfObject:seg.endIntersection];
            if (indx != NSNotFound) {
                // we found an intersection in the full scissor path that we can map to,
                // so use that for the end
                correctedEndIntersection = [scissorToShapeIntersections objectAtIndex:indx];
            }
            // now, create a new segment that is in relation to the full scissor path instead
            // of just the scissor subpath
            DKUIBezierPathClippedSegment *correctedSeg = [DKUIBezierPathClippedSegment clippedPairWithStart:correctedStartIntersection
                                                                                                     andEnd:correctedEndIntersection
                                                                                             andPathSegment:seg.pathSegment
                                                                                               fromFullPath:scissorPath];
            [output addObject:correctedSeg];
        }
    };

    // adjust the segments into the full path's intersection list
    fixSegmentIntersections(intersectionSegments, correctedIntersectionSegments);
    fixSegmentIntersections(differenceSegments, correctedDifferenceSegments);

    // at this point, we have our full intersection information for the scissors.
    // so we'll manually regenerate the full clipping result across all subpaths
    DKUIBezierPathClippingResult *clipped1 = [[DKUIBezierPathClippingResult alloc] initWithIntersection:entireScissorIntersection
                                                                                            andSegments:correctedIntersectionSegments
                                                                                          andDifference:entireScissorDifference
                                                                                            andSegments:correctedDifferenceSegments
                                                                                    andShellIntSegments:numberOfShellIntersectionSegments
                                                                                   andShellDiffSegments:numberOfShellDifferenceSegments];
    return clipped1;
}

//
// the scissor segments we'll call "red", and the shape segments we'll call "blue"
//
// to find new shapes from cutting with the scissors, the algorithm is:
//
// 1. first, we'll loop the rest of the algorith over each red segment:
// 2. with the input red or blue segment (always red to start, might be blue during the loop)
//     - if it's a red segment, find all blue + red segments that could attach to it's end point.
//     - if it's a blue segment, find all red segments that could attach to it's end point. (not blue!)
// 3. find the segment that would be the sharpest "left" turn, travelling from the
//    start of the red segment -> its end point-> onto the red/ blue segment that attaches.
// $. continue from the furthest left segment, and loop back to #3

//
// by starting with each red segment, and following a left-hand rule (like traversing through
// a maze) back to the starting segment, we'll build up new shapes.
//
// since some shapes may have multiple red segments in them, they will show up multiple times
// in our output of shapes, so we'll also need to filter out duplicates.
+ (NSArray *)redAndGreenAndBlueSegmentsCreatedFrom:(UIBezierPath *)shapePath bySlicingWithPath:(UIBezierPath *)scissorPath andNumberOfBlueShellSegments:(NSUInteger *)numberOfBlueShellSegments
{
    // find the intersections between the two paths. these will be the definitive intersection points,
    // no matter which way we clip the paths later on. if we clip shape to scissors, or scissor to shape,
    // we'll use these same intersections (properly adjusted for each cut).
    NSArray *scissorToShapeIntersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];

    // so our first step is to create arrays of both the red and blue segments.
    //
    // first, find the red segments (scissor intersection with the shape), and connect
    // it's end to its start, if possible.
    DKUIBezierPathClippingResult *clipped1 = [UIBezierPath redAndGreenSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath withIntersections:scissorToShapeIntersections];
    NSMutableArray *redSegments = [NSMutableArray arrayWithArray:clipped1.intersectionSegments];
    NSMutableArray *greenSegments = [NSMutableArray arrayWithArray:clipped1.differenceSegments];


    //
    // now work on the blue segments:

    //
    // in order for all of this to work, the intersections from the red/green need to be
    // re-used as we cut up the blue segments. to do this, we need to:
    // 1. flip all the intersections
    // 2. sort them so that they match the order we would have got if we'd found new intersections
    // 3. reset the mayCrossBoundary flag to match the path order we're cutting with

    // just find if it begins inside, but we'll throw away the intersections for now,
    // because we're going to reuse and resort the tValuesOfIntersectionPoints1.
    // this solves rounding error that happens when intersections generate slightly differently
    // depending on the order of paths sent in
    NSArray *intersectionsWithBoundaryInformation = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];
    //
    // this array will be the intersections between the shape and the scissor.
    // we'll use the exact same intersection objects (flipped, b/c we're attacking from
    // the shape v scissor instead of vice versa). We'll need to order them and
    // set the mayCrossBoundary so that the final array will appear as if it came
    // directly from [shapePath findIntersectionsWithClosedPath:scissorPath...]
    NSMutableArray *shapeToScissorIntersections = [NSMutableArray array];
    // 1. flip
    [scissorToShapeIntersections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [shapeToScissorIntersections addObject:[obj flipped]];
    }];
    // 2. sort
    [shapeToScissorIntersections sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 elementIndex1] < [obj2 elementIndex1]) {
            return NSOrderedAscending;
        } else if ([obj1 elementIndex1] == [obj2 elementIndex1] &&
                   [obj1 tValue1] < [obj2 tValue1]) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];

    if ([shapeToScissorIntersections count] != [intersectionsWithBoundaryInformation count]) {
        @throw [NSException exceptionWithName:@"BezierPathIntersectionException" reason:@"mismatched intersection length" userInfo:nil];
    }
    // 3. fix mayCrossBoundary:
    for (int i = 0; i < [intersectionsWithBoundaryInformation count]; i++) {
        [[shapeToScissorIntersections objectAtIndex:i] setMayCrossBoundary:[[intersectionsWithBoundaryInformation objectAtIndex:i] mayCrossBoundary]];
    }

    //
    // now we can clip the shape and scissor with essentially the same intersection points
    DKUIBezierPathClippingResult *clipped2 = [UIBezierPath redAndGreenSegmentsCreatedFrom:scissorPath bySlicingWithPath:shapePath withIntersections:shapeToScissorIntersections];

    //
    // this output (clipped1 and clipped2) give us the Segment objects for both the scissors and
    // the shape.
    // first check the blue intersection for it's end/start to combine
    NSArray *blueIntersectionSegments = clipped2.intersectionSegments;
    // next, check the blue difference to see if it's end and start should be connected
    NSArray *blueDifferenceSegments = clipped2.differenceSegments;
    // for the blue segments, we need to use both the intersection and difference,
    // so combine them into a single array of blue segments.
    NSMutableArray *blueSegments = [NSMutableArray array];

    // shell segments first!
    [blueSegments addObjectsFromArray:[blueIntersectionSegments subarrayWithRange:NSMakeRange(0, clipped2.numberOfShellIntersectionSegments)]];
    [blueSegments addObjectsFromArray:[blueDifferenceSegments subarrayWithRange:NSMakeRange(0, clipped2.numberOfShellDifferenceSegments)]];

    // non-shell next
    if (clipped2.numberOfShellIntersectionSegments < [blueIntersectionSegments count]) {
        [blueSegments addObjectsFromArray:[blueIntersectionSegments subarrayWithRange:NSMakeRange(clipped2.numberOfShellIntersectionSegments,
                                                                                                  [blueIntersectionSegments count] - clipped2.numberOfShellIntersectionSegments)]];
    }
    if (clipped2.numberOfShellDifferenceSegments < [blueDifferenceSegments count]) {
        [blueSegments addObjectsFromArray:[blueDifferenceSegments subarrayWithRange:NSMakeRange(clipped2.numberOfShellDifferenceSegments,
                                                                                                [blueDifferenceSegments count] - clipped2.numberOfShellDifferenceSegments)]];
    }

    if (numberOfBlueShellSegments) {
        numberOfBlueShellSegments[0] = clipped2.numberOfShellDifferenceSegments + clipped2.numberOfShellIntersectionSegments;
    }

    return [NSArray arrayWithObjects:redSegments, greenSegments, blueSegments, nil];
}


/**
 * The input shapePath bezier curve will be split into pieces, as if cut with scissors, by the
 * input scissor path.
 *
 * the result will specify whether each resulting smaller shape would be an intersection or
 * difference with the input scissorPath (if closed). If scissor path is open, then the
 * output will be considered entirely difference.
 *
 * IMPORTANT:
 *
 * red segment intersections have the element1 and tValue1 to be the /scissor/ element/tvalue
 * blue segment intersections have the element1 and tValue1 to be the /shape/ element/tvalue
 *
 * this means, that to compare start and end intersections between a red and blue, either the
 * red or blue segment's intersection should be flipped (to fit the red or blue side) so that
 * they compare the correct path's values.
 */
+ (NSArray *)redAndBlueSegmentsForShapeBuildingCreatedFrom:(UIBezierPath *)shapePath bySlicingWithPath:(UIBezierPath *)scissorPath andNumberOfBlueShellSegments:(NSUInteger *)numberOfBlueShellSegments
{
    NSArray *redGreenAndBlueSegments = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:numberOfBlueShellSegments];

    NSMutableArray<DKUIBezierPathClippedSegment *> *redSegments = [NSMutableArray arrayWithArray:[redGreenAndBlueSegments firstObject]];
    NSMutableArray<DKUIBezierPathClippedSegment *> *blueSegments = [NSMutableArray arrayWithArray:[redGreenAndBlueSegments lastObject]];

    //
    // filter out any red segments that have unmatched endpoints.
    // this means the segment started/ended inside the shape and not
    // at an intersection point
    [redSegments filterUsingPredicate:[NSPredicate predicateWithBlock:^(id seg, NSDictionary *bindings) {
        return (BOOL) !([[seg startIntersection] isKindOfClass:[DKUIBezierUnmatchedPathIntersectionPoint class]] ||
                        [[seg endIntersection] isKindOfClass:[DKUIBezierUnmatchedPathIntersectionPoint class]]);
    }]];

    if ([scissorPath isClosed] && ![redSegments count]) {
        // if we just filtered out cutting a hole in a path,
        // then re-add those unmatched segments back in
        [redSegments addObjectsFromArray:[redGreenAndBlueSegments firstObject]];
    }

    // track all of the intersections that the red segments use
    NSMutableSet *redIntersections = [NSMutableSet set];
    [redSegments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [redIntersections addObject:[obj startIntersection]];
        [redIntersections addObject:[obj endIntersection]];
    }];
    NSMutableArray *blueSegmentsThatIntersectWithRedSegments = [NSMutableArray array];
    for (int i = 0; i < [blueSegments count]; i++) {
        DKUIBezierPathClippedSegment *currBlueSeg = [blueSegments objectAtIndex:i];
        // if the blue segment's intersection isn't in the list of
        // red segments intersections, then that means that it intersects
        // one of the redsegments that had an unmatched intersection point.
        // this blue segment should be merged with its adjacent blue segment
        NSSet *matchedIntersections = [redIntersections objectsPassingTest:^(id obj, BOOL *stop) {
            for (int j = 0; j < [redIntersections count]; j++) {
                if ([[[currBlueSeg endIntersection] flipped] isEqualToIntersection:obj]) {
                    return YES;
                }
            }
            return NO;
        }];
        if ([matchedIntersections count] < 1) {
            // we know that the end intersection did not match,
            // so find the other blue segment whose start intersection
            // does not match
            for (int j = 0; j < [blueSegments count]; j++) {
                DKUIBezierPathClippedSegment *possibleMatchedBlueSeg = [blueSegments objectAtIndex:j];
                if ([possibleMatchedBlueSeg.startIntersection isEqualToIntersection:currBlueSeg.endIntersection] &&
                    possibleMatchedBlueSeg != currBlueSeg) {
                    // merge the two segments
                    UIBezierPath *newPathSegment = currBlueSeg.pathSegment;
                    [newPathSegment appendPathRemovingInitialMoveToPoint:possibleMatchedBlueSeg.pathSegment];

                    DKUIBezierPathClippedSegment *newBlueSeg = [DKUIBezierPathClippedSegment clippedPairWithStart:currBlueSeg.startIntersection
                                                                                                           andEnd:possibleMatchedBlueSeg.endIntersection
                                                                                                   andPathSegment:newPathSegment
                                                                                                     fromFullPath:currBlueSeg.fullPath];
                    [blueSegments replaceObjectAtIndex:i withObject:newBlueSeg];
                    [blueSegments removeObject:possibleMatchedBlueSeg];
                    if (numberOfBlueShellSegments) {
                        if (i < numberOfBlueShellSegments[0]) {
                            // the merged segments were in the shell, so we need to adjust that
                            // number to reflect the newly merged segments
                            numberOfBlueShellSegments[0]--;
                        }
                    }
                    i--;
                    break;
                }
            }
        } else {
            [blueSegmentsThatIntersectWithRedSegments addObject:currBlueSeg];
        }
    }

    //
    // now add all of the reverse of our segments to our output
    // so we can approach shape building from either direction
    NSMutableArray *redSegmentsLeftToUse = [NSMutableArray arrayWithArray:redSegments];
    NSMutableArray *blueSegmentsLeftToUse = [NSMutableArray arrayWithArray:blueSegments];
    [redSegments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [redSegmentsLeftToUse addObject:[obj reversedSegment]];
    }];
    //    [blueSegments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
    //        [blueSegmentsLeftToUse addObject:[obj reversedSegment]];
    //    }];

    return [NSArray arrayWithObjects:redSegmentsLeftToUse, blueSegmentsLeftToUse, nil];
}


#pragma mark - Shape Building

/**
 * when clipping an unclosed path through a closed path,
 * we will iterate across each of the closed subpaths individually
 * to find the new subclosed paths
 *
 * need to handle this better:
 * https://github.com/adamwulf/loose-leaf/issues/295
 */
- (NSArray<NSArray<DKUIBezierPathShape *> *> *)shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:(UIBezierPath *)scissorPath
{
    // return @[ array_of_shells, array_of_holes ]
    return [UIBezierPath subshapesCreatedFrom:self bySlicingWithPath:scissorPath];
}


/**
 * returns only unique subshapes, removing duplicates
 */
- (NSArray<NSArray<DKUIBezierPathShape *> *> *)uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:(UIBezierPath *)scissorPath
{
    NSArray *shapeShellsAndSubShapes = [self shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray *shapeShells = [shapeShellsAndSubShapes firstObject];
    NSArray *subShapes = [shapeShellsAndSubShapes lastObject];

    NSArray * (^deduplicateShapes)(NSArray *inter) = ^NSArray *(NSArray *shapes)
    {
        NSMutableArray *uniquePaths = [NSMutableArray array];
        for (DKUIBezierPathShape *possibleDuplicate in shapes) {
            if ([possibleDuplicate isClosed]) {
                // ignore unclosed shapes
                BOOL foundDuplicate = NO;
                for (DKUIBezierPathShape *uniqueShape in uniquePaths) {
                    if ([uniqueShape isSameShapeAs:possibleDuplicate]) {
                        foundDuplicate = YES;
                        break;
                    }
                }
                if (!foundDuplicate) {
                    [uniquePaths addObject:possibleDuplicate];
                }
            }
        }
        return uniquePaths;
    };

    shapeShells = deduplicateShapes(shapeShells);
    subShapes = deduplicateShapes(subShapes);

    return @[shapeShells, subShapes];
}


/**
 * returns only unique subshapes, removing duplicates
 */
- (NSArray<DKUIBezierPathShape *> *)uniqueShapesCreatedFromSlicingWithUnclosedPath:(UIBezierPath *)scissorPath
{
    NSArray *shapeShellsAndSubShapes = [self uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray *shapeShells = [shapeShellsAndSubShapes firstObject];
    NSArray *subShapes = [shapeShellsAndSubShapes lastObject];

    // now i have shape shells and holes, and need to match them together
    for (DKUIBezierPathShape *shell in shapeShells) {
        for (DKUIBezierPathShape *sub in subShapes) {
            if (![shell sharesSegmentWith:sub]) {
                // they don't share a segment
                if ([shell.fullPath containsPoint:sub.fullPath.firstPoint]) {
                    // it's a hole
                    [shell.holes addObject:sub];
                }
            }
        }
    }
    return shapeShells;
}


+ (NSArray<NSArray<DKUIBezierPathShape *> *> *)subshapesCreatedFrom:(UIBezierPath *)shapePath bySlicingWithPath:(UIBezierPath *)scissorPath
{
    NSUInteger numberOfBlueShellSegments = 0;
    NSArray *redBlueSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:&numberOfBlueShellSegments];
    NSArray *redSegments = [redBlueSegments firstObject];
    NSArray *blueSegments = [redBlueSegments lastObject];


    // now we have all of the red segments and all of the blue segments.
    // next we need to traverse this graph of segments, starting with each
    // red segment and proceeding along the left most path. this will
    // create all of the new shapes possible from these segments.
    return [UIBezierPath generateShapesFromRedSegments:redSegments andBlueSegments:blueSegments comp:[shapePath isClockwise] shapeShellElementCount:(int)numberOfBlueShellSegments];
}

- (NSArray<UIBezierPath *> *)booleanWithPath:(UIBezierPath *)scissors calculateIntersection:(BOOL)intersection
{
    if ([self isClosed]) {
        NSUInteger numberOfBlueShellSegments = 0;
        NSArray *redBlueSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:self bySlicingWithPath:scissors andNumberOfBlueShellSegments:&numberOfBlueShellSegments];
        NSArray<DKUIBezierPathClippedSegment *> *redSegments = [[redBlueSegments firstObject] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DKUIBezierPathClippedSegment *redSegment, NSDictionary<NSString *, id> *_Nullable bindings) {
            return (intersection && ![redSegment isReversed]) || (!intersection && [redSegment isReversed]);
        }]];

        BOOL (^containsRedSegment)(DKUIBezierPathShape *) = ^(DKUIBezierPathShape *inShape) {
            NSArray *shapes = [[inShape holes] arrayByAddingObject:inShape];
            for (DKUIBezierPathShape *shape in shapes) {
                for (DKUIBezierPathClippedSegment *segment in [shape segments]) {
                    for (DKUIBezierPathClippedSegment *redSegment in redSegments) {
                        if ([redSegment isEqualToSegment:segment] && [[redSegment fullPath] isEqual:[segment fullPath]]) {
                            return YES;
                        }
                    }
                }
            }

            return NO;
        };

        NSArray *clippingResult = [self uniqueShapesCreatedFromSlicingWithUnclosedPath:scissors];
        NSMutableArray *result = [NSMutableArray array];

        for (DKUIBezierPathShape *shape in clippingResult) {
            // any shape whose first segment is not reversed part of the intersection.
            // this is because the first segment is a red segment, and non-reversed
            // means its part of the original scissor path
            if (containsRedSegment(shape)) {
                [result addObject:[shape fullPath]];
            }
        }

        return result;
    } else if ([scissors isClosed]) {
        BOOL beginsInside1 = NO;
        NSMutableArray *tValuesOfIntersectionPoints = [NSMutableArray arrayWithArray:[self findIntersectionsWithClosedPath:scissors andBeginsInside:&beginsInside1]];
        DKUIBezierPathClippingResult *clipped = [self clipUnclosedPathToClosedPath:scissors usingIntersectionPoints:tValuesOfIntersectionPoints andBeginsInside:beginsInside1];
        return intersection ? clipped.entireIntersectionPath.subPaths : clipped.entireDifferencePath.subPaths;
    } else {
        return nil;
    }
}

- (NSArray<UIBezierPath *> *)intersectionWithPath:(UIBezierPath *)scissors
{
    return [self booleanWithPath:scissors calculateIntersection:YES];
}

- (NSArray<UIBezierPath *> *)differenceWithPath:(UIBezierPath *)scissors
{
    return [self booleanWithPath:scissors calculateIntersection:NO];
}

- (NSArray<DKUIBezierPathShape *> *)allUniqueShapesWithPath:(UIBezierPath *)scissors
{
    // clip from both perspectives so that we get intersection shapes twice
    // and difference shapes from each path
    NSArray<DKUIBezierPathShape *> *clippingResult1 = [self uniqueShapesCreatedFromSlicingWithUnclosedPath:scissors];
    NSArray<DKUIBezierPathShape *> *clippingResult2 = [scissors uniqueShapesCreatedFromSlicingWithUnclosedPath:self];

    // Cutting the scissors path with self will return shapes with flipped intersections,
    // so flip them back so that the intersection element/tvalue order matches clippingResult1
    NSMutableArray *flippedResult2 = [NSMutableArray array];
    [clippingResult2 enumerateObjectsUsingBlock:^(DKUIBezierPathShape *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [flippedResult2 addObject:[obj flippedShape]];
    }];

    // We'll keep everything from one of the clips, and then we'll add in
    // the difference shapes from the other clipping
    NSMutableArray<DKUIBezierPathShape *> *finalShapes = [flippedResult2 mutableCopy];

    for (DKUIBezierPathShape *firstShape in clippingResult1) {
        BOOL didFind = NO;
        for (DKUIBezierPathShape *secondShape in finalShapes) {
            if ([firstShape isSameShapeAs:secondShape] || [[firstShape fullPath] isEqualToBezierPath:[secondShape fullPath]]) {
                didFind = YES;
                break;
            }
        }
        if (!didFind) {
            [finalShapes addObject:firstShape];
        }
    }

    return finalShapes;
}

- (NSArray<DKUIBezierPathShape *> *)uniqueGluedShapesWithPath:(UIBezierPath *)scissors
{
    NSMutableArray<DKUIBezierPathShape *> *shapes = [[self allUniqueShapesWithPath:scissors] mutableCopy];

    NSMutableArray *gluedShapes = [NSMutableArray array];

    while ([shapes count]) {
        DKUIBezierPathShape *shape = [shapes firstObject];
        [shapes removeObjectAtIndex:0];

        if ([gluedShapes count]) {
            NSInteger index = [gluedShapes indexOfObjectPassingTest:^BOOL(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                return [obj canGlueToShape:shape];
            }];

            if (index == NSNotFound) {
                [gluedShapes addObject:shape];
            } else {
                DKUIBezierPathShape *toShape = [gluedShapes objectAtIndex:index];
                DKUIBezierPathShape *gluedShape = [toShape glueToShape:shape];
                [gluedShapes removeObjectAtIndex:index]; // remove the shape we just merged

                // now we've merged two shapes together, which might affect other unglued shapes
                // in gluedShapes array, so restart our algorithm with our new slightly smaller
                // array of all shapes
                [shapes addObject:gluedShape];
                [shapes addObjectsFromArray:gluedShapes];
                [gluedShapes removeAllObjects];
            }
        } else {
            [gluedShapes addObject:shape];
        }
    }

    return gluedShapes;
}

- (NSMutableArray<UIBezierPath *> *)unionWithPath:(UIBezierPath *)scissors
{
    NSArray<DKUIBezierPathShape *> *shapes = [self uniqueGluedShapesWithPath:scissors];

    // at this point, we have shapes all in the same clockwise direction and
    // we need to glue them together. we glue by finding segments in one shape
    // that are the reversed segments of the other shape and cancel them out.
    // what's left should be two endpoints on either end of a shape that match,
    // and we can link those endpoints together into a larger shape.
    //
    // we do this until we can't find any segments between any shapes that are reversed

    NSMutableArray<UIBezierPath *> *paths = [NSMutableArray array];

    for (DKUIBezierPathShape *shape in shapes) {
        [paths addObject:[shape fullPath]];
    }

    return paths;
}


+ (NSArray *)removeIdenticalRedSegments:(NSArray *)_redSegments andBlueSegments:(NSArray *)_blueSegments
{
    NSMutableArray *blueSegments = [NSMutableArray array];
    NSMutableArray *redSegments = [NSMutableArray array];

    //
    // tangent fixing:
    //
    //
    // the next two for loops remove extra segments that would
    // otherwise cause problems. the issue is red segments that
    // are tangent to blue segments.
    //
    // out of the two red segments and one blue segment that
    // are all tangent, the following two for loops will remove
    // the 1 reverse red segment and the blue segment, leaving
    // only the tangent and same-directioned red segment.

    for (DKUIBezierPathClippedSegment *red in _redSegments) {
        BOOL shouldAdd = YES;
        for (DKUIBezierPathClippedSegment *blue in _blueSegments) {
            DKUIBezierPathClippedSegment *flippedBlue = [blue flippedSegment];
            if ([[red startIntersection] isEqualToIntersection:[flippedBlue startIntersection]] &&
                [[red endIntersection] isEqualToIntersection:[flippedBlue endIntersection]]) {
                CGFloat angleBetween = [[red reversedSegment] angleBetween:flippedBlue];
                if ([self round:angleBetween to:6] == [self round:M_PI to:6] ||
                    [self round:angleBetween to:6] == [self round:-M_PI to:6]) {
                    //
                    // right now, if a segment is tangent for red and blue, then
                    // i need to delete the blue, delete the reversed red, and leave
                    // the red that's identical to the blue
                    //                    shouldAdd = YES;
                    // this is the tangent that's identical to blue
                }
            } else if ([[red startIntersection] isEqualToIntersection:[flippedBlue endIntersection]] &&
                       [[red endIntersection] isEqualToIntersection:[flippedBlue startIntersection]]) {
                CGFloat angleBetween = [red angleBetween:flippedBlue];
                if ([self round:angleBetween to:6] == [self round:M_PI to:6] ||
                    [self round:angleBetween to:6] == [self round:-M_PI to:6]) {
                    //
                    // right now, if a segmetn is tangent for red and blue, then
                    // i need to delete teh blue, delete teh reversed red, and leave
                    // the red that's identical to the blue
                    shouldAdd = NO;
                    // this is the tangent that's reversed from blue
                }
            }
        }
        if (shouldAdd) {
            [redSegments addObject:red];
        }
    }


    for (DKUIBezierPathClippedSegment *blue in _blueSegments) {
        BOOL shouldAdd = YES;
        for (DKUIBezierPathClippedSegment *red in _redSegments) {
            DKUIBezierPathClippedSegment *flippedBlue = [blue flippedSegment];
            if ([[red startIntersection] isEqualToIntersection:[flippedBlue startIntersection]] &&
                [[red endIntersection] isEqualToIntersection:[flippedBlue endIntersection]]) {
                CGFloat angleBetween = [[red reversedSegment] angleBetween:flippedBlue];
                if ([self round:angleBetween to:6] == [self round:M_PI to:6] ||
                    [self round:angleBetween to:6] == [self round:-M_PI to:6]) {
                    //
                    // right now, if a segmetn is tangent for red and blue, then
                    // i need to delete teh blue, delete teh reversed red, and leave
                    // the red that's identical to the blue
                    shouldAdd = NO;
                    // this is the tangent that's identical to blue
                }
            } else if ([[red startIntersection] isEqualToIntersection:[flippedBlue endIntersection]] &&
                       [[red endIntersection] isEqualToIntersection:[flippedBlue startIntersection]]) {
                CGFloat angleBetween = [red angleBetween:flippedBlue];
                if ([self round:angleBetween to:6] == [self round:M_PI to:6] ||
                    [self round:angleBetween to:6] == [self round:-M_PI to:6]) {
                    //
                    // right now, if a segmetn is tangent for red and blue, then
                    // i need to delete teh blue, delete teh reversed red, and leave
                    // the red that's identical to the blue
                    //                    shouldAdd = YES;
                    // this is the tangent that's reversed from blue
                }
            }
        }
        if (shouldAdd) {
            [blueSegments addObject:blue];
        }
    }

    return @[redSegments, blueSegments];
}

/**
 * red segments are the segments of the scissors that intersect with the shape.
 * blue segments are the segments of the shape that have been split up by the scissors
 *
 * to find subshapes, we start with a red shape, and the follow along the left-most path
 * until we arrive back at the other end of the red shape
 */
+ (NSArray *)generateShapesFromRedSegments:(NSArray *)_redSegments andBlueSegments:(NSArray *)_blueSegments comp:(BOOL)gt shapeShellElementCount:(int)shapeShellElementCount
{
    NSArray *deduppedSegments = [self removeIdenticalRedSegments:_redSegments andBlueSegments:_blueSegments];

    NSArray *blueSegmentsOfShell = [_blueSegments subarrayWithRange:NSMakeRange(0, shapeShellElementCount)];
    NSMutableSet *intersectionsOfShell = [NSMutableSet set];
    [blueSegmentsOfShell enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [intersectionsOfShell addObject:[obj startIntersection]];
        [intersectionsOfShell addObject:[obj endIntersection]];
    }];
    NSMutableArray *output = [NSMutableArray array];


    NSMutableArray *redSegments = [[deduppedSegments firstObject] mutableCopy];
    NSMutableArray *blueSegments = [[deduppedSegments lastObject] mutableCopy];

    NSMutableArray *allUnusedBlueSegments = [NSMutableArray arrayWithArray:blueSegments];
    NSMutableArray *redSegmentsToStartWith = [NSMutableArray arrayWithArray:redSegments];


    NSMutableArray *holesInNewShapes = [NSMutableArray array];


    while ([redSegmentsToStartWith count] || [allUnusedBlueSegments count]) {
        BOOL failedBuildingShape = NO;
        DKUIBezierPathClippedSegment *startingSegment;
        BOOL startedWithRed;
        if ([redSegmentsToStartWith count]) {
            startingSegment = [redSegmentsToStartWith firstObject];
            [redSegmentsToStartWith removeObjectAtIndex:0];
            startedWithRed = YES;
        } else {
            startingSegment = [allUnusedBlueSegments firstObject];
            [allUnusedBlueSegments removeObject:startingSegment];
            startingSegment = [startingSegment flippedSegment];
            startedWithRed = NO;
        }
        NSMutableArray *usedBlueSegments = [NSMutableArray array];
        DKUIBezierPathShape *currentlyBuiltShape = [UIBezierPath buildShapeWithRedSegments:startedWithRed ? redSegments : @[]
                                                                           andBlueSegments:blueSegments
                                                                        andStartingSegment:startingSegment
                                                                                      comp:gt
                                                                              andSetFailed:&failedBuildingShape
                                                                    andSetUsedBlueSegments:usedBlueSegments];

        if (failedBuildingShape) {
            // allow any used up blue segments to be used
            // next time, and don't add the shape
            //            [output addObject:currentlyBuiltShape];
            [usedBlueSegments removeAllObjects];
        } else {
            //            NSLog(@"adding shape");

            NSIndexSet *indexes = [currentlyBuiltShape.segments indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
                // all shape segments, when blue, will have been flipped
                return (BOOL)([intersectionsOfShell containsObject:[[obj startIntersection] flipped]] ||
                              [intersectionsOfShell containsObject:[[obj endIntersection] flipped]]);
            }];

            if ([indexes count]) {
                // shape does intersect with the shell
                [output addObject:currentlyBuiltShape];
            } else {
                if (startedWithRed) {
                    //
                    // in addition to checking if it intersects with the shell,
                    // i also need to find out if i just found a shape that matches the
                    // shell's clockwise/counterclockwise rotation, or not
                    //
                    // if this shape matches the shell's rotation, then it's a shape.
                    //
                    // if it does not match the shell's rotation, then it's a hole
                    if ([currentlyBuiltShape.fullPath isClockwise] == gt) {
                        // it's a shape
                        [output addObject:currentlyBuiltShape];
                    } else {
                        [holesInNewShapes addObject:currentlyBuiltShape];
                        if ([currentlyBuiltShape.segments count] == 1) {
                            [output addObject:currentlyBuiltShape];
                        }
                    }
                } else {
                    // started with blue segment, and shape didn't intersect with the wall, so that
                    // means it's already a hole. add it
                    [holesInNewShapes addObject:currentlyBuiltShape];
                }
            }
        }
        [allUnusedBlueSegments removeObjectsInArray:usedBlueSegments];
    }

    //    NSLog(@"found shapes: %@", output);
    //    NSLog(@"found possible holes: %@", holesInNewShapes);
    //    NSLog(@"still have %d unused blue segments", [allUnusedBlueSegments count]);

    for (DKUIBezierPathShape *potentialHole in [holesInNewShapes copy]) {
        // make sure the probable hole is actually a hole, and that
        // it exists within one of the output shells.
        // otherwise add it as a shell
        BOOL isDefinitelyHole = NO;
        for (DKUIBezierPathShape *knownShell in output) {
            if (![knownShell sharesSegmentWith:potentialHole]) {
                // they don't share a segment
                if ([knownShell.fullPath containsPoint:potentialHole.fullPath.firstPoint]) {
                    // it's definitely a hole
                    isDefinitelyHole = YES;
                    break;
                }
            }
        }
        if (!isDefinitelyHole) {
            // the potential hole isn't inside of any of our shells,
            // which means it's really a shell iteself
            [output addObject:potentialHole];
            [holesInNewShapes removeObject:potentialHole];
        }
    }

    return [NSArray arrayWithObjects:output, holesInNewShapes, nil];
}

+ (DKUIBezierPathClippedSegment *)getBestMatchSegmentForSegments:(NSArray *)shapeSegments
                                                          forRed:(NSArray *)redSegments
                                                         andBlue:(NSArray *)blueSegments
                                                      lastWasRed:(BOOL)lastWasRed
                                                            comp:(BOOL)gt
{
    DKUIBezierPathClippedSegment *segment = [shapeSegments lastObject];

    NSMutableArray *redSegmentsLeftToUse = [NSMutableArray arrayWithArray:redSegments];
    NSMutableArray *blueSegmentsLeftToUse = [NSMutableArray arrayWithArray:blueSegments];

    // first, find the blue segment that can attach to this red segment.
    DKUIBezierPathClippedSegment *currentSegmentCandidate = nil;
    // only allow looking at blue if our last segment was red
    if (lastWasRed) {
        for (int bi = 0; bi < [blueSegmentsLeftToUse count]; bi++) {
            DKUIBezierPathClippedSegment *blueSeg = [blueSegmentsLeftToUse objectAtIndex:bi];
            if ([blueSeg.startIntersection crossMatchesIntersection:[segment endIntersection]]) {
                if (!currentSegmentCandidate) {
                    DKVector *currSeg = [[segment pathSegment] tangentNearEnd].tangent;
                    DKVector *currPoss = [[blueSeg pathSegment] tangentNearStart].tangent;
                    //                        NSLog(@"angle: %f", [currSeg angleBetween:currPoss]);
                    if ([UIBezierPath round:[currSeg angleBetween:currPoss] to:6] == [UIBezierPath round:M_PI to:6]) {
                        // never allow exactly backwards tangents
                    } else if ([UIBezierPath round:[currSeg angleBetween:currPoss] to:6] == [UIBezierPath round:-M_PI to:6]) {
                        // never allow exactly backwards tangents
                    } else {
                        currentSegmentCandidate = blueSeg;
                        lastWasRed = NO;
                    }
                } else {
                    DKVector *currSeg = [[segment pathSegment] tangentNearEnd].tangent;
                    DKVector *currPoss = [[currentSegmentCandidate pathSegment] tangentNearStart].tangent;
                    DKVector *newPoss = [[blueSeg pathSegment] tangentNearStart].tangent;
                    //                        NSLog(@"angle: %f vs %f", [currSeg angleBetween:currPoss], [currSeg angleBetween:newPoss]);
                    if (gt) {
                        if ([currSeg angleBetween:newPoss] > [currSeg angleBetween:currPoss]) {
                            if ([UIBezierPath round:[currSeg angleBetween:newPoss] to:3] == [UIBezierPath round:M_PI to:3]) {
                                // never allow exactly backwards tangents
                            } else {
                                currentSegmentCandidate = blueSeg;
                                lastWasRed = NO;
                            }
                        }
                    } else {
                        if ([currSeg angleBetween:newPoss] < [currSeg angleBetween:currPoss]) {
                            if ([UIBezierPath round:[currSeg angleBetween:newPoss] to:3] == [UIBezierPath round:-M_PI to:3]) {
                                // never allow exactly backwards tangents
                            } else {
                                currentSegmentCandidate = blueSeg;
                                lastWasRed = NO;
                            }
                        }
                    }
                }
            }
        }
    }
    // next, find the connecting red segment, unless we're already closed
    for (int ri = 0; ri < [redSegmentsLeftToUse count]; ri++) {
        DKUIBezierPathClippedSegment *redSeg = [redSegmentsLeftToUse objectAtIndex:ri];
        //
        // i need to track how the segments in the shape are being held. right now
        // crossMatchesIntersection checks the elementIndex1 with elementIndex2. if the segment is set
        // as a red segment, then the red segments here will never match, because the elementIndex1
        // would only ever match elementIndex1. We need to flip the last segment so that
        // it looks like a "blue", which would match a red segment
        DKUIBezierPathClippedSegment *lastSegmentInShapeAsBlue = [segment flippedSegment];
        if ([redSeg.startIntersection crossMatchesIntersection:[lastSegmentInShapeAsBlue endIntersection]]) {
            if (!currentSegmentCandidate) {
                DKVector *currSeg = [[segment pathSegment] tangentNearEnd].tangent;
                DKVector *currPoss = [[redSeg pathSegment] tangentNearStart].tangent;
                //                    NSLog(@"angle: %f", [currSeg angleBetween:currPoss]);
                if ([UIBezierPath round:[currSeg angleBetween:currPoss] to:6] == [UIBezierPath round:M_PI to:6]) {
                    // never allow exactly backwards tangents
                } else if ([UIBezierPath round:[currSeg angleBetween:currPoss] to:6] == [UIBezierPath round:-M_PI to:6]) {
                    // never allow exactly backwards tangents
                } else {
                    currentSegmentCandidate = redSeg;
                    lastWasRed = YES;
                }
            } else {
                DKVector *currSeg = [[segment pathSegment] tangentNearEnd].tangent;
                DKVector *currPoss = [[currentSegmentCandidate pathSegment] tangentNearStart].tangent;
                DKVector *newPoss = [[redSeg pathSegment] tangentNearStart].tangent;
                if (gt) {
                    if ([currSeg angleBetween:newPoss] >= [currSeg angleBetween:currPoss]) {
                        if ([UIBezierPath round:[currSeg angleBetween:newPoss] to:3] == [UIBezierPath round:M_PI to:3]) {
                            // never allow exactly backwards tangents
                        } else {
                            currentSegmentCandidate = redSeg;
                            lastWasRed = YES;
                        }
                    }
                } else {
                    if ([currSeg angleBetween:newPoss] <= [currSeg angleBetween:currPoss]) {
                        if ([UIBezierPath round:[currSeg angleBetween:newPoss] to:3] == [UIBezierPath round:-M_PI to:3]) {
                            // never allow exactly backwards tangents
                        } else {
                            currentSegmentCandidate = redSeg;
                            lastWasRed = YES;
                        }
                    }
                }
            }
        }
    }
    return currentSegmentCandidate;
}


#pragma mark - UIBezierPath Extras

/**
 * a very simple method that will clip self and return only its
 * difference with the input shape
 */
- (UIBezierPath *)differenceOfPathTo:(UIBezierPath *)shapePath
{
    BOOL beginsInside1 = NO;
    NSMutableArray *tValuesOfIntersectionPoints = [NSMutableArray arrayWithArray:[self findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside1]];
    DKUIBezierPathClippingResult *clipped = [self clipUnclosedPathToClosedPath:shapePath usingIntersectionPoints:tValuesOfIntersectionPoints andBeginsInside:beginsInside1];
    return clipped.entireDifferencePath;
}


/**
 * points toward the direction of the curve
 * along the tangent of the curve
 * near the end of the curve
 */
- (DKTangentAtPoint *)tangentNearEnd
{
    //    return [self tangentRoundingNearStartOrEnd:1.0];
    return [self tangentRoundingNearStartOrEnd:.999];
}

/**
 * points toward the direction of the curve
 * along the tangent of the curve
 * near the end of the curve
 */
- (DKTangentAtPoint *)tangentNearStart
{
    //    DKTangentAtPoint* tan = [self tangentRoundingNearStartOrEnd:0.0];
    //    return [DKTangentAtPoint tangent:[tan.tangent flip] atPoint:tan.point];
    return [self tangentRoundingNearStartOrEnd:.001];
}


#pragma mark - Private Helpers

+ (DKUIBezierPathShape *)buildShapeWithRedSegments:(NSArray *)redSegments
                                   andBlueSegments:(NSArray *)blueSegments
                                andStartingSegment:(DKUIBezierPathClippedSegment *)startingSegment
                                              comp:(BOOL)gt
                                      andSetFailed:(BOOL *)failedBuildingShape
                            andSetUsedBlueSegments:(NSMutableArray *)usedBlueSegments
{
    //
    // each shape gets to use all the segments if it wants, just starting
    // with a new segment
    NSMutableArray *redSegmentsLeftToUse = [NSMutableArray arrayWithArray:redSegments];
    NSMutableArray *blueSegmentsLeftToUse = [NSMutableArray arrayWithArray:blueSegments];

    DKUIBezierPathShape *currentlyBuiltShape = [[DKUIBezierPathShape alloc] init];
    [currentlyBuiltShape.segments addObject:startingSegment];

    failedBuildingShape[0] = NO;
    BOOL lastWasRed = [redSegments containsObject:startingSegment];
    while (!failedBuildingShape[0]) {
        // we'll set us to failed unless we can add a segment.
        // when we add a segment below, then that triggers that
        // we've not failed
        failedBuildingShape[0] = YES;

        // first, find the blue segment that can attach to this red segment.
        DKUIBezierPathClippedSegment *currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:currentlyBuiltShape.segments
                                                                                                      forRed:redSegmentsLeftToUse
                                                                                                     andBlue:blueSegmentsLeftToUse
                                                                                                  lastWasRed:lastWasRed
                                                                                                        comp:gt];
        if ([currentSegmentCandidate isEqualToSegment:[currentlyBuiltShape.segments firstObject]]) {
            // shape is complete when we would have chosen the segment that
            // we started with
            failedBuildingShape[0] = NO;
            break;
        }

        if (currentSegmentCandidate) {
            failedBuildingShape[0] = NO;
            lastWasRed = [redSegmentsLeftToUse containsObject:currentSegmentCandidate];
            if (lastWasRed) {
                [currentlyBuiltShape.segments addObject:currentSegmentCandidate];
            } else {
                // it's a blue segment. redefine the segment in terms of red endpoints
                // so that we can know if its closed or not
                [usedBlueSegments addObject:currentSegmentCandidate];
                [currentlyBuiltShape.segments addObject:[currentSegmentCandidate flippedSegment]];
            }
            [redSegmentsLeftToUse removeObject:currentSegmentCandidate];
            [blueSegmentsLeftToUse removeObject:currentSegmentCandidate];
        }
    }
    if ([currentlyBuiltShape.segments count] == 1) {
        // a shape with a single segment is valid if its closed
        failedBuildingShape[0] = ![currentlyBuiltShape isClosed];
    }
    return currentlyBuiltShape;
}


/**
 * will find and return tangent information roughly
 * near the tvalue. This will treat all curves as lines
 * for determining which element we should use to
 * pick out the tvalue
 */
- (DKTangentAtPoint *)tangentRoundingNearStartOrEnd:(CGFloat)tValue
{
    if (tValue == 0) {
        // return tangentAtStart
        return [DKTangentAtPoint tangent:[DKVector vectorWithAngle:[self tangentAtStart]] atPoint:[self firstPoint]];
        ;
    } else if (tValue == 1) {
        // return tangentAtEnd
        return [DKTangentAtPoint tangent:[DKVector vectorWithAngle:[self tangentAtEnd]] atPoint:[self lastPoint]];
        ;
    }

    __block CGFloat entireLength = 0;
    __block CGPoint lastPoint = CGPointNotFound;
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger idx) {
        CGPoint nextLastPoint = lastPoint;
        if (element.type == kCGPathElementAddLineToPoint) {
            nextLastPoint = element.points[0];
        } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
            nextLastPoint = element.points[1];
        } else if (element.type == kCGPathElementAddCurveToPoint) {
            nextLastPoint = element.points[2];
        } else if (element.type == kCGPathElementMoveToPoint) {
            nextLastPoint = element.points[0];
        } else if (element.type == kCGPathElementCloseSubpath) {
            nextLastPoint = self.firstPoint;
        }

        if (CGPointEqualToPoint(lastPoint, CGPointNotFound) || element.type == kCGPathElementMoveToPoint) {
            lastPoint = element.points[0];
        } else if (element.type != kCGPathElementCloseSubpath) {
            entireLength += [UIBezierPath distance:lastPoint p2:nextLastPoint];
        }

        lastPoint = nextLastPoint;
    }];

    // at this point, we have a very rough length of the segment.
    // we treat all curvs as lines, so it's very far from perfect, but
    // good enough for our needs

    __block DKTangentAtPoint *ret = nil;


    const int maxDist = [UIBezierPath maxDistForEndPointTangents];
    CGFloat lengthAtT = entireLength * tValue;
    if (tValue > .5) {
        if (lengthAtT < entireLength - maxDist) {
            lengthAtT = entireLength - maxDist;
            tValue = lengthAtT / entireLength;
        }
    } else {
        if (lengthAtT > maxDist) {
            lengthAtT = maxDist;
            tValue = lengthAtT / entireLength;
        }
    }

    __block CGFloat tValueToUse = tValue;

    __block CGFloat lengthSoFar = 0;
    lastPoint = CGPointNotFound;
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger idx) {
        // if we have an answer, just exit
        if (ret)
            return;
        CGPoint nextLastPoint = lastPoint;
        if (element.type == kCGPathElementAddLineToPoint) {
            nextLastPoint = element.points[0];
        } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
            nextLastPoint = element.points[1];
        } else if (element.type == kCGPathElementAddCurveToPoint) {
            nextLastPoint = element.points[2];
        } else if (element.type == kCGPathElementMoveToPoint) {
            nextLastPoint = element.points[0];
        } else if (element.type == kCGPathElementCloseSubpath) {
            nextLastPoint = self.firstPoint;
        }

        // we're still looking for the element that contains t
        CGFloat lengthOfElement = 0;
        if (CGPointEqualToPoint(lastPoint, CGPointNotFound) || element.type == kCGPathElementMoveToPoint) {
            lastPoint = element.points[0];
            nextLastPoint = lastPoint;
        } else if (element.type != kCGPathElementCloseSubpath) {
            lengthOfElement = [UIBezierPath distance:lastPoint p2:nextLastPoint];
        }
        if (lengthSoFar + lengthOfElement > lengthAtT) {
            // this is the element to use for our calculation
            // scale the tvalue to this element

            // chop the front of the path off
            CGFloat tSoFar = lengthSoFar / entireLength;
            tValueToUse = tValueToUse - tSoFar;

            // chop off the end of the path
            CGFloat tDurationOfElement = (lengthOfElement) / entireLength;
            if (tDurationOfElement) {
                tValueToUse /= tDurationOfElement;
            }

            // use this tvalue
            CGPoint bez[4];
            bez[0] = lastPoint;
            bez[3] = element.points[0];
            if (element.type == kCGPathElementAddLineToPoint) {
                CGFloat width = element.points[0].x - lastPoint.x;
                CGFloat height = element.points[0].y - lastPoint.y;
                bez[1] = CGPointMake(lastPoint.x + width / 3.0, lastPoint.y + height / 3.0);
                bez[2] = CGPointMake(lastPoint.x + width / 3.0 * 2.0, lastPoint.y + height / 3.0 * 2.0);
            } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
                bez[0] = lastPoint;

                bez[1] = CGPointMake((lastPoint.x + 2.0 * element.points[0].x) / 3.0,
                                     (lastPoint.y + 2.0 * element.points[0].y) / 3.0);
                bez[2] = CGPointMake((element.points[1].x + 2.0 * element.points[0].x) / 3.0,
                                     (element.points[1].y + 2.0 * element.points[0].y) / 3.0);

                bez[3] = element.points[1];
            } else if (element.type == kCGPathElementAddCurveToPoint) {
                bez[0] = lastPoint;
                bez[1] = element.points[0];
                bez[2] = element.points[1];
                bez[3] = element.points[2];
            }

            CGPoint tangent = [UIBezierPath tangentAtT:tValueToUse forBezier:bez];
            CGPoint point = [UIBezierPath pointAtT:tValueToUse forBezier:bez];

            ret = [DKTangentAtPoint tangent:[[DKVector vectorWithX:tangent.x andY:tangent.y] normal] atPoint:point];
        }
        lengthSoFar += lengthOfElement;
        lastPoint = nextLastPoint;
    }];

    return ret;
}


#pragma mark - Utility

/**
 * when calculating the tangent of a curve near its
 * endpoint, this is the maximum distance away from the endpoint
 * that we're allowed to travel
 */
+ (CGFloat)maxDistForEndPointTangents
{
    return 5;
}

CG_INLINE CGFloat
CGIsAboutEqual(CGFloat a, CGFloat b)
{
    NSInteger aInt = (NSInteger)(a * 1000000);
    NSInteger bInt = (NSInteger)(b * 1000000);
    return aInt == bInt;
}

CG_INLINE CGFloat
CGIsAboutGreater(CGFloat a, CGFloat b)
{
    NSInteger aInt = (NSInteger)(a * 1000000);
    NSInteger bInt = (NSInteger)(b * 1000000);
    return aInt > bInt;
}

CG_INLINE CGFloat
CGIsAboutLess(CGFloat a, CGFloat b)
{
    NSInteger aInt = (NSInteger)(a * 1000000);
    NSInteger bInt = (NSInteger)(b * 1000000);
    return aInt < bInt;
}

+ (NSArray<NSValue *> *)findIntersectionsBetweenBezier:(CGPoint[4])bez andLineFrom:(CGPoint)p1 to:(CGPoint)p2 flipped:(bool)flipped
{
    if (CGPointEqualToPoint(p1, p2) || CGPointEqualToPoint(bez[0], bez[3])) {
        // TODO julia we might still have to check if that point happens to be ON the curve?!
        return [NSArray array];
    }

    NSMutableArray<NSValue *> *intersections = [NSMutableArray array];

    CGFloat A = p2.y - p1.y; //A=y2-y1
    CGFloat B = p1.x - p2.x; //B=x1-x2
    CGFloat C = p1.x * (p1.y - p2.y) + p1.y * (p2.x - p1.x); //C=x1*(y1-y2)+y1*(x2-x1)

    CGFloat px[4] = {bez[0].x, bez[1].x, bez[2].x, bez[3].x};
    CGFloat py[4] = {bez[0].y, bez[1].y, bez[2].y, bez[3].y};
    Coeffs bx = [self bezierCoeffs:px];
    Coeffs by = [self bezierCoeffs:py];

    CGFloat P[4];
    P[0] = A * bx.a3 + B * by.a3; /*t^3*/
    P[1] = A * bx.a2 + B * by.a2; /*t^2*/
    P[2] = A * bx.a1 + B * by.a1; /*t*/
    P[3] = A * bx.a0 + B * by.a0 + C; /*1*/

    NSArray<NSNumber *> *r = [self cubicRoots:P];

    /*verify the roots are in bounds of the linear segment*/
    for (int i = 0; i < 3; i++) {
        CGFloat t = [r[i] floatValue];

        CGPoint p;
        p.x = bx.a3 * t * t * t + bx.a2 * t * t + bx.a1 * t + bx.a0;
        p.y = by.a3 * t * t * t + by.a2 * t * t + by.a1 * t + by.a0;


        /*above is intersection point assuming infinitely long line segment,
          make sure we are also in bounds of the line*/
        CGFloat s;
        if (!CGIsAboutEqual((p2.x - p1.x), 0)) {
            /*if not vertical line*/
            s = (p.x - p1.x) / (p2.x - p1.x);
        } else {
            s = (p.y - p1.y) / (p2.y - p1.y);
        }

        // discard if not in bounds
        if (CGIsAboutLess(t, 0) || CGIsAboutGreater(t, 1) || CGIsAboutLess(s, 0) || CGIsAboutGreater(s, 1)) {
            continue;
        }

        CGFloat lineLength = [UIBezierPath distance:p1 p2:p2];
        CGFloat tLine = [UIBezierPath distance:p p2:p1] / lineLength;

        if (CGIsAboutLess(tLine, 0) || CGIsAboutGreater(tLine, 1)) {
            continue;
        }

        if (flipped) {
            [intersections addObject:[NSValue valueWithCGPoint:CGPointMake(tLine, t)]];
        } else {
            [intersections addObject:[NSValue valueWithCGPoint:CGPointMake(t, tLine)]];
        }
    }

    return intersections;
}

+ (NSArray<NSNumber *> *)cubicRoots:(CGFloat[4])p
{
    CGFloat t[3] = {1, -1, -1};

    if (p[0] == 0) {
        if (p[1] == 0) {
            // linear formula
            CGFloat t[3];
            t[0] = -1 * (p[3] / p[2]);
            t[1] = -1;
            t[2] = -1;

            /*discard out of spec roots*/
            if (t[0] < 0 || t[0] > 1.0) {
                t[0] = -1;
            }

            return [UIBezierPath sortedCubicRootsFromCArray:t];

        } else {
            CGFloat DQ = pow(p[2], 2) - 4 * p[1] * p[3]; // quadratic discriminant
            if (DQ >= 0) {
                // quadratic formula
                DQ = sqrt(DQ);
                t[0] = -1 * ((DQ + p[2]) / (2 * p[1]));
                t[1] = ((DQ - p[2]) / (2 * p[1]));
                t[2] = -1;

                /*discard out of spec roots*/
                for (int i = 0; i < 2; i++) {
                    if (t[i] < 0 || t[i] > 1.0) {
                        t[i] = -1;
                    }
                }
            }

            return [UIBezierPath sortedCubicRootsFromCArray:t];
        }
    } else {
        CGFloat a = p[0];
        CGFloat b = p[1];
        CGFloat c = p[2];
        CGFloat d = p[3];

        CGFloat A = b / a;
        CGFloat B = c / a;
        CGFloat C = d / a;

        CGFloat Q = (3 * B - pow(A, 2)) / 9;
        CGFloat R = (9 * A * B - 27 * C - 2 * pow(A, 3)) / 54;
        CGFloat D = pow(Q, 3) + pow(R, 2); // polynomial discriminant

        if (D >= 0) // complex or duplicate roots
        {
            CGFloat S = sgn(R + sqrt(D)) * pow(abs(R + sqrt(D)), (1.0 / 3.0));
            CGFloat T = sgn(R - sqrt(D)) * pow(abs(R - sqrt(D)), (1.0 / 3.0));

            t[0] = -A / 3 + (S + T); // real root
            t[1] = -A / 3 - (S + T) / 2; // real part of complex root
            t[2] = -A / 3 - (S + T) / 2; // real part of complex root
            CGFloat Im = abs(sqrt(3) * (S - T) / 2); // complex part of root pair

            /*discard complex roots*/
            if (Im != 0) {
                t[1] = -1;
                t[2] = -1;
            }

        } else { // distinct real roots
            CGFloat th = acos(R / sqrt(-pow(Q, 3)));

            t[0] = 2 * sqrt(-Q) * cos(th / 3) - A / 3;
            t[1] = 2 * sqrt(-Q) * cos((th + 2 * M_PI) / 3) - A / 3;
            t[2] = 2 * sqrt(-Q) * cos((th + 4 * M_PI) / 3) - A / 3;
        }

        /*discard out of spec roots*/
        for (int i = 0; i < 3; i++) {
            if (t[i] < 0 || t[i] > 1.0) {
                t[i] = -1;
            }
        }

        return [UIBezierPath sortedCubicRootsFromCArray:t];
    }
}

+ (NSArray<NSNumber *> *)sortedCubicRootsFromCArray:(CGFloat[3])t
{
    NSArray<NSNumber *> *retArray = @[
        @(t[0]),
        @(t[1]),
        @(t[2])
    ];

    return [retArray sortedArrayUsingComparator:^(id obj1, id obj2) {
        if ([obj1 floatValue] == -1) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        if ([obj2 floatValue] == -1) {
            return (NSComparisonResult)NSOrderedAscending;
        }

        if ([obj1 floatValue] > [obj2 floatValue]) {
            return (NSComparisonResult)NSOrderedDescending;
        }

        if ([obj1 floatValue] < [obj2 floatValue]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
}

+ (Coeffs)bezierCoeffs:(CGFloat[4])p
{
    Coeffs c;
    c.a3 = -p[0] + 3 * p[1] + -3 * p[2] + p[3];
    c.a2 = 3 * p[0] - 6 * p[1] + 3 * p[2];
    c.a1 = -3 * p[0] + 3 * p[1];
    c.a0 = p[0];
    return c;
}


/**
 * this will return an unfiltered array of intersections between
 * the two input bezier curves. it will also blindly try to find
 * intersections, even if the two input curves do not share
 * any overlapping bounds (though it would still return quickly)
 */
+ (NSArray *)findIntersectionsBetweenBezier:(CGPoint[4])bez1 andBezier:(CGPoint[4])bez2
{
    NSMutableArray *intersectionsOutput = [NSMutableArray array];
    NSMutableArray *altIntersectionsOutput = [NSMutableArray array];

    std::vector<Geom::Point> A((int)4);
    A[0] = Geom::Point(bez1[0].x, bez1[0].y);
    A[1] = Geom::Point(bez1[1].x, bez1[1].y);
    A[2] = Geom::Point(bez1[2].x, bez1[2].y);
    A[3] = Geom::Point(bez1[3].x, bez1[3].y);


    std::vector<Geom::Point> B((int)4);
    B[0] = Geom::Point(bez2[0].x, bez2[0].y);
    B[1] = Geom::Point(bez2[1].x, bez2[1].y);
    B[2] = Geom::Point(bez2[2].x, bez2[2].y);
    B[3] = Geom::Point(bez2[3].x, bez2[3].y);

    get_solutions(intersectionsOutput, B, A, kUIBezierClippingPrecision, Geom::intersections_clip);
    get_solutions(altIntersectionsOutput, A, B, kUIBezierClippingPrecision, Geom::intersections_clip);

    //
    // This is a bit of a shame, but we'll get different answers out of libgeom
    // depending on the order of the beziers that we send in.
    //
    // As a work around, we'll trust the solution with more found intersections.
    //
    // there is a small chance that the output will be of equal size, but will
    // have found different intersections, but we're going to ignore that edge
    // case
    if ([altIntersectionsOutput count] > [intersectionsOutput count]) {
        NSMutableArray *altRet = [NSMutableArray array];
        [altIntersectionsOutput enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGPoint p = [obj CGPointValue];
            CGFloat swap = p.y;
            p.y = p.x;
            p.x = swap;
            [altRet addObject:[NSValue valueWithCGPoint:p]];
        }];
        intersectionsOutput = altRet;
    }
    return intersectionsOutput;
}


/**
 *
 * from http://stackoverflow.com/questions/15489520/calculate-the-arclength-curve-length-of-a-cubic-bezier-curve-why-is-not-workin
 *
 * this will return an estimated arc length for the input bezier, given
 * the input number of steps to divide it into
 */
+ (CGFloat)estimateArcLengthOf:(CGPoint *)bez1 withMaxSteps:(NSInteger)steps andAccuracy:(CGFloat)accuracy
{
    CGFloat dist1 = [UIBezierPath distance:bez1[0] p2:bez1[1]];
    CGFloat dist2 = [UIBezierPath distance:bez1[1] p2:bez1[2]];
    CGFloat dist3 = [UIBezierPath distance:bez1[2] p2:bez1[3]];
    CGFloat total = dist1 + dist2 + dist3;

    if (total < accuracy) {
        return total;
    }

    CGFloat td = 1.0 / steps;
    CGPoint b = bez1[0];
    CGFloat dX = 0, dY = 0;
    CGFloat dS = 0;
    CGFloat sumArc = 0;
    CGFloat t = 0;

    for (int i = 0; i < steps; i++) {
        t = t + td;
        CGPoint a = [UIBezierPath pointAtT:t forBezier:bez1];
        dX = a.x - b.x;
        dY = a.y - b.y;
        // deltaS. Pitagora
        dS = sqrt((dX * dX) + (dY * dY));
        sumArc = sumArc + dS;
        b.x = a.x;
        b.y = a.y;
    }

    return sumArc;
}


/**
 * this method will fill the input bezier curve with the contents of the
 * input starting point and CGPathElement.
 *
 * this is a convenient way to created a CGPoint[4] from a CGPathElement
 *
 * For convenience, this method will return the point at the end of the
 * element, so that if looping through numerous elements it's easy to get
 * the starting point for the next element without needing to inspect the
 * value of the returned bez.
 */
+ (CGPoint)fillCGPoints:(CGPoint *)bez withElement:(CGPathElement)element givenElementStartingPoint:(CGPoint)startPoint andSubPathStartingPoint:(CGPoint)pathStartPoint
{
    if (element.type == kCGPathElementCloseSubpath) {
        // treat a close path as a line from the current starting
        // point back to the beginning of the line
        bez[0] = startPoint;
        bez[1] = CGPointMake(startPoint.x + (pathStartPoint.x - startPoint.x) / 3.0, startPoint.y + (pathStartPoint.y - startPoint.y) / 3.0);
        bez[2] = CGPointMake(startPoint.x + (pathStartPoint.x - startPoint.x) * 2.0 / 3.0, startPoint.y + (pathStartPoint.y - startPoint.y) * 2.0 / 3.0);
        bez[3] = pathStartPoint;
        return pathStartPoint;
    } else if (element.type == kCGPathElementMoveToPoint) {
        bez[0] = element.points[0];
        bez[1] = element.points[0];
        bez[2] = element.points[0];
        bez[3] = element.points[0];
        return element.points[0];
    } else if (element.type == kCGPathElementAddLineToPoint) {
        bez[0] = startPoint;
        bez[1] = CGPointMake(startPoint.x + (element.points[0].x - startPoint.x) / 3.0, startPoint.y + (element.points[0].y - startPoint.y) / 3.0);
        bez[2] = CGPointMake(startPoint.x + (element.points[0].x - startPoint.x) * 2.0 / 3.0, startPoint.y + (element.points[0].y - startPoint.y) * 2.0 / 3.0);
        bez[3] = element.points[0];
        return element.points[0];
    } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
        CGPoint ctrlOrig = element.points[0];
        CGPoint curveTo = element.points[1];
        CGPoint ctrl1 = CGPointMake((startPoint.x + 2.0 * ctrlOrig.x) / 3.0, (startPoint.y + 2.0 * ctrlOrig.y) / 3.0);
        CGPoint ctrl2 = CGPointMake((curveTo.x + 2.0 * ctrlOrig.x) / 3.0, (curveTo.y + 2.0 * ctrlOrig.y) / 3.0);

        bez[0] = startPoint;
        bez[1] = ctrl1;
        bez[2] = ctrl2;
        bez[3] = element.points[1];
        return element.points[1];
    } else if (element.type == kCGPathElementAddCurveToPoint) {
        bez[0] = startPoint;
        bez[1] = element.points[0];
        bez[2] = element.points[1];
        bez[3] = element.points[2];
        return element.points[2];
    } else {
        // impossible, but listed for the compiler's
        // happiness (unless new element types are added
        // one day...)
        return CGPointZero;
    }
}

+ (CGFloat)round:(CGFloat)val to:(int)digits
{
    double factor = pow(10, digits);
    return roundf(val * factor) / factor;
}

@end

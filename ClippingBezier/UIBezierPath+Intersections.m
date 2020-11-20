//
//  UIBezierPath+Intersections.m
//  ClippingBezier
//
//  Created by Adam Wulf on 2/1/15.
//  Copyright (c) 2015 Adam Wulf. All rights reserved.
//

#import "UIBezierPath+Intersections.h"
#import <PerformanceBezier/PerformanceBezier.h>
#import "DKIntersectionOfPaths.h"
#import "UIBezierPath+Clipping.h"
#import "UIBezierPath+Trimming.h"
#import "UIBezierPath+Ahmed.h"

static inline CGPoint intersects2D(CGPoint p1, CGPoint p2, CGPoint p3, CGPoint p4);


@implementation UIBezierPath (Intersections)

+ (void)load
{
    @autoreleasepool {
        NSStringFromClass([self class]);
    }
}
// boolean operations for an unclosed path on a closed path

/**
 * this method will loop the current segment, and will chop it into
 * pieces each time it intersects itself.
 *
 * keep an ever growing path of all we've seen. if the current element
 * intersects anything that we've seen so far, then split it at the intersection
 * point.
 *
 * the "all we've ever seen" will contain the first half + intersection, and teh output
 * array will contain the last half + intersection
 */
- (NSArray<DKUIBezierPathIntersectionPoint *> *)selfIntersections
{
    NSMutableArray *intersections = [NSMutableArray array];
    __block UIBezierPath *seenSoFar = [UIBezierPath bezierPath];
    __block CGPoint lastMoveTo = [self firstPoint];
    __block NSInteger lastMoveToIndex = 0;
    __block CGPoint lastPoint = lastMoveTo;

    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger idx) {
        if (element.type == kCGPathElementMoveToPoint) {
            [seenSoFar addPathElement:element];
            lastMoveTo = element.points[0];
            lastPoint = lastMoveTo;
            lastMoveToIndex = idx;
            return;
        }
        if ([seenSoFar length]) {
            UIBezierPath *segment = [UIBezierPath bezierPath];
            [segment moveToPoint:lastPoint];

            if (element.type == kCGPathElementCloseSubpath) {
                [segment addLineToPoint:lastMoveTo];
                lastPoint = lastMoveTo;
            } else {
                [segment addPathElement:element];
                lastPoint = element.points[[UIBezierPath numberOfPointsForElement:element] - 1];
            }

            NSArray<DKUIBezierPathIntersectionPoint *> *segmentIntersections = [seenSoFar findIntersectionsWithClosedPath:segment andBeginsInside:NULL];
            for (DKUIBezierPathIntersectionPoint *intersection in segmentIntersections) {
                if (([intersection elementIndex2] == 1 && [intersection tValue2] == 0) ||
                    ([intersection elementIndex2] == 0 && [intersection tValue2] == 1)) {
                    // skip
                } else if (element.type == kCGPathElementCloseSubpath &&
                           (([intersection elementIndex1] == lastMoveToIndex && [intersection tValue1] == 1) ||
                            ([intersection elementIndex1] == lastMoveToIndex + 1 && [intersection tValue1] == 0))) {
                    // skip, it's the close path intersecting the start of the path
                } else {
                    DKUIBezierPathIntersectionPoint *adjustedInter = [DKUIBezierPathIntersectionPoint intersectionAtElementIndex:intersection.elementIndex1
                                                                                                                       andTValue:intersection.tValue1
                                                                                                                withElementIndex:seenSoFar.elementCount + intersection.elementIndex2 - 1
                                                                                                                       andTValue:intersection.tValue2
                                                                                                                andElementCount1:self.elementCount
                                                                                                                andElementCount2:self.elementCount
                                                                                                          andLengthUntilPath1Loc:intersection.lenAtInter1
                                                                                                          andLengthUntilPath2Loc:seenSoFar.length + intersection.lenAtInter2];
                    adjustedInter.bez1[0] = intersection.bez1[0];
                    adjustedInter.bez1[1] = intersection.bez1[1];
                    adjustedInter.bez1[2] = intersection.bez1[2];
                    adjustedInter.bez1[3] = intersection.bez1[3];
                    adjustedInter.bez2[0] = intersection.bez2[0];
                    adjustedInter.bez2[1] = intersection.bez2[1];
                    adjustedInter.bez2[2] = intersection.bez2[2];
                    adjustedInter.bez2[3] = intersection.bez2[3];
                    adjustedInter.pathLength1 = self.length;
                    adjustedInter.pathLength2 = adjustedInter.pathLength1;
                    [intersections addObject:adjustedInter];
                }
            }
        }

        [seenSoFar addPathElement:element];
    }];

    return intersections;
}

- (UIBezierPath *)pathByRemovingSelfIntersections
{
    NSArray<DKUIBezierPathIntersectionPoint *> *intersections = [self selfIntersections];

    return [self copy];
}

- (NSArray<UIBezierPath *> *)pathsFromSelfIntersections
{
    NSMutableArray<DKUIBezierPathIntersectionPoint *> *intersections = [NSMutableArray array];

    for (DKUIBezierPathIntersectionPoint *inter in [self selfIntersections]) {
        [intersections addObject:inter];
        [intersections addObject:[inter flipped]];
    }

    [intersections sortUsingComparator:^NSComparisonResult(DKUIBezierPathIntersectionPoint *obj1, DKUIBezierPathIntersectionPoint *obj2) {
        if (obj1.elementIndex1 > obj2.elementIndex1) {
            return NSOrderedAscending;
        } else if (obj1.elementIndex1 == obj2.elementIndex1 && obj1.tValue1 > obj2.tValue2) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];

    NSMutableArray<UIBezierPath *> *paths = [NSMutableArray array];
    UIBezierPath *fullPath = self;

    NSInteger elementIndexes[intersections.count];
    CGFloat tValues[intersections.count];

    for (NSInteger index = 0; index < [intersections count]; index++) {
        DKUIBezierPathIntersectionPoint *inter = intersections[index];

        elementIndexes[index] = inter.elementIndex1;
        tValues[index] = inter.tValue1;
    }

    for (NSInteger index = 0; index < [intersections count]; index++) {
        NSInteger elementIndex = elementIndexes[index];
        CGFloat tValue = tValues[index];

        // TODO: if intersections contains 2+ intersections within the same element, the tValues of 2+ intersections needs to be scaled
        // to account for the clipped intersection.
        [paths addObject:[fullPath bezierPathByTrimmingFromElement:elementIndex andTValue:tValue]];
        fullPath = [fullPath bezierPathByTrimmingToElement:elementIndex andTValue:tValue];

        for (NSInteger next = index + 1; next < [intersections count]; next++) {
            NSInteger nextElementIndex = elementIndexes[next];
            CGFloat nextTValue = tValues[next];

            if (elementIndex == nextElementIndex) {
                tValues[next] = nextTValue / tValue;
            } else {
                break;
            }
        }
    }

    if ([fullPath length]) {
        [paths addObject:fullPath];
    }

    return [[paths reverseObjectEnumerator] allObjects];
}

+ (CGPoint)intersects2D:(CGPoint)p1 to:(CGPoint)p2 andLine:(CGPoint)p3 to:(CGPoint)p4
{
    return intersects2D(p1, p2, p3, p4);
}


/**
 * This method will possibly split /myFlatPath/ into two pieces.
 * The first piece will be up to it's nearest intersection with
 * /otherFlatPath/, and the second will be whatever is left
 *
 * this method acts on flattened UIBiezerPaths.
 *
 * it's particularly useful for us, because we're going to call
 * into this method with flattened /elements/ of a larger path.
 * this way, instead of flattening the entire shape, we'll only
 * flatten and compare the new segment to small pieces of the
 * shape.
 *
 * in thoery, this should reduce CPU considerably.
 *
 * this method should return:
 * 1. if there is an intersection between the curves
 * 2. the section of myFlatElement before the intersection, and
 * 3. the section of myFlatElement after the intersection
 *
 * the /start/ and /end/ properties of the returned struct
 * are autoreleased
 *
 * this will always ignore an intersection at element == 1 and tvalue = 0
 */
+ (DKIntersectionOfPaths *)firstIntersectionBetween:(UIBezierPath *)myFlatPath
                                            andPath:(UIBezierPath *)otherFlatPath
{
    // this method is called on two flattened paths,
    // and represents the intersection of
    // two unflattened elements from the psuedoForUnflattenedPaths
    DKIntersectionOfPaths *ret = [[DKIntersectionOfPaths alloc] init];
    // initialize
    ret.doesIntersect = NO;
    ret.start = nil;
    ret.end = nil;

    // setup our output
    UIBezierPath *pathToFirstIntersection = [UIBezierPath bezierPath];
    UIBezierPath *restOfPath = [UIBezierPath bezierPath];

    //
    // flat if we've seen the intersection yet,
    // if so, then all the rest of the elements
    // will be added to restOfPath
    __block BOOL hasSeenIntersection = NO;

    //
    // lastPoint is the start point of the line segment,
    // which is the end point / moveTo point of the
    // element before it
    __block CGPoint myLastPoint = CGPointZero;
    // when we find an intersection, we need to track it
    // so that we don't find it twice in a row
    __block NSInteger myElementIndexOfIntersection = -1;
    __block CGFloat myTValueOfIntersection = 0;
    [myFlatPath iteratePathWithBlock:^(CGPathElement element, NSUInteger myCurrentElementIndex) {
        //
        // this measures the distance to the closest intersection
        // found to the start of the current line segment
        __block CGFloat distanceToClosestIntersection;
        do {
            // CGFLOAT_MAX means that we haven't found an intersection
            distanceToClosestIntersection = CGFLOAT_MAX;

            if (element.type == kCGPathElementMoveToPoint) {
                // just trying to find the first intersection,
                // so we're never inside
                if (!hasSeenIntersection) {
                    [pathToFirstIntersection moveToPoint:element.points[0]];
                } else {
                    [restOfPath moveToPoint:element.points[0]];
                }
                myLastPoint = element.points[0];
            } else if (element.type == kCGPathElementCloseSubpath) {
                //
                // ok, first check if we're done with the subpath,
                // if so, reset our state and keep going if we have
                // more subpaths
                if (!hasSeenIntersection) {
                    [pathToFirstIntersection closePath];
                } else {
                    [restOfPath closePath];
                }
                myLastPoint = CGPointZero;
            } else if (element.type == kCGPathElementAddLineToPoint) {
                CGPoint nextPoint = element.points[0];
                if (!hasSeenIntersection) {
                    __block CGPoint lastPointOfOperatedPath = CGPointNotFound;
                    __block CGPoint closestIntersectionOfCurve = CGPointNotFound;
                    __block CGPoint mostRecentMoveToPoint = CGPointNotFound;
                    //
                    // now, we iterate over the entire path with our line segment,
                    // looking for the closest intersection point to the start
                    // of the line.
                    [otherFlatPath iteratePathWithBlock:^(CGPathElement element, NSUInteger idx) {
                        if (element.type == kCGPathElementMoveToPoint) {
                            // track our last moved to point, so that we know
                            // where to start our segment, or where we should
                            // end if we see a close path
                            lastPointOfOperatedPath = element.points[0];
                            mostRecentMoveToPoint = element.points[0];
                        } else if (element.type == kCGPathElementAddLineToPoint ||
                                   element.type == kCGPathElementCloseSubpath) {
                            CGPoint lineToPoint;
                            if (element.type == kCGPathElementAddLineToPoint) {
                                // our line will end at the element point
                                lineToPoint = element.points[0];
                            } else {
                                // our line will end at the beginning of the subpath
                                lineToPoint = mostRecentMoveToPoint;
                            }
                            // find our intersection, if any
                            CGPoint intersection = intersects2D(myLastPoint, nextPoint, lastPointOfOperatedPath, lineToPoint);
                            if (!CGPointEqualToPoint(intersection, CGPointNotFound) &&
                                !CGPointEqualToPoint(myLastPoint, intersection)) {
                                // ok, we found an intersection! save this intersection
                                // if it's the closest one we've seen so far, otherwise
                                // disregard it
                                CGFloat distanceToIntersection = [UIBezierPath distance:intersection p2:myLastPoint];
                                if (distanceToIntersection < distanceToClosestIntersection) {
                                    closestIntersectionOfCurve = intersection;
                                    distanceToClosestIntersection = distanceToIntersection;
                                }
                            }
                        }
                        lastPointOfOperatedPath = element.points[0];
                    }];

                    //
                    // at this point, closestIntersectionOfCurve and distanceToClosestIntersection
                    // will both be set with values if we found an intersection at all
                    if (!CGPointEqualToPoint(closestIntersectionOfCurve, CGPointNotFound)) {
                        // save the element and T value for the intersection
                        // the t value is just the distance to the intersection compared to the entire line
                        myElementIndexOfIntersection = myCurrentElementIndex;
                        myTValueOfIntersection = [UIBezierPath distance:myLastPoint p2:closestIntersectionOfCurve] / [UIBezierPath distance:myLastPoint p2:nextPoint];
                        // the location of the intersection is where we'll pick up
                        // when we next loop. We don't actually need this in the
                        // case where we find teh interesection, but i'm including it
                        // to keep the code parallel. that way the myLastPoint will always
                        // be accuate through the algorithm, whether it needs to or not
                        hasSeenIntersection = YES;
                        myLastPoint = closestIntersectionOfCurve;
                        // now add the intersection to our segments
                        [pathToFirstIntersection addLineToPoint:closestIntersectionOfCurve];
                        [restOfPath moveToPoint:closestIntersectionOfCurve];
                    } else {
                        // update our endpoint
                        myLastPoint = element.points[0];
                        [pathToFirstIntersection addLineToPoint:myLastPoint];
                    }
                } else {
                    // we've already found the intersection, so now
                    // we just need to add everythign we see to the
                    // rest of the output
                    [restOfPath addLineToPoint:nextPoint];
                }
            } else {
                //
                // this algorithm and only handle flattened paths
            }

            // if we found an intersection, then we've split this
            // segment in half and need to continue chopping the
            // next piece of it
        } while (distanceToClosestIntersection != CGFLOAT_MAX);
    }];

    // set our output and we're done!
    ret.doesIntersect = hasSeenIntersection;
    ret.start = pathToFirstIntersection;
    ret.end = restOfPath;
    ret.elementNumberOfIntersection = (int)myElementIndexOfIntersection;
    ret.tValueOfIntersection = myTValueOfIntersection;

    if (!ret.doesIntersect) {
        ret.end = nil;
    }

    return ret;
}

CGRect boundsForElement(CGPoint startPoint, CGPathElement element, CGPoint pathStartingPoint)
{
    // this method will return the bounds for the input element
    // it'd really need the start point of the element too, but
    // it's pseudo code...
    if (element.type == kCGPathElementAddCurveToPoint) {
        CGFloat minX = MIN(MIN(MIN(startPoint.x, element.points[0].x), element.points[1].x), element.points[2].x);
        CGFloat minY = MIN(MIN(MIN(startPoint.y, element.points[0].y), element.points[1].y), element.points[2].y);
        CGFloat maxX = MAX(MAX(MAX(startPoint.x, element.points[0].x), element.points[1].x), element.points[2].x);
        CGFloat maxY = MAX(MAX(MAX(startPoint.y, element.points[0].y), element.points[1].y), element.points[2].y);
        return CGRectMake(minX, minY, maxX - minX, maxY - minY);
    } else if (element.type == kCGPathElementMoveToPoint) {
        return CGRectMake(element.points[0].x, element.points[0].y, 0, 0);
    } else if (element.type == kCGPathElementCloseSubpath) {
        CGFloat minX = MIN(startPoint.x, pathStartingPoint.x);
        CGFloat minY = MIN(startPoint.y, pathStartingPoint.y);
        CGFloat maxX = MAX(startPoint.x, pathStartingPoint.x);
        CGFloat maxY = MAX(startPoint.y, pathStartingPoint.y);
        return CGRectMake(minX, minY, maxX - minX, maxY - minY);
    } else {
        CGFloat minX = MIN(startPoint.x, element.points[0].x);
        CGFloat minY = MIN(startPoint.y, element.points[0].y);
        CGFloat maxX = MAX(startPoint.x, element.points[0].x);
        CGFloat maxY = MAX(startPoint.y, element.points[0].y);
        return CGRectMake(minX, minY, maxX - minX, maxY - minY);
    }
}

+ (CGRect)boundsForElement:(CGPathElement)element withStartPoint:(CGPoint)startPoint andSubPathStartingPoint:(CGPoint)pathStartingPoint
{
    return boundsForElement(startPoint, element, pathStartingPoint);
}


/**
 * this will return both the intersection and the difference
 * of the unclosed path with the closed path.
 */
+ (NSArray *)calculateIntersectionAndDifferenceBetween:(UIBezierPath *)myUnclosedPath andPath:(UIBezierPath *)otherClosedPath
{
    __block UIBezierPath *intersectionPath = [UIBezierPath bezierPath];
    __block UIBezierPath *differencePath = [UIBezierPath bezierPath];


    __block CGPoint myLastPoint = CGPointZero;
    [myUnclosedPath iteratePathWithBlock:^(CGPathElement myElement, NSUInteger idx) {
        //
        // convert the single element into a path of 1 element
        UIBezierPath *pathForElement = [UIBezierPath bezierPath];
        [pathForElement moveToPoint:myLastPoint];
        [pathForElement addPathElement:myElement];


        __block DKIntersectionOfPaths *intersection = [[DKIntersectionOfPaths alloc] init];

        do {
            CGRect myElementBounds = pathForElement.bounds;

            intersection.doesIntersect = NO;

            CGPoint otherClosedPathStartingPoint = otherClosedPath.firstPoint;
            __block CGPoint otherLastPoint = CGPointZero;
            [otherClosedPath iteratePathWithBlock:^(CGPathElement otherElement, NSUInteger idx) {

                CGRect otherElementBounds = boundsForElement(otherLastPoint, otherElement, otherClosedPathStartingPoint);

                if (CGRectIntersectsRect(myElementBounds, otherElementBounds)) {
                    // determine if this element actually intersects this
                    // element

                    //
                    // to do that, first flatten the elements, and cache
                    // these flat curves so that we can recall them easily
                    // later if we need to check intersections w/ one of these
                    // elements later
                    UIBezierPath *myFlattedElement = [pathForElement bezierPathByFlatteningPathAndImmutable:YES]; // flattened myElement
                    UIBezierPath *otherFlattedElement = [UIBezierPath bezierPath]; // flattened otherElement
                    [otherFlattedElement moveToPoint:otherLastPoint];
                    [otherFlattedElement addPathElement:otherElement];
                    otherFlattedElement = [otherFlattedElement bezierPathByFlatteningPathAndImmutable:YES];

                    DKIntersectionOfPaths *possibleIntersection = [UIBezierPath firstIntersectionBetween:myFlattedElement andPath:otherFlattedElement];
                    if (possibleIntersection.doesIntersect) {
                        // yep! these two elements intersect.
                        // that means we'll need to chop myElement,
                        // but we might chop it at a closer intersection than
                        // this one...
                        if (possibleIntersection.elementNumberOfIntersection < intersection.elementNumberOfIntersection ||
                            !intersection.doesIntersect) {
                            // check if our intersection happens sooner in the
                            // myElement than any intersection we have already
                            intersection = possibleIntersection;
                        } else {
                            // noop
                        }
                    } else {
                        // does not intersect with this otherElement, but it
                        // might later/earlier in otherPath, so don't change
                        // any state here
                        //
                        // noop
                    }
                } else {
                    // definitely doesn't intersect this part of the
                    // otherPath
                    //
                    // noop
                }
                otherLastPoint = otherElement.points[[UIBezierPath numberOfPointsForElement:otherElement] - 1];
            }];

            if (intersection.doesIntersect) {
                pathForElement = intersection.end;
                [intersectionPath appendPath:intersection.start];
                // swap the paths since we've intersected
                UIBezierPath *swap = intersectionPath;
                intersectionPath = differencePath;
                differencePath = swap;
            } else {
                [intersectionPath appendPath:pathForElement];
            }

        } while (intersection.doesIntersect);

        myLastPoint = pathForElement.lastPoint;
    }];

    return [NSArray arrayWithObjects:intersectionPath, differencePath, nil];
}


/**
 * adds a copy of the input path element
 * to this path
 */
- (void)addPathElement:(CGPathElement)element
{
    if (element.type == kCGPathElementMoveToPoint) {
        [self moveToPoint:element.points[0]];
    } else if (element.type == kCGPathElementCloseSubpath) {
        [self closePath];
    } else if (element.type == kCGPathElementAddLineToPoint) {
        [self addLineToPoint:element.points[0]];
    } else if (element.type == kCGPathElementAddCurveToPoint) {
        [self addCurveToPoint:element.points[2] controlPoint1:element.points[0] controlPoint2:element.points[1]];
    } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
        [self addQuadCurveToPoint:element.points[1] controlPoint:element.points[0]];
    }
}

+ (CGPoint)endPointForPathElement:(CGPathElement)element
{
    if (element.type == kCGPathElementMoveToPoint) {
        return element.points[0];
    } else if (element.type == kCGPathElementAddLineToPoint) {
        return element.points[0];
    } else if (element.type == kCGPathElementAddCurveToPoint) {
        return element.points[2];
    } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
        return element.points[1];
    }
    return CGPointZero;
}

@end


inline CGPoint intersects2D(CGPoint p1, CGPoint p2, CGPoint p3, CGPoint p4)
{
    float firstLineSlopeX, firstLineSlopeY, secondLineSlopeX, secondLineSlopeY;

    firstLineSlopeX = p2.x - p1.x;
    firstLineSlopeY = p2.y - p1.y;

    secondLineSlopeX = p4.x - p3.x;
    secondLineSlopeY = p4.y - p3.y;

    float s, t;
    s = (-firstLineSlopeY * (p1.x - p3.x) + firstLineSlopeX * (p1.y - p3.y)) / (-secondLineSlopeX * firstLineSlopeY + firstLineSlopeX * secondLineSlopeY);
    t = (secondLineSlopeX * (p1.y - p3.y) - secondLineSlopeY * (p1.x - p3.x)) / (-secondLineSlopeX * firstLineSlopeY + firstLineSlopeX * secondLineSlopeY);

    if (s >= 0 && s <= 1 && t >= 0 && t <= 1) {
        float intersectionPointX = p1.x + (t * firstLineSlopeX);
        float intersectionPointY = p1.y + (t * firstLineSlopeY);

        // Collision detected
        return CGPointMake(intersectionPointX, intersectionPointY);
    } else if (isnan(s) && isnan(t)) {
        // parallel
    }

    return CGPointNotFound; // No collision
}

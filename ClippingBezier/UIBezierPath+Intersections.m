//
//  UIBezierPath+Intersections.m
//  ClippingBezier
//
//  Created by Adam Wulf on 2/1/15.
//  Copyright (c) 2015 Adam Wulf. All rights reserved.
//

#import "UIBezierPath+Intersections.h"
#import "PerformanceBezier.h"
#import "UIBezierPath+Clipping_Private.h"
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
- (NSArray *)pathsFromSelfIntersections
{
    NSMutableArray *intersections = [NSMutableArray array];

    __block UIBezierPath *seenSoFar = [self buildEmptyPath];
    NSMutableArray *output = [NSMutableArray array];
    __block CGPoint lastMyPoint = CGPointZero;

    //
    // i think the crash that's happening here is because
    // i'm nesting calls to CGPathApply() (from iteratePathWithBlock)
    //
    // as an alternative. i've unwrapped the first iteratePathWithBlock,
    // storing each element in an array, and then looping over that array
    int elementCount = (int)[self elementCount];
    __block CGPathElement *selfElements = (CGPathElement *)malloc(sizeof(CGPathElement) * elementCount);
    if (!selfElements) {
        @throw [NSException exceptionWithName:@"Memory Exception" reason:@"can't malloc" userInfo:nil];
    }
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger index) {
        // need to copy the element so that we get
        // a copy of the .points as well
        CGPathElement *ptr = [UIBezierPath copyCGPathElement:&element];
        selfElements[index] = *ptr;
    }];


    BOOL (^pointIsNearToPoint)(CGPoint p1, CGPoint p2) = ^BOOL(CGPoint p1, CGPoint p2) {
        // when two segments start/end at the same point, they are sometimes found
        // as *almost* the same point. this makes sure we take this rounding error
        // into account when two segments intersect at endpoints
        CGFloat close = .00001;
        CGFloat xDiff = ABS(p2.x - p1.x);
        CGFloat yDiff = ABS(p2.y - p1.y);
        return xDiff < close && yDiff < close;
    };

    // at this point, the selfElements is an array of CGPathElements
    // that I can loop over without needing to nest calls of CGPathApply
    for (int index = 0; index < elementCount; index++) {
        CGPathElement element = selfElements[index];
        if (element.type == kCGPathElementAddLineToPoint) {
            __block CGPoint lastSeenPoint = CGPointZero;
            __block CGFloat distanceSoFar = 0;
            __strong UIBezierPath *iterateOnThisPath = seenSoFar;
            [iterateOnThisPath iteratePathWithBlock:^(CGPathElement seenElement, NSUInteger idx) {
                if (seenElement.type == kCGPathElementAddLineToPoint) {
                    CGPoint intersection = intersects2D(lastMyPoint, element.points[0], lastSeenPoint, seenElement.points[0]);
                    if (!CGPointEqualToPoint(intersection, CGPointNotFound) &&
                        !pointIsNearToPoint(intersection, lastMyPoint)) {
                        [intersections addObject:[NSValue valueWithCGPoint:intersection]];

                        // ok, we have an intersection
                        UIBezierPath *outPath = [seenSoFar bezierPathByTrimmingFromLength:distanceSoFar + [UIBezierPath distance:lastSeenPoint p2:intersection]];
                        if (![outPath elementCount]) {
                            outPath = [seenSoFar bezierPathByTrimmingFromLength:distanceSoFar + [UIBezierPath distance:lastSeenPoint p2:intersection]];
                        }
                        [outPath addLineToPoint:intersection];
                        [output addObject:outPath];

                        seenSoFar = [seenSoFar bezierPathByTrimmingToLength:distanceSoFar + [UIBezierPath distance:lastSeenPoint p2:intersection]];
                        lastSeenPoint = intersection;
                    }
                    distanceSoFar += [UIBezierPath distance:lastSeenPoint p2:seenElement.points[0]];
                }
                lastSeenPoint = seenElement.points[0];
            }];
            [seenSoFar addPathElement:element];
        } else {
            [seenSoFar addPathElement:element];
        }
        lastMyPoint = element.points[0];
    }
    // cleanup selfElements!
    // making sure to free .points
    // since we deep copied the element
    for (int i = 0; i < elementCount; i++) {
        free(selfElements[i].points);
    }
    free(selfElements);

    [output addObject:seenSoFar];

    return output;
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
    UIBezierPath *pathToFirstIntersection = [myFlatPath buildEmptyPath];
    UIBezierPath *restOfPath = [myFlatPath buildEmptyPath];

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
    __block UIBezierPath *intersectionPath = [myUnclosedPath buildEmptyPath];
    __block UIBezierPath *differencePath = [myUnclosedPath buildEmptyPath];


    __block CGPoint myLastPoint = CGPointZero;
    [myUnclosedPath iteratePathWithBlock:^(CGPathElement myElement, NSUInteger idx) {
        //
        // convert the single element into a path of 1 element
        UIBezierPath *pathForElement = [myUnclosedPath buildEmptyPath];
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
                    UIBezierPath *otherFlattedElement = [myUnclosedPath buildEmptyPath]; // flattened otherElement
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

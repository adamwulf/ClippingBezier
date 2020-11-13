//
//  UIBezierPath+Ahmed.m
//  ClippingBezier
//
//  Created by Adam Wulf on 10/6/12.
//  Copyright (c) 2012 Graceful Construction, LLC. All rights reserved.
//

#import "UIBezierPath+Ahmed.h"
#import <objc/runtime.h>
#import <PerformanceBezier/PerformanceBezier.h>


static const CGFloat kIdealFlatness = .01;

@implementation UIBezierPath (Ahmed)


#pragma mark - Properties


/**
 * this is a property on the category, as described in:
 * https://github.com/techpaa/iProperties
 */
- (void)setIsFlat:(BOOL)isFlat
{
    [self pathProperties].isFlat = isFlat;
}

/**
 * return YES if this bezier path is made up of only
 * moveTo, closePath, and lineTo elements
 *
 * TODO
 * this method helps caching flattened paths internally
 * to this category, but is not yet fit for public use.
 *
 * detecting when this path is flat would mean we'd have
 * to also swizzle the constructors to bezier paths
 */
- (BOOL)isFlat
{
    return [self pathProperties].isFlat;
}

#pragma mark - UIBezierPath

- (UIBezierPath *)bezierPathByFlatteningPath
{
    return [self bezierPathByFlatteningPathWithFlatnessThreshold:kIdealFlatness];
}

- (UIBezierPath *)bezierPathByFlatteningPathAndImmutable:(BOOL)returnCopy
{
    return [self bezierPathByFlatteningPathWithFlatnessThreshold:kIdealFlatness immutable:returnCopy];
}

/**
 * call this method on a UIBezierPath to generate
 * a new flattened path
 *
 * This category is named after Athar Luqman Ahmad, who
 * wrote a masters thesis about minimizing the number of
 * lines required to flatten a bezier curve
 *
 * The thesis is available here:
 * http://www.cis.usouthal.edu/~hain/general/Theses/Ahmad_thesis.pdf
 *
 * The algorithm that I use as of 10/09/2012 is a simple
 * recursive algorithm that doesn't use any of ahmed's
 * optimizations yet
 *
 * TODO: add in Ahmed's optimizations
 */
- (UIBezierPath *)bezierPathByFlatteningPathWithFlatnessThreshold:(CGFloat)flatnessThreshold
{
    return [self bezierPathByFlatteningPathWithFlatnessThreshold:flatnessThreshold immutable:NO];
}
/**
 * @param willBeImmutable YES if this function should return a distinct UIBezier, NO otherwise
 *
 * if the caller plans to modify the returned path, then shouldBeImmutable should
 * be called with NO.
 *
 * if the caller only plans to iterate over and look at the returned value,
 * then shouldBeImmutable should be YES - this is considerably faster to not
 * return a copy if the value will be treated as immutable
 */
- (UIBezierPath *)bezierPathByFlatteningPathWithFlatnessThreshold:(CGFloat)flatnessThreshold immutable:(BOOL)willBeImmutable
{
    UIBezierPathProperties *props = [self pathProperties];
    UIBezierPath *ret = props.bezierPathByFlatteningPath;
    if (ret) {
        if (willBeImmutable)
            return ret;
        return [ret copy];
    }
    if (self.isFlat) {
        if (willBeImmutable)
            return self;
        return [self copy];
    }

    __block NSInteger flattenedElementCount = 0;
    UIBezierPath *newPath = [UIBezierPath bezierPath];
    newPath.lineWidth = self.lineWidth;
    newPath.lineCapStyle = self.lineCapStyle;
    newPath.lineJoinStyle = self.lineJoinStyle;

    NSInteger elements = [self elementCount];
    NSInteger n;
    CGPoint pointForClose = CGPointMake(0.0, 0.0);
    CGPoint lastPoint = CGPointMake(0.0, 0.0);

    for (n = 0; n < elements; ++n) {
        CGPoint points[3];
        CGPathElement element = [self elementAtIndex:n associatedPoints:points];

        switch (element.type) {
            case kCGPathElementMoveToPoint:
                [newPath moveToPoint:points[0]];
                pointForClose = lastPoint = points[0];
                flattenedElementCount++;
                continue;

            case kCGPathElementAddLineToPoint:
                [newPath addLineToPoint:points[0]];
                lastPoint = points[0];
                flattenedElementCount++;
                break;

            case kCGPathElementAddQuadCurveToPoint:
            case kCGPathElementAddCurveToPoint: {
                //
                // handle both curve types gracefully
                CGPoint curveTo;
                CGPoint ctrl1;
                CGPoint ctrl2;
                if (element.type == kCGPathElementAddQuadCurveToPoint) {
                    curveTo = element.points[1];
                    ctrl1 = element.points[0];
                    ctrl2 = ctrl1;
                } else { // element.type == kCGPathElementAddCurveToPoint
                    curveTo = element.points[2];
                    ctrl1 = element.points[0];
                    ctrl2 = element.points[1];
                }

                //
                // ok, this is the bezier for our current element
                CGPoint bezier[4] = {lastPoint, ctrl1, ctrl2, curveTo};


                //
                // define our recursive function that will
                // help us split the curve up as needed
                __block __weak void (^weak_flattenCurve)(UIBezierPath *newPath, CGPoint startPoint, CGPoint bez[4]);
                void (^flattenCurve)(UIBezierPath *newPath, CGPoint startPoint, CGPoint bez[4]);
                weak_flattenCurve = flattenCurve = ^(UIBezierPath *newPath, CGPoint startPoint, CGPoint bez[4]) {
                    //
                    // first, calculate the error rate for
                    // a line segement between the start/end points
                    // vs the curve
                    CGPoint onCurve = [UIBezierPath pointAtT:.5 forBezier:bez];
                    CGFloat error = [UIBezierPath distanceOfPointToLine:onCurve start:startPoint end:bez[2]];

                    //
                    // if that error is less than our accepted
                    // level of error, then just add a line,
                    //
                    // otherwise, split the curve in half and recur
                    if (error <= flatnessThreshold) {
                        [newPath addLineToPoint:bez[3]];
                        flattenedElementCount++;
                    } else {
                        CGPoint bez1[4], bez2[4];
                        [UIBezierPath subdivideBezierAtT:bez bez1:bez1 bez2:bez2 t:.5];
                        // now we've split the curve in half, and have
                        // two bezier curves bez1 and bez2. recur
                        // on these two halves
                        weak_flattenCurve(newPath, startPoint, bez1);
                        weak_flattenCurve(newPath, startPoint, bez2);
                    }
                };

                flattenCurve(newPath, lastPoint, bezier);

                lastPoint = points[2];
                break;
            }

            case kCGPathElementCloseSubpath:
                [newPath closePath];
                lastPoint = pointForClose;
                flattenedElementCount++;
                break;

            default:
                break;
        }
    }

    // since we just built the flattened path
    // we know how many elements there are, so cache that
    UIBezierPathProperties *newPathProps = [newPath pathProperties];
    newPathProps.cachedElementCount = flattenedElementCount;

    props.bezierPathByFlatteningPath = newPath;

    return [self bezierPathByFlatteningPathAndImmutable:willBeImmutable];
}

@end

//
//  UIBezierPath+ClippingCPP.m
//  ClippingBezier
//
//  Created by Adam Wulf on 4/5/21.
//

#import "ClippingBezier.h"
#import "UIBezierPath+Clipping_Private.h"
#include "interval.h"
#include <vector>
#include "bezierclip.hxx"
#include "point.h"
#include "NearestPoint.h"
#include "bezier-clipping.h"

using namespace Geom;

@implementation UIBezierPath (ClippingCPP)


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

@end

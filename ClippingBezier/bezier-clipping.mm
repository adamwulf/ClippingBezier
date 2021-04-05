/** \file
 * Bezier interpolation for inkscape drawing code.
 */
/*
 * Original code published in:
 *   An Algorithm for Automatically Fitting Digitized Curves
 *   by Philip J. Schneider
 *  "Graphics Gems", Academic Press, 1990
 *
 * Authors:
 *   Philip J. Schneider
 *   Lauris Kaplinski <lauris@kaplinski.com>
 *   Peter Moulder <pmoulder@mail.csse.monash.edu.au>
 *
 * Copyright (C) 1990 Philip J. Schneider
 * Copyright (C) 2001 Lauris Kaplinski
 * Copyright (C) 2001 Ximian, Inc.
 * Copyright (C) 2003,2004 Monash University
 *
 * This library is free software; you can redistribute it and/or
 * modify it either under the terms of the GNU Lesser General Public
 * License version 2.1 as published by the Free Software Foundation
 * (the "LGPL") or, at your option, under the terms of the Mozilla
 * Public License Version 1.1 (the "MPL"). If you do not alter this
 * notice, a recipient may use your version of this file under either
 * the MPL or the LGPL.
 *
 * You should have received a copy of the LGPL along with this library
 * in the file COPYING-LGPL-2.1; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 * You should have received a copy of the MPL along with this library
 * in the file COPYING-MPL-1.1
 *
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY
 * OF ANY KIND, either express or implied. See the LGPL or the MPL for
 * the specific language governing rights and limitations.
 *
 */

#include "interval.h"
#include <vector>
#include "bezierclip.hxx"
#include "point.h"
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import "PerformanceBezier.h"
#import "NearestPoint.h"
#include "bezier-clipping.h"

// clarify Geom::Point vs MacTypes
using Geom::Point;

// TODO: change the namespace so i don't conflict with the actual Geom namespace
namespace Geom
{
#pragma mark - interval routines

/*
     * Map the sub-interval I in [0,1] into the interval J and assign it to J
     */
inline void map_to(Interval &J, Interval const &I)
{
    double length = J.extent();
    J[1] = I.max() * length + J[0];
    J[0] = I.min() * length + J[0];
}

/*
     * The interval [1,0] is used to represent the empty interval, this routine
     * is just an helper function for creating such an interval
     */
inline Interval make_empty_interval()
{
    Interval I(0);
    I[0] = 1;
    return I;
}

const Interval UNIT_INTERVAL(0, 1);
const double MAX_PRECISION = 1e-8;
const double MIN_CLIPPED_SIZE_THRESHOLD = 0.8;
const Interval EMPTY_INTERVAL = make_empty_interval();
const Interval H1_INTERVAL(0, 0.5);
const Interval H2_INTERVAL(0.5 + MAX_PRECISION, 1.0);


#pragma mark - bezier curve routines

/*
     * Return true if all the Bezier curve control points are near,
     * false otherwise
     */
inline bool is_constant(std::vector<Point> const &A, double precision)
{
    for (unsigned int i = 1; i < A.size(); ++i) {
        if (!are_near(A[i][X], A[0][X], precision) ||
            !are_near(A[i][Y], A[0][Y], precision))
            return false;
    }
    return true;
}

inline bool is_near(std::vector<Point> const &A, std::vector<Point> const &B, double precision)
{
    if (is_constant(A, precision) && is_constant(B, precision) &&
        are_near(A[0][X], B[0][X], precision) &&
        are_near(A[0][Y], B[0][Y], precision)) {
        return true;
    }
    return false;
}

/*
     * Compute the hodograph of the bezier curve B and return it in D
     */
inline void derivative(std::vector<Point> &D, std::vector<Point> const &B)
{
    D.clear();
    size_t sz = B.size();
    if (sz == 0)
        return;
    if (sz == 1) {
        D.resize(1, Point(0, 0));
        return;
    }
    size_t n = sz - 1;
    D.reserve(n);
    for (size_t i = 0; i < n; ++i) {
        D.push_back(n * (B[i + 1] - B[i]));
    }
}

/*
     * Compute the hodograph of the Bezier curve B rotated of 90 degree
     * and return it in D; we have N(t) orthogonal to B(t) for any t
     */
inline void normal(std::vector<Point> &N, std::vector<Point> const &B)
{
    derivative(N, B);
    for (size_t i = 0; i < N.size(); ++i) {
        N[i] = rot90(N[i]);
    }
}

/*
     *  Compute the portion of the Bezier curve "B" wrt the interval [0,t]
     */
inline void left_portion(Coord t, std::vector<Point> &B)
{
    size_t n = B.size();
    for (size_t i = 1; i < n; ++i) {
        for (size_t j = n - 1; j > i - 1; --j) {
            B[j] = lerp(t, B[j - 1], B[j]);
        }
    }
}

/*
     *  Compute the portion of the Bezier curve "B" wrt the interval [t,1]
     */
inline void right_portion(Coord t, std::vector<Point> &B)
{
    size_t n = B.size();
    for (size_t i = 1; i < n; ++i) {
        for (size_t j = 0; j < n - i; ++j) {
            B[j] = lerp(t, B[j], B[j + 1]);
        }
    }
}

/*
     *  Compute the portion of the Bezier curve "B" wrt the interval "I"
     */
inline void portion(std::vector<Point> &B, Interval const &I)
{
    if (I.min() == 0) {
        if (I.max() == 1)
            return;
        left_portion(I.max(), B);
        return;
    }
    right_portion(I.min(), B);
    if (I.max() == 1)
        return;
    double t = I.extent() / (1 - I.min());
    left_portion(t, B);
}


#pragma mark - clipping

inline size_t get_precision(Interval const &I)
{
    double d = I.extent();
    double e = 0.1, p = 10;
    int n = 0;
    while (n < 16 && d < e) {
        p *= 10;
        e = 1 / p;
        ++n;
    }
    return n;
}


/*
     * iterate
     *
     * input:
     * A, B: control point sets of two bezier curves
     * domA, domB: real parameter intervals of the two curves
     * precision: required computational precision of the returned parameter ranges
     * output:
     * domsA, domsB: sets of parameter intervals
     *
     * The parameter intervals are computed by using a Bezier clipping algorithm,
     * in case the clipping doesn't shrink the initial interval more than 20%,
     * a subdivision step is performed.
     * If during the computation one of the two curve interval length becomes less
     * than MAX_PRECISION the routine exits indipendently by the precision reached
     * in the computation of the other curve interval.
     */
void iterate(std::vector<Interval> &domsA,
             std::vector<Interval> &domsB,
             std::vector<Point> const &A,
             std::vector<Point> const &B,
             Interval const &domA,
             Interval const &domB,
             double precision,
             clip_fnc_t *clip)
{
    // in order to limit recursion
    static size_t counter = 0;
    if (domA.extent() == 1 && domB.extent() == 1)
        counter = 0;
    if (++counter > 100) {
        return;
    }
#if VERBOSE
    std::cerr << ">> curve subdision performed <<" << std::endl;
    std::cerr << "dom(A) : " << domA << std::endl;
    std::cerr << "dom(B) : " << domB << std::endl;
//    std::cerr << "angle(A) : " << angle(A) << std::endl;
//    std::cerr << "angle(B) : " << angle(B) << std::endl;
#endif

    if (precision < MAX_PRECISION)
        precision = MAX_PRECISION;

    std::vector<Point> pA = A;
    std::vector<Point> pB = B;
    std::vector<Point> *C1 = &pA;
    std::vector<Point> *C2 = &pB;

    Interval dompA = domA;
    Interval dompB = domB;
    Interval *dom1 = &dompA;
    Interval *dom2 = &dompB;

    Interval dom;

    size_t iter = 0;
    while (++iter < 100 && (dompA.extent() >= MAX_PRECISION || dompB.extent() >= MAX_PRECISION) && !is_constant(*C1, precision) && !is_constant(*C2, precision)) {
// this loop used to not consider if C1 or C2 were or were not
// constant. It used to only check at the tail of the loop, so if anyone
// were to pass in point Bezier paths, then it'd die a horrible death
// in the clip() call below.
//
// now I always check so I can recur blindly as needed


#if VERBOSE
        std::cerr << "iter: " << iter << std::endl;
#endif
        clip(dom, *C1, *C2, precision);

        // [1,0] is utilized to represent an empty interval
        if (dom == EMPTY_INTERVAL) {
#if VERBOSE
            std::cerr << "dom: empty" << std::endl;
#endif
            return;
        }
#if VERBOSE
        std::cerr << "dom : " << dom << std::endl;
#endif
        // all other cases where dom[0] > dom[1] are invalid
        if (dom.min() > dom.max()) {
            assert(dom.min() < dom.max());
        }

        //            map_to(*dom1, domm);
        map_to(*dom2, dom);

        // it's better to stop before losing computational precision
        if (dom2->extent() <= MAX_PRECISION || dom1->extent() <= MAX_PRECISION) {
#if VERBOSE
            std::cerr << "beyond max precision limit" << std::endl;
#endif
            break;
        }

        //            portion(*C1, domm);
        portion(*C2, dom);
        if (is_constant(*C2, precision)) {
#if VERBOSE
            std::cerr << "new curve portion is constant" << std::endl;
#endif
            break;
        }
        // if we have clipped less than 20% than we need to subdive the curve
        // with the largest domain into two sub-curves
        if (dom.extent() > MIN_CLIPPED_SIZE_THRESHOLD) {
#if VERBOSE
            std::cerr << "clipped less than 20% : " << dom.extent() << std::endl;
            std::cerr << "angle(pA) : " << angle(pA) << std::endl;
            std::cerr << "angle(pB) : " << angle(pB) << std::endl;
#endif
            std::vector<Point> pC1, pC2;
            Interval dompC1, dompC2;
            if (dompA.extent() > dompB.extent()) {
                if ((dompA.extent() / 2) < MAX_PRECISION) {
                    break;
                }
                pC1 = pC2 = pA;
                portion(pC1, H1_INTERVAL);
                if (is_constant(pC1, precision)) {
#if VERBOSE
                    std::cerr << "new curve portion pC1 is constant" << std::endl;
#endif
                    break;
                }
                portion(pC2, H2_INTERVAL);
                if (is_constant(pC2, precision)) {
#if VERBOSE
                    std::cerr << "new curve portion pC2 is constant" << std::endl;
#endif
                    break;
                }
                dompC1 = dompC2 = dompA;
                map_to(dompC1, H1_INTERVAL);
                map_to(dompC2, H2_INTERVAL);
                iterate(domsA, domsB, pC1, pB, dompC1, dompB, precision, clip);
                iterate(domsA, domsB, pC2, pB, dompC2, dompB, precision, clip);
            } else {
                if ((dompB.extent() / 2) < MAX_PRECISION) {
                    break;
                }
                pC1 = pC2 = pB;
                portion(pC1, H1_INTERVAL);
                if (is_constant(pC1, precision)) {
#if VERBOSE
                    std::cerr << "new curve portion pC1 is constant" << std::endl;
#endif
                    break;
                }
                portion(pC2, H2_INTERVAL);
                if (is_constant(pC2, precision)) {
#if VERBOSE
                    std::cerr << "new curve portion pC2 is constant" << std::endl;
#endif
                    break;
                }
                dompC1 = dompC2 = dompB;
                map_to(dompC1, H1_INTERVAL);
                map_to(dompC2, H2_INTERVAL);
                iterate(domsB, domsA, pC1, pA, dompC1, dompA, precision, clip);
                iterate(domsB, domsA, pC2, pA, dompC2, dompA, precision, clip);
            }
            return;
        }

        std::swap(C1, C2);
        std::swap(dom1, dom2);
#if VERBOSE
        std::cerr << "dom(pA) : " << dompA << std::endl;
        std::cerr << "dom(pB) : " << dompB << std::endl;
#endif
    }
    size_t precA = get_precision(dompA);
    size_t precB = get_precision(dompB);

    bool precisionIsTerrible = false;

    if (precA > 0 || precB > 0) {
        //
        // here we need to look to see how
        // precise our measurements are. if
        // one of the curves is more precise than
        // the other, then we're going to adjust
        // the output values of the less precise
        // to better match
        if (precB > precA) {
            // this takes the more precise value,
            // finds the point on the curve that matches
            // the tValue of the intersection.
            //
            // then we reverse that and take that point
            // to infer the T value for the less precise
            // curve
            //
            // precision of b is greater than a,
            // so trust it. find the T value
            // for the point closest to the value
            // of b
            CGFloat midT = dompB.middle();
            CGPoint Bbez[4];
            Bbez[0] = CGPointMake(B[0][X], B[0][Y]);
            Bbez[1] = CGPointMake(B[1][X], B[1][Y]);
            Bbez[2] = CGPointMake(B[2][X], B[2][Y]);
            Bbez[3] = CGPointMake(B[3][X], B[3][Y]);
            CGPoint Abez[4];
            Abez[0] = CGPointMake(A[0][X], A[0][Y]);
            Abez[1] = CGPointMake(A[1][X], A[1][Y]);
            Abez[2] = CGPointMake(A[2][X], A[2][Y]);
            Abez[3] = CGPointMake(A[3][X], A[3][Y]);
            double currWidth = domB[1] - domB[0];
            midT = (midT - domB[0]) / currWidth;
            CGPoint pointAtT = [UIBezierPath pointAtT:midT forBezier:Bbez];
            double currTValue;
            CGPoint otherPointAtT = NearestPointOnCurve(pointAtT, Abez, &currTValue);

            // now i need to scale the tvalue to
            // the current clip value
            currWidth = domA[1] - domA[0];
            currTValue = domA[0] + currTValue * currWidth;
            dompA[0] = currTValue;
            dompA[1] = currTValue;
#if VERBOSE
            NSLog(@"Bbez precision %f and %f", ABS(otherPointAtT.x - pointAtT.x), ABS(otherPointAtT.y - pointAtT.y));
#endif
            if (ABS(otherPointAtT.x - pointAtT.x) > 1 || ABS(otherPointAtT.y - pointAtT.y) > 1) {
                // even after taking our more precise curve and trying to find
                // the nearest point on the other curve, we still have an "intersection"
                // that is further than 1pt for either curve.
                //
                // this is a near intersection, but a miss, so mark that precisionIsTerrible
                precisionIsTerrible = YES;
            }
        } else if (precA > precB) {
            CGFloat midT = dompA.middle();
            CGPoint Abez[4];
            Abez[0] = CGPointMake(A[0][X], A[0][Y]);
            Abez[1] = CGPointMake(A[1][X], A[1][Y]);
            Abez[2] = CGPointMake(A[2][X], A[2][Y]);
            Abez[3] = CGPointMake(A[3][X], A[3][Y]);
            CGPoint Bbez[4];
            Bbez[0] = CGPointMake(B[0][X], B[0][Y]);
            Bbez[1] = CGPointMake(B[1][X], B[1][Y]);
            Bbez[2] = CGPointMake(B[2][X], B[2][Y]);
            Bbez[3] = CGPointMake(B[3][X], B[3][Y]);
            double currWidth = domA[1] - domA[0];
            midT = (midT - domA[0]) / currWidth;
            CGPoint pointAtT = [UIBezierPath pointAtT:midT forBezier:Abez];
            double currTValue;
            // domB could be (0.0-0.5)
            // tvalue would be between 0 and 1.
            // i need to effectively stretch the domB to a full 0-1
            // and find the stretched t value too
            CGPoint otherPointAtT = NearestPointOnCurve(pointAtT, Bbez, &currTValue);
            currWidth = domB[1] - domB[0];
            currTValue = domB[0] + currTValue * currWidth;
            dompB[0] = currTValue;
            dompB[1] = currTValue;
#if VERBOSE
            NSLog(@"Abez precision %f and %f", ABS(otherPointAtT.x - pointAtT.x), ABS(otherPointAtT.y - pointAtT.y));
#endif
            if (ABS(otherPointAtT.x - pointAtT.x) > 1 || ABS(otherPointAtT.y - pointAtT.y) > 1) {
                // even after taking our more precise curve and trying to find
                // the nearest point on the other curve, we still have an "intersection"
                // that is further than 1pt for either curve.
                //
                // this is a near intersection, but a miss, so mark that precisionIsTerrible
                precisionIsTerrible = YES;
            }
        }
        if (!precisionIsTerrible) {
            // sometimes, if an input curve is already
            // a point, then our algorithm fails
            //
            // so we should only add to our answer output if
            // our precision warrents it
            domsA.push_back(dompA);
            domsB.push_back(dompB);
        }
    }
}

/*
     * get_solutions
     *
     *  input: A, B       - set of control points of two Bezier curve
     *  input: precision  - required precision of computation -> applicable to the Point precision, not tvalue precision
     *                      tvalues are always compared against MAX_PRECISION
     *  input: clip       - the routine used for clipping
     *  output: xs        - set of pairs of parameter values
     *                      at which the clipping algorithm converges
     *
     *  This routine is based on the Bezier Clipping Algorithm,
     *  see: Sederberg - Computer Aided Geometric Design
     */
void get_solutions(NSMutableArray *xs,
                   std::vector<Point> const &A,
                   std::vector<Point> const &B,
                   double precision,
                   clip_fnc_t *clip)
{
    if (is_constant(A, precision) || is_constant(B, precision)) {
        // if our input is already a point, then bail out
        return;
    }

    CGPoint ci;
    std::vector<Interval> domsA, domsB;
    iterate(domsA, domsB, A, B, UNIT_INTERVAL, UNIT_INTERVAL, precision, clip);
    if (domsA.size() != domsB.size()) {
        assert(domsA.size() == domsB.size());
    }
    [xs removeAllObjects];

    for (size_t i = 0; i < domsA.size(); ++i) {
#if VERBOSE
        std::cerr << i << " : domA : " << domsA[i] << std::endl;
        std::cerr << "extent A: " << domsA[i].extent() << "  ";
        std::cerr << "precision A: " << get_precision(domsA[i]) << std::endl;
        std::cerr << i << " : domB : " << domsB[i] << std::endl;
        std::cerr << "extent B: " << domsB[i].extent() << "  ";
        std::cerr << "precision B: " << get_precision(domsB[i]) << std::endl;
#endif
        size_t __attribute__((unused)) prec = get_precision(domsA[i]);
        Coord __attribute__((unused)) ext = domsA[i].extent();

        ci.x = domsA[i].middle();
        ci.y = domsB[i].middle();
        [xs addObject:[NSValue valueWithCGPoint:ci]];
    }
}


#pragma mark -  convex hull

/*
     * return true in case the oriented polyline p0, p1, p2 is a right turn
     */
inline bool is_a_right_turn(Point const &p0, Point const &p1, Point const &p2)
{
    if (p1 == p2)
        return false;
    Point q1 = p1 - p0;
    Point q2 = p2 - p0;
    if (q1 == -q2)
        return false;
    return (cross(q1, q2) < 0);
}

/*
     * return true if p < q wrt the lexicographyc order induced by the coordinates
     */
struct lex_less {
    bool operator()(Point const &p, Point const &q)
    {
        return ((p[X] < q[X]) || (p[X] == q[X] && p[Y] < q[Y]));
    }
};

/*
     * return true if p > q wrt the lexicographyc order induced by the coordinates
     */
struct lex_greater {
    bool operator()(Point const &p, Point const &q)
    {
        return ((p[X] > q[X]) || (p[X] == q[X] && p[Y] > q[Y]));
    }
};

/*
     * Compute the convex hull of a set of points.
     * The implementation is based on the Andrew's scan algorithm
     * note: in the Bezier clipping for collinear normals it seems
     * to be more stable wrt the Graham's scan algorithm and in general
     * a bit quikier
     */
void convex_hull(std::vector<Point> &P)
{
    size_t n = P.size();
    if (n < 2)
        return;
    std::sort(P.begin(), P.end(), lex_less());
    if (n < 4)
        return;
    // upper hull
    size_t u = 2;
    for (size_t i = 2; i < n; ++i) {
        while (u > 1 && !is_a_right_turn(P[u - 2], P[u - 1], P[i])) {
            --u;
        }
        std::swap(P[u], P[i]);
        ++u;
    }
    std::sort(P.begin() + u, P.end(), lex_greater());
    std::rotate(P.begin(), P.begin() + 1, P.end());
    // lower hull
    size_t l = u;
    size_t k = u - 1;
    for (size_t i = l; i < n; ++i) {
        while (l > k && !is_a_right_turn(P[l - 2], P[l - 1], P[i])) {
            --l;
        }
        std::swap(P[l], P[i]);
        ++l;
    }
    P.resize(l);
}


#pragma mark - intersection

/*
     *  Make up an orientation line using the control points c[i] and c[j]
     *  the line is returned in the output parameter "l" in the form of a 3 element
     *  vector : l[0] * x + l[1] * y + l[2] == 0; the line is normalized.
     */
inline void orientation_line(std::vector<double> &l,
                             std::vector<Point> const &c,
                             size_t i, size_t j)
{
    l[0] = c[j][Y] - c[i][Y];
    l[1] = c[i][X] - c[j][X];
    l[2] = cross(c[i], c[j]);
    double length = std::sqrt(l[0] * l[0] + l[1] * l[1]);
    assert(length != 0);
    l[0] /= length;
    l[1] /= length;
    l[2] /= length;
}

/*
     * Pick up an orientation line for the Bezier curve "c" and return it in
     * the output parameter "l"
     */
inline void pick_orientation_line(std::vector<double> &l,
                                  std::vector<Point> const &c,
                                  double precision)
{
    size_t i = c.size();
    while (--i > 0 && are_near(c[0], c[i], precision)) {
    }
    if (i == 0) {
        // this should never happen because when a new curve portion is created
        // we check that it is not constant;
        // however this requires that the precision used in the is_constant
        // routine has to be the same used here in the are_near test
        assert(i != 0);
    }
    orientation_line(l, c, 0, i);
    //std::cerr << "i = " << i << std::endl;
}

/*
     *  Compute the signed distance of the point "P" from the normalized line l
     */
inline double distancePtoL(Point const &P, std::vector<double> const &l)
{
    return l[X] * P[X] + l[Y] * P[Y] + l[2];
}

/*
     * Compute the min and max distance of the control points of the Bezier
     * curve "c" from the normalized orientation line "l".
     * This bounds are returned through the output Interval parameter"bound".
     */
inline void fat_line_bounds(Interval &bound,
                            std::vector<Point> const &c,
                            std::vector<double> const &l)
{
    bound[0] = 0;
    bound[1] = 0;
    double d;
    for (size_t i = 0; i < c.size(); ++i) {
        d = distancePtoL(c[i], l);
        if (bound[0] > d)
            bound[0] = d;
        if (bound[1] < d)
            bound[1] = d;
    }
}

/*
     * return the x component of the intersection point between the line
     * passing through points p1, p2 and the line Y = "y"
     */
inline double intersect(Point const &p1, Point const &p2, double y)
{
    // we are sure that p2[Y] != p1[Y] because this routine is called
    // only when the lower or the upper bound is crossed
    double dy = (p2[Y] - p1[Y]);
    double s = (y - p1[Y]) / dy;
    return (p2[X] - p1[X]) * s + p1[X];
}


/*
     * Clip the Bezier curve "B" wrt the fat line defined by the orientation
     * line "l" and the interval range "bound", the new parameter interval for
     * the clipped curve is returned through the output parameter "dom"
     */
void clip_interval(Interval &dom,
                   std::vector<Point> const &B,
                   std::vector<double> const &l,
                   Interval const &bound)
{
    double n = B.size() - 1; // number of sub-intervals
    std::vector<Point> D; // distance curve control points
    D.reserve(B.size());
    double d;
    for (size_t i = 0; i < B.size(); ++i) {
        d = distancePtoL(B[i], l);
        D.push_back(Point(i / n, d));
    }
    //print(D);

    convex_hull(D);
    std::vector<Point> &p = D;
    //print(p);

    bool plower, phigher;
    bool clower, chigher;
    double t, tmin = 1, tmax = 0;
    //std::cerr << "bound : " << bound << std::endl;

    plower = (p[0][Y] < bound.min());
    phigher = (p[0][Y] > bound.max());
    if (!(plower || phigher)) // inside the fat line
    {
        if (tmin > p[0][X])
            tmin = p[0][X];
        if (tmax < p[0][X])
            tmax = p[0][X];
        //std::cerr << "0 : inside " << p[0]
        //          << " : tmin = " << tmin << ", tmax = " << tmax << std::endl;
    }

    for (size_t i = 1; i < p.size(); ++i) {
        clower = (p[i][Y] < bound.min());
        chigher = (p[i][Y] > bound.max());
        if (!(clower || chigher)) // inside the fat line
        {
            if (tmin > p[i][X])
                tmin = p[i][X];
            if (tmax < p[i][X])
                tmax = p[i][X];
            //std::cerr << i << " : inside " << p[i]
            //          << " : tmin = " << tmin << ", tmax = " << tmax
            //          << std::endl;
        }
        if (clower != plower) // cross the lower bound
        {
            t = intersect(p[i - 1], p[i], bound.min());
            if (tmin > t)
                tmin = t;
            if (tmax < t)
                tmax = t;
            plower = clower;
            //std::cerr << i << " : lower " << p[i]
            //          << " : tmin = " << tmin << ", tmax = " << tmax
            //          << std::endl;
        }
        if (chigher != phigher) // cross the upper bound
        {
            t = intersect(p[i - 1], p[i], bound.max());
            if (tmin > t)
                tmin = t;
            if (tmax < t)
                tmax = t;
            phigher = chigher;
            //std::cerr << i << " : higher " << p[i]
            //          << " : tmin = " << tmin << ", tmax = " << tmax
            //          << std::endl;
        }
    }

    // we have to test the closing segment for intersection
    size_t last = p.size() - 1;
    clower = (p[0][Y] < bound.min());
    chigher = (p[0][Y] > bound.max());
    if (clower != plower) // cross the lower bound
    {
        t = intersect(p[last], p[0], bound.min());
        if (tmin > t)
            tmin = t;
        if (tmax < t)
            tmax = t;
        //std::cerr << "0 : lower " << p[0]
        //          << " : tmin = " << tmin << ", tmax = " << tmax << std::endl;
    }
    if (chigher != phigher) // cross the upper bound
    {
        t = intersect(p[last], p[0], bound.max());
        if (tmin > t)
            tmin = t;
        if (tmax < t)
            tmax = t;
        //std::cerr << "0 : higher " << p[0]
        //          << " : tmin = " << tmin << ", tmax = " << tmax << std::endl;
    }

    dom[0] = tmin;
    dom[1] = tmax;
}


#pragma mark - Clipping functions

void intersections_clip(Interval &dom,
                        std::vector<Point> const &A,
                        std::vector<Point> const &B,
                        double precision)
{
    std::vector<double> bl(3);
    Interval bound;
    pick_orientation_line(bl, A, precision);
    fat_line_bounds(bound, A, bl);
    clip_interval(dom, B, bl, bound);
}
}

//
//  UIBezierPath+Clipping.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 9/10/13.
//  Copyright (c) 2013 Milestone Made LLC. All rights reserved.
//

#import "UIBezierPath+Clipping.h"
#import <DrawKit-iOS/DrawKit-iOS.h>
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
#import <DrawKit-iOS/DrawKit-iOS.h>
#include <DrawKit-iOS/point.h>
#import <PerformanceBezier/PerformanceBezier.h>

#define kUIBezierClippingPrecision 0.0005
#define kUIBezierClosenessPrecision 0.5

// clarify Geom::Point vs MacTypes
using Geom::Point;

// TODO: change the namespace so i don't conflict with the actual Geom namespace
namespace Geom {
    
    /**
     * returns YES if the two input points are within precision distance
     * of each other
     */
    inline bool are_near(Point a, Point b, double precision) {
        return are_near(a[X], b[X], precision) && are_near(a[Y], b[Y], precision);
    }
    
    
#pragma mark - interval routines
    
    /*
     * Map the sub-interval I in [0,1] into the interval J and assign it to J
     */
    inline
    void map_to(Interval & J, Interval const& I)
    {
        double length = J.extent();
        J[1] = I.max() * length + J[0];
        J[0] = I.min() * length + J[0];
    }
    
    /*
     * The interval [1,0] is used to represent the empty interval, this routine
     * is just an helper function for creating such an interval
     */
    inline
    Interval make_empty_interval()
    {
        Interval I(0);
        I[0] = 1;
        return I;
    }
    
    const Interval UNIT_INTERVAL(0,1);
    const double MAX_PRECISION = 1e-8;
    const double MIN_CLIPPED_SIZE_THRESHOLD = 0.8;
    const Interval EMPTY_INTERVAL = make_empty_interval();
    typedef void clip_fnc_t (Interval &,
                             std::vector<Point> const&,
                             std::vector<Point> const&,
                             double);
    const Interval H1_INTERVAL(0, 0.5);
    const Interval H2_INTERVAL(0.5 + MAX_PRECISION, 1.0);
    
    
    
#pragma mark - bezier curve routines
    
    /*
     * Return true if all the Bezier curve control points are near,
     * false otherwise
     */
    inline
    bool is_constant(std::vector<Point> const& A, double precision)
    {
        for (unsigned int i = 1; i < A.size(); ++i)
        {
            if(!are_near(A[i][X], A[0][X], precision) ||
               !are_near(A[i][Y], A[0][Y], precision))
                return false;
        }
        return true;
    }
    
    inline bool is_near(std::vector<Point> const& A, std::vector<Point> const& B, double precision){
        if(is_constant(A, precision) && is_constant(B, precision) &&
           are_near(A[0][X], B[0][X], precision) &&
           are_near(A[0][Y], B[0][Y], precision)){
            return true;
        }
        return false;
    }
    
    /*
     * Compute the hodograph of the bezier curve B and return it in D
     */
    inline
    void derivative(std::vector<Point> & D, std::vector<Point> const& B)
    {
        D.clear();
        size_t sz = B.size();
        if (sz == 0) return;
        if (sz == 1)
        {
            D.resize(1, Point(0,0));
            return;
        }
        size_t n = sz-1;
        D.reserve(n);
        for (size_t i = 0; i < n; ++i)
        {
            D.push_back(n*(B[i+1] - B[i]));
        }
    }
    
    /*
     * Compute the hodograph of the Bezier curve B rotated of 90 degree
     * and return it in D; we have N(t) orthogonal to B(t) for any t
     */
    inline
    void normal(std::vector<Point> & N, std::vector<Point> const& B)
    {
        derivative(N,B);
        for (size_t i = 0; i < N.size(); ++i)
        {
            N[i] = rot90(N[i]);
        }
    }
    
    /*
     *  Compute the portion of the Bezier curve "B" wrt the interval [0,t]
     */
    inline
    void left_portion(Coord t, std::vector<Point> & B)
    {
        size_t n = B.size();
        for (size_t i = 1; i < n; ++i)
        {
            for (size_t j = n-1; j > i-1 ; --j)
            {
                B[j] = Lerp(t, B[j-1], B[j]);
            }
        }
    }
    
    /*
     *  Compute the portion of the Bezier curve "B" wrt the interval [t,1]
     */
    inline
    void right_portion(Coord t, std::vector<Point> & B)
    {
        size_t n = B.size();
        for (size_t i = 1; i < n; ++i)
        {
            for (size_t j = 0; j < n-i; ++j)
            {
                B[j] = Lerp(t, B[j], B[j+1]);
            }
        }
    }
    
    /*
     *  Compute the portion of the Bezier curve "B" wrt the interval "I"
     */
    inline
    void portion (std::vector<Point> & B , Interval const& I)
    {
        if (I.min() == 0)
        {
            if (I.max() == 1)  return;
            left_portion(I.max(), B);
            return;
        }
        right_portion(I.min(), B);
        if (I.max() == 1)  return;
        double t = I.extent() / (1 - I.min());
        left_portion(t, B);
    }
    
    
#pragma mark - clipping
    
    inline
    size_t get_precision(Interval const& I)
    {
        double d = I.extent();
        double e = 0.1, p = 10;
        int n = 0;
        while (n < 16 && d < e)
        {
            p *= 10;
            e = 1/p;
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
    void iterate (std::vector<Interval>& domsA,
                  std::vector<Interval>& domsB,
                  std::vector<Point> const& A,
                  std::vector<Point> const& B,
                  Interval const& domA,
                  Interval const& domB,
                  double precision,
                  clip_fnc_t* clip)
    {
        // in order to limit recursion
        static size_t counter = 0;
        if (domA.extent() == 1 && domB.extent() == 1) counter  = 0;
        if (++counter > 100){
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
        std::vector<Point>* C1 = &pA;
        std::vector<Point>* C2 = &pB;
        
        Interval dompA = domA;
        Interval dompB = domB;
        Interval* dom1 = &dompA;
        Interval* dom2 = &dompB;
        
        Interval dom;
        
        size_t iter = 0;
        while (++iter < 100
               && (dompA.extent() >= MAX_PRECISION || dompB.extent() >= MAX_PRECISION)
               && !is_constant(*C1, precision) && !is_constant(*C2, precision))
        {
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
            if (dom == EMPTY_INTERVAL)
            {
#if VERBOSE
                std::cerr << "dom: empty" << std::endl;
#endif
                return;
            }
#if VERBOSE
            std::cerr << "dom : " << dom << std::endl;
#endif
            // all other cases where dom[0] > dom[1] are invalid
            if (dom.min() >  dom.max())
            {
                assert(dom.min() <  dom.max());
            }
            
            //            map_to(*dom1, domm);
            map_to(*dom2, dom);
            
            // it's better to stop before losing computational precision
            if (dom2->extent() <= MAX_PRECISION || dom1->extent() <= MAX_PRECISION)
            {
#if VERBOSE
                std::cerr << "beyond max precision limit" << std::endl;
#endif
                break;
            }
            
            //            portion(*C1, domm);
            portion(*C2, dom);
            if (is_constant(*C2, precision))
            {
#if VERBOSE
                std::cerr << "new curve portion is constant" << std::endl;
#endif
                break;
            }
            // if we have clipped less than 20% than we need to subdive the curve
            // with the largest domain into two sub-curves
            if ( dom.extent() > MIN_CLIPPED_SIZE_THRESHOLD)
            {
#if VERBOSE
                std::cerr << "clipped less than 20% : " << dom.extent() << std::endl;
                std::cerr << "angle(pA) : " << angle(pA) << std::endl;
                std::cerr << "angle(pB) : " << angle(pB) << std::endl;
#endif
                std::vector<Point> pC1, pC2;
                Interval dompC1, dompC2;
                if (dompA.extent() > dompB.extent())
                {
                    if ((dompA.extent() / 2) < MAX_PRECISION)
                    {
                        break;
                    }
                    pC1 = pC2 = pA;
                    portion(pC1, H1_INTERVAL);
                    if (is_constant(pC1, precision))
                    {
#if VERBOSE
                        std::cerr << "new curve portion pC1 is constant" << std::endl;
#endif
                        break;
                    }
                    portion(pC2, H2_INTERVAL);
                    if (is_constant(pC2, precision))
                    {
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
                }
                else
                {
                    if ((dompB.extent() / 2) < MAX_PRECISION)
                    {
                        break;
                    }
                    pC1 = pC2 = pB;
                    portion(pC1, H1_INTERVAL);
                    if (is_constant(pC1, precision))
                    {
#if VERBOSE
                        std::cerr << "new curve portion pC1 is constant" << std::endl;
#endif
                        break;
                    }
                    portion(pC2, H2_INTERVAL);
                    if (is_constant(pC2, precision))
                    {
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
        
        BOOL precisionIsTerrible = NO;
        
        if(precA > 0 || precB > 0){
            //
            // here we need to look to see how
            // precise our measurements are. if
            // one of the curves is more precise than
            // the other, then we're going to adjust
            // the output values of the less precise
            // to better match
            if(precB > precA){
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
                CGPoint otherPointAtT = NearestPointOnCurve(pointAtT, Abez, &currTValue );
                
                // now i need to scale the tvalue to
                // the current clip value
                currWidth = domA[1] - domA[0];
                currTValue = domA[0] + currTValue * currWidth;
                dompA[0] = currTValue;
                dompA[1] = currTValue;
#if VERBOSE
                NSLog(@"Bbez precision %f and %f", ABS(otherPointAtT.x - pointAtT.x), ABS(otherPointAtT.y - pointAtT.y));
#endif
                if(ABS(otherPointAtT.x - pointAtT.x) > 1 || ABS(otherPointAtT.y - pointAtT.y) > 1){
                    // even after taking our more precise curve and trying to find
                    // the nearest point on the other curve, we still have an "intersection"
                    // that is further than 1pt for either curve.
                    //
                    // this is a near intersection, but a miss, so mark that precisionIsTerrible
                    precisionIsTerrible = YES;
                }
            }else if(precA > precB){
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
                CGPoint otherPointAtT = NearestPointOnCurve(pointAtT, Bbez, &currTValue );
                currWidth = domB[1] - domB[0];
                currTValue = domB[0] + currTValue * currWidth;
                dompB[0] = currTValue;
                dompB[1] = currTValue;
#if VERBOSE
                NSLog(@"Abez precision %f and %f", ABS(otherPointAtT.x - pointAtT.x), ABS(otherPointAtT.y - pointAtT.y));
#endif
                if(ABS(otherPointAtT.x - pointAtT.x) > 1 || ABS(otherPointAtT.y - pointAtT.y) > 1){
                    // even after taking our more precise curve and trying to find
                    // the nearest point on the other curve, we still have an "intersection"
                    // that is further than 1pt for either curve.
                    //
                    // this is a near intersection, but a miss, so mark that precisionIsTerrible
                    precisionIsTerrible = YES;
                }
            }
            if(!precisionIsTerrible){
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
    void get_solutions (NSMutableArray* xs,
                        std::vector<Point> const& A,
                        std::vector<Point> const& B,
                        double precision,
                        clip_fnc_t* clip)
    {
        
        if(is_constant(A,precision) || is_constant(B,precision)){
            // if our input is already a point, then bail out
            return;
        }
        
        CGPoint ci;
        std::vector<Interval> domsA, domsB;
        iterate (domsA, domsB, A, B, UNIT_INTERVAL, UNIT_INTERVAL, precision, clip);
        if (domsA.size() != domsB.size())
        {
            assert (domsA.size() == domsB.size());
        }
        [xs removeAllObjects];
        
        for (size_t i = 0; i < domsA.size(); ++i)
        {
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
    inline
    bool is_a_right_turn (Point const& p0, Point const& p1, Point const& p2)
    {
        if (p1 == p2) return false;
        Point q1 = p1 - p0;
        Point q2 = p2 - p0;
        if (q1 == -q2) return false;
        return (cross (q1, q2) < 0);
    }
    
    /*
     * return true if p < q wrt the lexicographyc order induced by the coordinates
     */
    struct lex_less
    {
        bool operator() (Point const& p, Point const& q)
        {
            return ((p[X] < q[X]) || (p[X] == q[X] && p[Y] < q[Y]));
        }
    };
    
    /*
     * return true if p > q wrt the lexicographyc order induced by the coordinates
     */
    struct lex_greater
    {
        bool operator() (Point const& p, Point const& q)
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
    void convex_hull (std::vector<Point> & P)
    {
        size_t n = P.size();
        if (n < 2)  return;
        std::sort(P.begin(), P.end(), lex_less());
        if (n < 4) return;
        // upper hull
        size_t u = 2;
        for (size_t i = 2; i < n; ++i)
        {
            while (u > 1 && !is_a_right_turn(P[u-2], P[u-1], P[i]))
            {
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
        for (size_t i = l; i < n; ++i)
        {
            while (l > k && !is_a_right_turn(P[l-2], P[l-1], P[i]))
            {
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
    inline
    void orientation_line (std::vector<double> & l,
                           std::vector<Point> const& c,
                           size_t i, size_t j)
    {
        l[0] = c[j][Y] - c[i][Y];
        l[1] = c[i][X] - c[j][X];
        l[2] = cross(c[i], c[j]);
        double length = std::sqrt(l[0] * l[0] + l[1] * l[1]);
        assert (length != 0);
        l[0] /= length;
        l[1] /= length;
        l[2] /= length;
    }
    
    /*
     * Pick up an orientation line for the Bezier curve "c" and return it in
     * the output parameter "l"
     */
    inline
    void pick_orientation_line (std::vector<double> & l,
                                std::vector<Point> const& c,
                                double precision)
    {
        size_t i = c.size();
        while (--i > 0 && are_near(c[0], c[i], precision))
        {}
        if (i == 0)
        {
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
    inline
    double distance (Point const& P, std::vector<double> const& l)
    {
        return l[X] * P[X] + l[Y] * P[Y] + l[2];
    }
    
    /*
     * Compute the min and max distance of the control points of the Bezier
     * curve "c" from the normalized orientation line "l".
     * This bounds are returned through the output Interval parameter"bound".
     */
    inline
    void fat_line_bounds (Interval& bound,
                          std::vector<Point> const& c,
                          std::vector<double> const& l)
    {
        bound[0] = 0;
        bound[1] = 0;
        double d;
        for (size_t i = 0; i < c.size(); ++i)
        {
            d = distance(c[i], l);
            if (bound[0] > d)  bound[0] = d;
            if (bound[1] < d)  bound[1] = d;
        }
    }
    
    /*
     * return the x component of the intersection point between the line
     * passing through points p1, p2 and the line Y = "y"
     */
    inline
    double intersect (Point const& p1, Point const& p2, double y)
    {
        // we are sure that p2[Y] != p1[Y] because this routine is called
        // only when the lower or the upper bound is crossed
        double dy = (p2[Y] - p1[Y]);
        double s = (y - p1[Y]) / dy;
        return (p2[X]-p1[X])*s + p1[X];
    }
    
    
    
    /*
     * Clip the Bezier curve "B" wrt the fat line defined by the orientation
     * line "l" and the interval range "bound", the new parameter interval for
     * the clipped curve is returned through the output parameter "dom"
     */
    void clip_interval (Interval& dom,
                        std::vector<Point> const& B,
                        std::vector<double> const& l,
                        Interval const& bound)
    {
        double n = B.size() - 1;  // number of sub-intervals
        std::vector<Point> D;     // distance curve control points
        D.reserve (B.size());
        double d;
        for (size_t i = 0; i < B.size(); ++i)
        {
            d = distance (B[i], l);
            D.push_back (Point(i/n, d));
        }
        //print(D);
        
        convex_hull(D);
        std::vector<Point> & p = D;
        //print(p);
        
        bool plower, phigher;
        bool clower, chigher;
        double t, tmin = 1, tmax = 0;
        //std::cerr << "bound : " << bound << std::endl;
        
        plower = (p[0][Y] < bound.min());
        phigher = (p[0][Y] > bound.max());
        if (!(plower || phigher))  // inside the fat line
        {
            if (tmin > p[0][X])  tmin = p[0][X];
            if (tmax < p[0][X])  tmax = p[0][X];
            //std::cerr << "0 : inside " << p[0]
            //          << " : tmin = " << tmin << ", tmax = " << tmax << std::endl;
        }
        
        for (size_t i = 1; i < p.size(); ++i)
        {
            clower = (p[i][Y] < bound.min());
            chigher = (p[i][Y] > bound.max());
            if (!(clower || chigher))  // inside the fat line
            {
                if (tmin > p[i][X])  tmin = p[i][X];
                if (tmax < p[i][X])  tmax = p[i][X];
                //std::cerr << i << " : inside " << p[i]
                //          << " : tmin = " << tmin << ", tmax = " << tmax
                //          << std::endl;
            }
            if (clower != plower)  // cross the lower bound
            {
                t = intersect(p[i-1], p[i], bound.min());
                if (tmin > t)  tmin = t;
                if (tmax < t)  tmax = t;
                plower = clower;
                //std::cerr << i << " : lower " << p[i]
                //          << " : tmin = " << tmin << ", tmax = " << tmax
                //          << std::endl;
            }
            if (chigher != phigher)  // cross the upper bound
            {
                t = intersect(p[i-1], p[i], bound.max());
                if (tmin > t)  tmin = t;
                if (tmax < t)  tmax = t;
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
        if (clower != plower)  // cross the lower bound
        {
            t = intersect(p[last], p[0], bound.min());
            if (tmin > t)  tmin = t;
            if (tmax < t)  tmax = t;
            //std::cerr << "0 : lower " << p[0]
            //          << " : tmin = " << tmin << ", tmax = " << tmax << std::endl;
        }
        if (chigher != phigher)  // cross the upper bound
        {
            t = intersect(p[last], p[0], bound.max());
            if (tmin > t)  tmin = t;
            if (tmax < t)  tmax = t;
            //std::cerr << "0 : higher " << p[0]
            //          << " : tmin = " << tmin << ", tmax = " << tmax << std::endl;
        }
        
        dom[0] = tmin;
        dom[1] = tmax;
    }
    
    
    
#pragma mark - Clipping functions
    
    inline
    void intersections_clip (Interval & dom,
                             std::vector<Point> const& A,
                             std::vector<Point> const& B,
                             double precision)
    {
        std::vector<double> bl(3);
        Interval bound;
        pick_orientation_line(bl, A, precision);
        fat_line_bounds(bound, A, bl);
        clip_interval(dom, B, bl, bound);
    }
    
}


#pragma mark - UIBezier Clipping

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

+(void) resetSegmentTestCount{
    segmentTestCount = 0;
}

+(NSInteger) segmentTestCount{
    return segmentTestCount;
}

+(void) resetSegmentCompareCount{
    segmentCompareCount = 0;
}

+(NSInteger) segmentCompareCount{
    return segmentCompareCount;
}





#pragma mark - Intersection Finding


/**
 * this will return all intersections points between
 * the self path and the input closed path.
 */
-(NSArray*) findIntersectionsWithClosedPath:(UIBezierPath*)closedPath andBeginsInside:(BOOL*)beginsInside{
    
    // hold our bezier information for the curves we compare
    CGPoint bez1_[4];
    CGPoint bez2_[4];
    // pointer versions of the array, since [] can't be passed to blocks
    CGPoint* bez1 = bez1_;
    CGPoint* bez2 = bez2_;
    
    //
    // we're going to make this method generic, and iterate
    // over the flat path first, if available.
    // this means our algorithm will care about
    // path1 vs path2, not self vs closedPath
    UIBezierPath* path1;
    UIBezierPath* path2;
    // if the closed path is flat, it's significantly faster
    // to iterate over it first than it is to iterate over it last.
    // track if we've flipped the paths we're working with, so
    // that we'll return the intersections in the proper path's
    // element/tvalue first
    BOOL didFlipPathNumbers = NO;
    if([closedPath isFlat]){
        path1 = closedPath;
        path2 = self;
        didFlipPathNumbers = YES;
    }else{
        path1 = self;
        path2 = closedPath;
    }
    NSInteger elementCount1 = path1.elementCount;
    NSInteger elementCount2 = path2.elementCount;
    
    
    
    // track if the path1Element begins inside or
    // outside the closed path. this will help us track
    // if intersection points actually change where the curve
    // lands
    __block CGPoint lastPath1Point = CGNotFoundPoint;
    // this array will hold all of the intersection data as we
    // find them
    NSMutableArray* foundIntersections = [NSMutableArray array];
    
    
    __block CGPoint path1StartingPoint = path1.firstPoint;
    // the lengths along the paths that we calculate are
    // estimates only, and not exact
    __block CGFloat path1EstimatedLength = 0;
    __block CGFloat path2EstimatedLength = 0;

    // first, confirm that the paths have a possibility of intersecting
    // at all by comparing their bounds
    CGRect path1Bounds = [path1 bounds];
    CGRect path2Bounds = [path2 bounds];
    // expand the bounds by 1px, just so we're sure to see overlapping bounds for tangent paths
    path1Bounds = CGRectInset(path1Bounds, -1, -1);
    path2Bounds = CGRectInset(path2Bounds, -1, -1);

    if(CGRectIntersectsRect(path1Bounds, path2Bounds)){
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
        [path1 iteratePathWithBlock:^(CGPathElement path1Element, NSUInteger path1ElementIndex){
            // must call this before fillCGPoints, since our call to fillCGPoints will update lastPath1Point
            CGRect path1ElementBounds = [UIBezierPath boundsForElement:path1Element withStartPoint:lastPath1Point andSubPathStartingPoint:path1StartingPoint];
            // expand the bounds by 1px, just so we're sure to see overlapping bounds for tangent paths
            path1ElementBounds = CGRectInset(path1ElementBounds, -1, -1);
            lastPath1Point = [UIBezierPath fillCGPoints:bez1
                                            withElement:path1Element
                              givenElementStartingPoint:lastPath1Point
                                andSubPathStartingPoint:path1StartingPoint];
            CGFloat path1EstimatedElementLength = 0;
            
            // only look for intersections if it's not a moveto point.
            // this way our bez1 array will be filled with a valid
            // bezier curve
            if(path1Element.type != kCGPathElementMoveToPoint){
                path1EstimatedElementLength = [UIBezierPath estimateArcLengthOf:bez1 withSteps:10];
                
                __block CGPoint lastPath2Point = CGNotFoundPoint;
                
                if(CGRectIntersectsRect(path1ElementBounds, path2Bounds)){
                    // at this point, we know that path1's element intersections somewhere within
                    // all of path 2, so we'll iterate over path2 and find as many intersections
                    // as we can
                    __block CGPoint path2StartingPoint = path2.firstPoint;
                    path2EstimatedLength = 0;
                    // big iterating over path2 to find all intersections with this element from path1
                    [path2 iteratePathWithBlock:^(CGPathElement path2Element, NSUInteger path2ElementIndex){
                        // must call this before fillCGPoints, since that will update lastPath1Point
                        CGRect path2ElementBounds = [UIBezierPath boundsForElement:path2Element withStartPoint:lastPath2Point andSubPathStartingPoint:path2StartingPoint];
                        // expand the bounds by 1px, just so we're sure to see overlapping bounds for tangent paths
                        path2ElementBounds = CGRectInset(path2ElementBounds, -1, -1);
                        lastPath2Point = [UIBezierPath fillCGPoints:bez2
                                                        withElement:path2Element
                                          givenElementStartingPoint:lastPath2Point
                                            andSubPathStartingPoint:path2StartingPoint];
                        CGFloat path2ElementLength = 0;
                        if(path2Element.type != kCGPathElementMoveToPoint){
                            path2ElementLength = [UIBezierPath estimateArcLengthOf:bez2 withSteps:10];
                            if(CGRectIntersectsRect(path1ElementBounds, path2ElementBounds)){
                                // track the number of segment comparisons we have to do
                                // this tracks our worst case of how many segment rects intersect
                                segmentCompareCount++;
                                
                                // at this point, we have two valid bezier arrays populated
                                // into bez1 and bez2. calculate if they intersect at all
                                NSArray* intersections;
                                if((path1Element.type == kCGPathElementAddLineToPoint || path1Element.type == kCGPathElementCloseSubpath) &&
                                   (path2Element.type == kCGPathElementAddLineToPoint || path2Element.type == kCGPathElementCloseSubpath)){
                                    // in this case, the two elements are both lines, so they can intersect at
                                    // only 1 place.
                                    // TODO: should i return two intersections if they're tangent?
                                    CGPoint intersection = [UIBezierPath intersects2D:bez1[0] to:bez1[3] andLine:bez2[0] to:bez2[3]];
                                    if(!CGPointEqualToPoint(intersection,CGNotFoundPoint)){
                                        CGFloat path1TValue = distance(bez1[0], intersection) / distance(bez1[0], bez1[3]);
                                        CGFloat path2TValue = distance(bez2[0], intersection) / distance(bez2[0], bez2[3]);
                                        if(path1TValue >= 0 && path1TValue <= 1 &&
                                           path2TValue >= 0 && path2TValue <= 1){
                                            intersections = [NSArray arrayWithObject:[NSValue valueWithCGPoint:CGPointMake(path2TValue, path1TValue)]];
                                        }else{
                                            // doesn't intersect within allowed T values
                                        }
                                    }
                                }else{
                                    // at least one of the curves is a proper bezier, so use our
                                    // bezier intersection algorithm to find possibly multiple intersections
                                    // between these curves
                                    intersections = [UIBezierPath findIntersectionsBetweenBezier:bez1 andBezier:bez2];
                                }
                                // loop through the intersections that we've found, and add in
                                // some context that we can save for each one.
                                for(NSValue* val in intersections){
                                    CGFloat tValue1 = [val CGPointValue].y;
                                    CGFloat tValue2 = [val CGPointValue].x;
                                    // estimated length along each curve until the intersection is hit
                                    CGFloat lenTillPath1Inter = path1EstimatedLength + tValue1 * path1EstimatedElementLength;
                                    CGFloat lenTillPath2Inter = path2EstimatedLength + tValue2 * path2ElementLength;
                                    
                                    DKUIBezierPathIntersectionPoint* inter = [DKUIBezierPathIntersectionPoint intersectionAtElementIndex:path1ElementIndex
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
                                    
                                    if(didFlipPathNumbers){
                                        // we flipped the order that we're looking through paths,
                                        // so we need to flip the intersection indexes so that
                                        // bez1 is always the unclosed path and bez2 is always closed
                                        inter = [inter flipped];
                                    }
                                    // add to our output!
                                    [foundIntersections addObject:inter];
                                }
                            }
                            // track our full path length
                            path2EstimatedLength += path2ElementLength;
                        }else{
                            // it's a moveto element, so update our starting
                            // point for this subpath within the full path
                            path2StartingPoint = path2Element.points[0];
                        }
                    }];
                }
                path1EstimatedLength += path1EstimatedElementLength;
            }else{
                // it's a moveto element, so update our starting
                // point for this subpath within the full path
                path1StartingPoint = path1Element.points[0];
            }
        }];
        
        // make sure we have the points sorted by the intersection location
        // inside of self instead of inside the closed curve
        [foundIntersections sortUsingComparator:^NSComparisonResult(id obj1, id obj2){
            if([obj1 elementIndex1] < [obj2 elementIndex1]){
                return NSOrderedAscending;
            }else if([obj1 elementIndex1] == [obj2 elementIndex1] &&
                     [obj1 tValue1] < [obj2 tValue1]){
                return NSOrderedAscending;
            }
            return NSOrderedDescending;
        }];
        
        [foundIntersections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
            DKUIBezierPathIntersectionPoint* intersection = obj;
            if(!didFlipPathNumbers){
                intersection.pathLength1 = path1EstimatedLength;
                intersection.pathLength2 = path2EstimatedLength;
            }else{
                intersection.pathLength1 = path2EstimatedLength;
                intersection.pathLength2 = path1EstimatedLength;
            }
        }];
        
        // save all of our intersections, we may need this reference
        // later if we filter out too many intersections as duplicates
        NSArray* allFoundIntersections = foundIntersections;
        
        // iterate over the intersections and filter out duplicates
        __block DKUIBezierPathIntersectionPoint* lastInter = [foundIntersections lastObject];
        foundIntersections = [NSMutableArray arrayWithArray:[foundIntersections filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(id obj, NSDictionary*bindings){
            DKUIBezierPathIntersectionPoint* intersection = obj;
            BOOL isDistinctIntersection = ![obj matchesElementEndpointWithIntersection:lastInter];
            CGPoint interLoc = intersection.location1;
            CGPoint lastLoc = lastInter.location1;
            CGPoint interLoc2 = intersection.location2;
            CGPoint lastLoc2 = lastInter.location2;
            if(isDistinctIntersection){
                if((ABS(interLoc.x - lastLoc.x) < kUIBezierClosenessPrecision &&
                   ABS(interLoc.y - lastLoc.y) < kUIBezierClosenessPrecision) ||
                   (ABS(interLoc2.x - lastLoc2.x) < kUIBezierClosenessPrecision &&
                    ABS(interLoc2.y - lastLoc2.y) < kUIBezierClosenessPrecision)){
                    // the points are close, but they might not necessarily be the same intersection.
                    // for instance, a curve could be a very very very sharp V, and the intersection could
                    // be slicing through the middle of the V to look like an ∀
                    // the distance between the intersections along the - might be super small,
                    // but along the V is much much further and should count as two intersections
                    
                    BOOL closeLocation1 = [lastInter isCloseToIntersection:intersection withPrecision:kUIBezierClosenessPrecision];
                    BOOL closeLocation2 = [[lastInter flipped] isCloseToIntersection:[intersection flipped] withPrecision:kUIBezierClosenessPrecision];
                    
                    if(closeLocation1 != closeLocation2){
                        NSLog(@"gotcha");
                    }
                    
                    isDistinctIntersection = !closeLocation1 || !closeLocation2;
                }
            }
            if(isDistinctIntersection){
                lastInter = obj;
            }
            return isDistinctIntersection;
        }]]];
        
        if(![foundIntersections count] && [allFoundIntersections count]){
            // we accidentally filter out all of the points, because
            // they all matched
            // so add just 1 back in
            [foundIntersections addObject:[allFoundIntersections firstObject]];
        }else{
            // sort exact match intersections out of the flipped intersections
            // [DrawKitiOSClippingIntersectionTests testLineNearBoundary]
            NSMutableArray* originallyFoundIntersections = [NSMutableArray arrayWithArray:foundIntersections];
            [foundIntersections sortUsingComparator:^NSComparisonResult(id obj1, id obj2){
                if([obj1 elementIndex2] < [obj2 elementIndex2]){
                    return NSOrderedAscending;
                }else if([obj1 elementIndex2] == [obj2 elementIndex2] &&
                         [obj1 tValue2] < [obj2 tValue2]){
                    return NSOrderedAscending;
                }
                return NSOrderedDescending;
            }];
            
            __block DKUIBezierPathIntersectionPoint* lastInter = nil;
            [foundIntersections enumerateObjectsUsingBlock:^(DKUIBezierPathIntersectionPoint* obj, NSUInteger idx, BOOL *stop) {
                if([[lastInter flipped] matchesElementEndpointWithIntersection:[obj flipped]]){
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
        if([closedPath isClosed]){
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
            DKUIBezierPathIntersectionPoint* firstIntersection = [foundIntersections firstObject];
            DKUIBezierPathIntersectionPoint* lastIntersection = [foundIntersections lastObject];
            BOOL isInside = [closedPath containsPoint:self.firstPoint];
            if(isInside && firstIntersection.elementIndex1 != 1 && firstIntersection.tValue1 != 0){
                // double check that the first line segment is actually inside, and
                // not just tangent at self.firstPoint
                CGFloat firstTValue = firstIntersection.tValue1 / 2;
                CGPoint* bezToUseForNextPoint = firstIntersection.bez1;
                CGPoint locationAfterIntersection = [UIBezierPath pointAtT:firstTValue forBezier:bezToUseForNextPoint];
                isInside = isInside && [closedPath containsPoint:locationAfterIntersection];
            }
            if(beginsInside){
                *beginsInside = isInside;
            }
            if(lastIntersection == [foundIntersections firstObject]){
                // make sure not to compare the first and last intersection
                // if they're the same
                lastIntersection = nil;
            }
            for(int i=0;i<[foundIntersections count];i++){
                DKUIBezierPathIntersectionPoint* intersection = [foundIntersections objectAtIndex:i];
                
                DKUIBezierPathIntersectionPoint* nextIntersection = nil;
                if(i < [foundIntersections count] - 1){
                    nextIntersection = [foundIntersections objectAtIndex:i+1];
                }
                
                CGPoint possibleNextBezier[4];
                CGPoint* bezToUseForNextPoint = intersection.bez1;
                // if the next intersection isn't in the same element, then we
                // can test a point halfway between our intersection and the end
                // of the element to see if we're inside/outside the closed shape
                CGFloat nextTValue = (intersection.tValue1 + 1.0) / 2.0;
                if(nextIntersection && nextIntersection.elementIndex1 == intersection.elementIndex1){
                    // welp, our next intersection is inside the same element,
                    // so average our intersection points to see if we're inside/
                    // outside the shape
                    nextTValue = (intersection.tValue1 + nextIntersection.tValue1) / 2.0;
                }
                if(nextTValue == intersection.tValue1){
                    // our "next" value to check is the same as the point we're
                    // already looking at. so look at the next element instead
                    if(nextIntersection){
                        nextTValue = nextIntersection.tValue1 / 2;
                        bezToUseForNextPoint = nextIntersection.bez1;
                    }else{
                        // no next intersection, check if we have a next element
                        if(intersection.elementIndex1 < [self elementCount]-1){
                            nextTValue = 1;
                            // since the next element is entirely within the next segment,
                            // we can just use it as a point bezier
                            CGPathElement ele = [self elementAtIndex:intersection.elementIndex1+1];
                            if(ele.type != kCGPathElementCloseSubpath){
                                possibleNextBezier[0] = ele.points[0];
                                possibleNextBezier[1] = ele.points[0];
                                possibleNextBezier[2] = ele.points[0];
                                possibleNextBezier[3] = ele.points[0];
                                bezToUseForNextPoint = (CGPoint*) &possibleNextBezier;
                            }else{
                                UIBezierPath* subpath = [[self subPaths] objectAtIndex:[self subpathIndexForElement:intersection.elementIndex1]];
                                bezToUseForNextPoint[0] = subpath.lastPoint;
                                bezToUseForNextPoint[1] = subpath.lastPoint;
                                bezToUseForNextPoint[2] = subpath.lastPoint;
                                bezToUseForNextPoint[3] = subpath.lastPoint;
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
                if(!nextIntersection && intersection.tValue1 == 1 && intersection.elementIndex1 == self.elementCount - 1){
                    endsInTangent = YES;
                }
                BOOL isInsideAfterIntersection = [closedPath containsPoint:locationAfterIntersection];
                
                if(!endsInTangent){
                    // we found an intersection that crosses the boundary of the shape,
                    // so mark it as such
                    intersection.mayCrossBoundary = isInside != isInsideAfterIntersection;
                }
                
                // setup for next iteration of loop
                lastIntersection = intersection;
                isInside = isInsideAfterIntersection;
            }
        }
        return  [foundIntersections copy];
    }

    return [NSArray array];
}



#pragma mark - Segment Finding


/**
 * This method will clip out the intersection and the difference
 * of self compared to the closed path input
 *
 * IMPORTANT:
 * this method should only be sent single paths without any additional subpaths.
 * otherwise, the returned numberOfIntersectionSegments / numberOfDifferenceSegments
 * will be wrong
 */
-(DKUIBezierPathClippingResult*) clipUnclosedPathToClosedPath:(UIBezierPath*)closedPath usingIntersectionPoints:(NSArray*)intersectionPoints andBeginsInside:(BOOL)beginsInside{
    __block UIBezierPath* currentIntersectionSegment = [UIBezierPath bezierPath];
    
    //
    // first, the base case:
    // closed path with 1 or fewer intersections, or no intersections at all
    if(([self isClosed] && [intersectionPoints count] <= 1) || [intersectionPoints count] == 0){
        DKUIBezierPathClippingResult* ret = nil;
        if([self isClosed] && [intersectionPoints count] == 1){
            // single
            DKUIBezierPathIntersectionPoint* onlyIntersection = [intersectionPoints firstObject];

            // goal here is to split the path in half, at the intersection point.
            // portionOfBezierPathStartingAtT0 is from t=0 to t=intersection
            // portionOfBezierPathStartingAtIntersectionPoint is t=intersection to t=end
            UIBezierPath* portionOfBezierPathStartingAtT0 = [UIBezierPath bezierPath];
            UIBezierPath* portionOfBezierPathStartingAtIntersectionPoint = [UIBezierPath bezierPath];
            // as we iterate over the path, we'll add path elements to this path
            __block UIBezierPath* actingPathToAddTo = portionOfBezierPathStartingAtT0;
            
            __block CGPoint selfPathStartingPoint = self.firstPoint;
            __block CGPoint startingPoint = self.firstPoint;
            [self iteratePathWithBlock:^(CGPathElement element, NSUInteger elementIndex){
                if(element.type == kCGPathElementMoveToPoint){
                    selfPathStartingPoint = element.points[0];
                }
                if(elementIndex == onlyIntersection.elementIndex1){
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
                }else{
                    // the intersection isn't inside this element, so just
                    // add it to our path
                    if(element.type == kCGPathElementCloseSubpath){
                        // if it's a close element, we need to add it as a line
                        // back to the path starting point. this is because
                        // our new path will have a different starting point, so the
                        // close path would effectivley line-to the wrong point.
                        // we'll explicitly line-to there instead, but only if
                        // our path hasn't already landed at that point.
                        if(!CGPointEqualToPoint(startingPoint, selfPathStartingPoint)){
                            // dont add a line to a point if we're already at that point
                            [actingPathToAddTo addLineToPoint:selfPathStartingPoint];
                        }
                    }else{
                        [actingPathToAddTo addPathElement:element];
                    }
                }
                if(element.type != kCGPathElementCloseSubpath){
                    // update our starting point for the next element
                    // TODO: handle close elements as a LineTo the most recent MoveTo
                    startingPoint = element.points[[UIBezierPath numberOfPointsForElement:element]-1];
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
            NSArray* differenceSegments = [NSArray arrayWithObject:[DKUIBezierPathClippedSegment clippedPairWithStart:onlyIntersection
                                                                                                               andEnd:onlyIntersection
                                                                                                       andPathSegment:portionOfBezierPathStartingAtIntersectionPoint
                                                                                                         fromFullPath:self]];
            ret = [[DKUIBezierPathClippingResult alloc] initWithIntersection:[UIBezierPath bezierPath]
                                                                 andSegments:[NSArray array]
                                                               andDifference:[portionOfBezierPathStartingAtIntersectionPoint copy]
                                                                 andSegments:differenceSegments
                                                         andShellIntSegments:0
                                                        andShellDiffSegments:1];

            
        }else{
            // it's closed or unclosed with 0 intersections
            DKUIBezierUnmatchedPathIntersectionPoint* startOfBlue = [DKUIBezierUnmatchedPathIntersectionPoint intersectionAtElementIndex:0 andTValue:0 withElementIndex:NSNotFound andTValue:0 andElementCount1:self.elementCount andElementCount2:closedPath.elementCount andLengthUntilPath1Loc:self.length andLengthUntilPath2Loc:0];
            DKUIBezierUnmatchedPathIntersectionPoint* endOfBlue = [DKUIBezierUnmatchedPathIntersectionPoint intersectionAtElementIndex:self.elementCount-1 andTValue:1 withElementIndex:NSNotFound andTValue:0 andElementCount1:self.elementCount andElementCount2:closedPath.elementCount andLengthUntilPath1Loc:self.length andLengthUntilPath2Loc:0];
            NSArray* differenceSegments = [NSArray arrayWithObject:[DKUIBezierPathClippedSegment clippedPairWithStart:startOfBlue
                                                                                                               andEnd:endOfBlue
                                                                                                       andPathSegment:[self copy]
                                                                                                         fromFullPath:self]];
            ret = [[DKUIBezierPathClippingResult alloc] initWithIntersection:[UIBezierPath bezierPath]
                                                                 andSegments:[NSArray array]
                                                               andDifference:[self copy]
                                                                 andSegments:differenceSegments
                                                         andShellIntSegments:0
                                                        andShellDiffSegments:1];
        }
        if([closedPath isClosed] && ![intersectionPoints count] && [closedPath containsPoint:self.firstPoint]){
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
    NSMutableArray* tValuesOfIntersectionPoints = [NSMutableArray arrayWithArray:intersectionPoints];
    
    NSMutableArray* originalTValuesOfIntersectionPoints = [tValuesOfIntersectionPoints mutableCopy];
    NSInteger countOfIntersections = [tValuesOfIntersectionPoints count];
    //
    // track special case if we start at an intersection
    BOOL firstIntersectionIsStartOfPath = [[tValuesOfIntersectionPoints firstObject] elementIndex1] == 1 && [[tValuesOfIntersectionPoints firstObject] tValue1] == 0;
    
    // collect the intersecting and difference segments
    NSMutableArray* intersectionSegments = [NSMutableArray array];
    NSMutableArray* differenceSegments = [NSMutableArray array];
    
    // during our algorithm, we'll always add to the intersection
    // and not the difference. whenever we hit an intersection, we'll
    // just swap the intersection/difference pointers so that we'll
    // continually toggle which array we're adding to.
    __block NSMutableArray* actingintersectionSegments = intersectionSegments;
    __block NSMutableArray* actingdifferenceSegments = differenceSegments;
    
    CGPoint firstPoint = self.firstPoint;
    if(![closedPath containsPoint:firstPoint] || !beginsInside || ![closedPath isClosed]){
        // if we're starting outside the closedPath,
        // the init our paths to the correct side
        // so our output will be a proper intersection
        // vs difference
        actingintersectionSegments = differenceSegments;
        actingdifferenceSegments = intersectionSegments;
    }
    
    NSMutableArray* firstIntersectionSegments = actingintersectionSegments;
    
    // most recent tValue that we've looked at as we traverse over the path. begin with the start point
    __block DKUIBezierPathIntersectionPoint* lastTValue = nil;
    DKUIBezierPathIntersectionPoint* firstTValue = [originalTValuesOfIntersectionPoints firstObject];
    if([self isClosed]){
        // if we're closed, then the last intersection we've looked at
        // is the last intersection in the path. from there, it loops
        // around back through the start of the path
        lastTValue = [originalTValuesOfIntersectionPoints lastObject];
    }else{
        // of unclosed paths, the "most recent" intersection is the non-intersection
        // of the start of the path. not sure why we're not using firstIntersectionIsStartOfPath
        lastTValue = [DKUIBezierUnmatchedPathIntersectionPoint intersectionAtElementIndex:0 andTValue:0 withElementIndex:NSNotFound andTValue:0 andElementCount1:self.elementCount andElementCount2:closedPath.elementCount andLengthUntilPath1Loc:0 andLengthUntilPath2Loc:0];
    }
    if(firstTValue.elementIndex1 == 1 && firstTValue.tValue1 == 0){
        // we start on an intersection, so use this as the "last"
        // tvalue, so that it will begin the first segment.
        lastTValue = firstTValue;
    }
    
    
    // the last point is always the end of the path
    
    DKUIBezierUnmatchedPathIntersectionPoint* endOfTheLine = [DKUIBezierUnmatchedPathIntersectionPoint intersectionAtElementIndex:self.elementCount-1 andTValue:1 withElementIndex:NSNotFound andTValue:0 andElementCount1:self.elementCount andElementCount2:closedPath.elementCount andLengthUntilPath1Loc:self.length andLengthUntilPath2Loc:0];
    
    CGPoint selfPathStartingPoint = self.firstPoint;
    
    __block BOOL closedPathIsPoint = NO;
    
    __block BOOL lastElementIsClosePath = NO;
    __block CGPoint startingPoint = CGNotFoundPoint;
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentElementIndex){
        if(![tValuesOfIntersectionPoints count] || currentElementIndex != [[tValuesOfIntersectionPoints firstObject] elementIndex1]){
            // no intersection between these two elements, so add the
            // element to the output
            if(element.type == kCGPathElementCloseSubpath){
                if(CGPointEqualToPoint(currentIntersectionSegment.lastPoint, self.firstPoint)){
                    // track if the closePathElement actually gives us a line segment,
                    // or if the rest of the path was already visually closed
                    closedPathIsPoint = YES;
                }
                // TODO: future optimization here would be to skip the line-to
                // if the path is already at the self.firstPoint...
                [currentIntersectionSegment addLineToPoint:self.firstPoint];
                if(currentElementIndex == self.elementCount - 1){
                    lastElementIsClosePath = YES;
                }
            }else{
                // no intersection, just add the element
                [currentIntersectionSegment addPathElement:element];
            }
        }else{
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
            while([[tValuesOfIntersectionPoints firstObject] elementIndex1] == currentElementIndex){
                // get the T-value of the intersection in self's element.
                // if this element had been split before, then this tValue may
                // have been adjust from the origin tvalue intersection
                CGFloat tValue = [[tValuesOfIntersectionPoints firstObject] tValue1];
                if(tValue == 1){
                    hasRight = NO;
                }
                
                // split us into left/right
                CGPoint left[4];
                CGPoint right[4];
                [UIBezierPath subdivideBezier:bez intoLeft:left andRight:right atT:tValue];
                
                // add the path element to the intersection
                if(tValue > 0){
                    // if the tValue is 0, then the intersection really happened at the
                    // end of the last element, so we don't need to add a curve to a single point
                    // here. instead just skip it and only add a curve that has a size larger
                    // than a single point.
                    if(element.type != kCGPathElementAddLineToPoint && element.type != kCGPathElementCloseSubpath){
                        [currentIntersectionSegment addCurveToPoint:left[3] controlPoint1:left[1] controlPoint2:left[2]];
                    }else{
                        [currentIntersectionSegment addLineToPoint:left[3]];
                    }
                }
                
                // currTValue is always the unadjusted tvalue of the intersection
                // between the curves
                DKUIBezierPathIntersectionPoint* currTValue = [originalTValuesOfIntersectionPoints objectAtIndex:0];
                if(currTValue != lastTValue){
                    // just in case the first intersection is exactly
                    // on a boundary, then we'll want to skip creating a segment
                    // that is exactly 1 px large (distance of 0)
                    [actingintersectionSegments addObject:[DKUIBezierPathClippedSegment clippedPairWithStart:lastTValue
                                                                                                     andEnd:currTValue
                                                                                             andPathSegment:currentIntersectionSegment
                                                                                               fromFullPath:self]];
                }
                lastTValue = currTValue;
                if([[tValuesOfIntersectionPoints firstObject] mayCrossBoundary]){
                    // this intersection causes a boundary crossing, so switch
                    // our intersection and difference
                    // swap inside/outside
                    NSMutableArray* swap = actingintersectionSegments;
                    actingintersectionSegments = actingdifferenceSegments;
                    actingdifferenceSegments = swap;
                }else{
                    // the intersection does not cross the boundary of the
                    // shape
                }
                if(hasRight || currentElementIndex != self.elementCount - 1){
                    // don't add the trailing moveTo if there won't
                    // be any more segments to add to it
                    currentIntersectionSegment = [UIBezierPath bezierPath];
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
                for(int i=0;i<[tValuesOfIntersectionPoints count];i++){
                    DKUIBezierPathIntersectionPoint* oldInter = [tValuesOfIntersectionPoints objectAtIndex:i];
                    if([oldInter elementIndex1] == currentElementIndex){
                        // this intersection matches the current element that
                        // we just split, so adjust it's T values
                        CGFloat oldT = [oldInter tValue1];
                        CGFloat adjustedTValue = (oldT - tValue) / (1.0 - tValue);
                        if(oldT == 1 || oldT == 0){
                            // save if its on a boundary for rounding error
                            adjustedTValue = oldT;
                        }
                        // create a new intersection, and replace it in the array
                        DKUIBezierPathIntersectionPoint* newInter = [DKUIBezierPathIntersectionPoint intersectionAtElementIndex:oldInter.elementIndex1
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
            if(hasRight){
                // ok, we've processed all intersections for this element,
                // now add what's left of this element to the curve
                // TODO: what happens if the element intersects at the end of the element at T = 1?
                if(element.type != kCGPathElementAddLineToPoint && element.type != kCGPathElementCloseSubpath){
                    [currentIntersectionSegment addCurveToPoint:bez[3] controlPoint1:bez[1] controlPoint2:bez[2]];
                }else{
                    [currentIntersectionSegment addLineToPoint:bez[3]];
                }
                // and now loop back around to the next element and begin
                // the process all over for the rest of the path.
            }
        }
        
        if(element.type != kCGPathElementCloseSubpath){
            // update our starting point for the next element
            // NOTE: we don't handle close subpaths / move-to's and
            // resetting the startpoint because this method only
            // handles paths with a single subpath. multiple subpaths
            // are not supported here. use redAndGreenAndBlueSegmentsCreatedFrom
            // or similar instead for multiple subpaths.
            startingPoint = element.points[[UIBezierPath numberOfPointsForElement:element]-1];
        }
    }];
    
    
    if(lastTValue.tValue1 == 1 && ((closedPathIsPoint && lastElementIsClosePath && lastTValue.elementIndex1 == self.elementCount - 2) ||
                                         (!lastElementIsClosePath && lastTValue.elementIndex1 == self.elementCount - 1))){
        // the last intersection is at the very very end of the curve,
        // so we've already added the appropriate segment for it. there's
        // nothing left on the right hand side of the intersection to use
        // as another segment
    }else
        if(![self isClosed] || (countOfIntersections <= 2 && firstIntersectionIsStartOfPath)){
        // if the path is closed, then section of the curve from the last intersection
        // wrapped to the first intersection has already been added to the first segment
        // so only add this last segment if it's not closed
        [actingintersectionSegments addObject:[DKUIBezierPathClippedSegment clippedPairWithStart:lastTValue
                                                                                         andEnd:endOfTheLine
                                                                                 andPathSegment:currentIntersectionSegment
                                                                                   fromFullPath:self]];
    }else if([self isClosed]){
        // if we're closed, then the last loops around
        // through the first - they're actually the same segment.
        // this will merge the two segments and replace them in our output.
        if([firstIntersectionSegments count]){
            DKUIBezierPathClippedSegment* firstSeg = [firstIntersectionSegments firstObject];
            [currentIntersectionSegment appendPathRemovingInitialMoveToPoint:firstSeg.pathSegment1];
            DKUIBezierPathClippedSegment* newSeg = [DKUIBezierPathClippedSegment clippedPairWithStart:firstSeg.startIntersection
                                                                                               andEnd:firstSeg.endIntersection
                                                                                       andPathSegment:currentIntersectionSegment
                                                                                         fromFullPath:firstSeg.fullPath];
            [firstIntersectionSegments replaceObjectAtIndex:0 withObject:newSeg];
        }
    }
    
    // now calculate the full intersection and difference paths
    UIBezierPath* intersection = [UIBezierPath bezierPath];
    UIBezierPath* difference = [UIBezierPath bezierPath];
    for(DKUIBezierPathClippedSegment* seg in intersectionSegments){
        if([seg.pathSegment1 elementCount] > 1){
            [intersection appendPath:seg.pathSegment1];
        }
    }
    for(DKUIBezierPathClippedSegment* seg in differenceSegments){
        if([seg.pathSegment1 elementCount] > 1){
            [difference appendPath:seg.pathSegment1];
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
+(DKUIBezierPathClippingResult*) redAndGreenSegmentsCreatedFrom:(UIBezierPath*)shapePath bySlicingWithPath:(UIBezierPath*)scissorPath withIntersections:(NSArray*)_scissorToShapeIntersections{
    // We'll clip twice, once clipping by the scissors to get the intersection/difference of the
    // scissor path compared to the shape
    NSMutableArray* scissorToShapeIntersections = [NSMutableArray arrayWithArray:_scissorToShapeIntersections];
    
    //
    // these will track the full intersection and difference
    // objects used to generate a full DKUIBezierPathClippingResult
    // over the entire scissor path, not just each subpath
    UIBezierPath* entireScissorIntersection = [UIBezierPath bezierPath];
    UIBezierPath* entireScissorDifference = [UIBezierPath bezierPath];
    NSMutableArray* intersectionSegments = [NSMutableArray array];
    NSMutableArray* differenceSegments = [NSMutableArray array];
    
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
    NSMutableArray* allSubpathToShapeIntersections = [NSMutableArray array];
    NSUInteger elementCountForPreviousSubpaths = 0;
    CGFloat pathLengthForPreviousSubpaths = 0;
    //
    // as we iterate over the subpaths, if an intersection point represents a non-intersection,
    // then we need to adjust that as well to show the correct element count
    DKUIBezierPathIntersectionPoint* (^adjustedNonIntersection)(DKUIBezierPathIntersectionPoint*inter) =
    ^DKUIBezierPathIntersectionPoint*(DKUIBezierPathIntersectionPoint* inter){
        // this block will accept an intersection, and will return a new intersection that has
        // adjusted the elementCount and lenAtInter1 to reflect all previous subpaths so far
        //
        // this is useful when manually adjusting for unmatched intersections that do not appear in
        // scissorToShapeIntersections, and so cannot be simply mapped to
        DKUIBezierPathIntersectionPoint* ret = [DKUIBezierUnmatchedPathIntersectionPoint intersectionAtElementIndex:inter.elementIndex1 + elementCountForPreviousSubpaths
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
    DKUIBezierPathClippedSegment* (^adjustNonIntersectionPointForSegment)(DKUIBezierPathClippedSegment*) =
    ^DKUIBezierPathClippedSegment*(DKUIBezierPathClippedSegment* seg){
        // this block will inspect the input segment and determine if
        // either of its intersections represent a non-intersection with the shape.
        //
        // if so, it will adjust those intersection objects to reflect the
        // subpath location in the complete scissor path, and will return
        // a properly adjusted segment
        DKUIBezierPathIntersectionPoint* altStartInter = nil;
        DKUIBezierPathIntersectionPoint* altEndInter = nil;
        if([seg.startIntersection isKindOfClass:[DKUIBezierUnmatchedPathIntersectionPoint class]]){
            altStartInter = adjustedNonIntersection(seg.startIntersection);
        }
        if([seg.endIntersection isKindOfClass:[DKUIBezierUnmatchedPathIntersectionPoint class]]){
            altEndInter = adjustedNonIntersection(seg.endIntersection);
        }
        
        if(altStartInter || altEndInter){
            return [DKUIBezierPathClippedSegment clippedPairWithStart:altStartInter ? altStartInter : seg.startIntersection
                                                               andEnd:altEndInter ? altEndInter : seg.endIntersection
                                                       andPathSegment:seg.pathSegment1
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
    for(UIBezierPath* subScissors in [scissorPath subPaths]){
        BOOL beginsInside1_alt = NO;
        // find intersections within only this subpath
        NSMutableArray* subpathToShapeIntersections = [NSMutableArray arrayWithArray:[subScissors findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside1_alt]];
        // find all segments for only this subpath
        DKUIBezierPathClippingResult* subpathClippingResult = [subScissors clipUnclosedPathToClosedPath:shapePath usingIntersectionPoints:subpathToShapeIntersections andBeginsInside:beginsInside1_alt];
        
        // track our subpath intersections, so that we can map
        // them back to full path intersections
        [allSubpathToShapeIntersections addObjectsFromArray:subpathToShapeIntersections];
        // update the entire difference/intersection paths
        [entireScissorIntersection appendPath:subpathClippingResult.entireIntersectionPath];
        [entireScissorDifference appendPath:subpathClippingResult.entireDifferencePath];
        
        // and track the segments for this subpath.
        // we'll update the segment intersections after this loop
        for (DKUIBezierPathClippedSegment* seg in subpathClippingResult.intersectionSegments) {
            [intersectionSegments addObject:adjustNonIntersectionPointForSegment(seg)];
        }
        for (DKUIBezierPathClippedSegment* seg in subpathClippingResult.differenceSegments) {
            [differenceSegments addObject:adjustNonIntersectionPointForSegment(seg)];
        }
        
        // track where we are in the context of the full path.
        // this is useful for adjusting non-matching intersection points
        elementCountForPreviousSubpaths += [subScissors elementCount];
        pathLengthForPreviousSubpaths += [subScissors length];
        if(!hasCountedShellSegments){
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
    NSMutableArray* correctedIntersectionSegments = [NSMutableArray array];
    NSMutableArray* correctedDifferenceSegments = [NSMutableArray array];
    
    //
    // now, all of the intersectionSegments and differenceSegments are correct
    // for their respective subpaths. we need to create new segment objects
    // to represent these segments that will adjust them into the full path's
    // list of intersections.
    void (^fixSegmentIntersections)(NSArray*, NSMutableArray*) = ^(NSArray* segmentsToFix, NSMutableArray* output) {
        for(DKUIBezierPathClippedSegment* seg in segmentsToFix){
            NSUInteger indx;
            DKUIBezierPathIntersectionPoint* correctedStartIntersection = seg.startIntersection;
            indx = [allSubpathToShapeIntersections indexOfObject:seg.startIntersection];
            if(indx != NSNotFound){
                // we found an intersection in the full scissor path that we can map to,
                // so use that for the start
                correctedStartIntersection = [scissorToShapeIntersections objectAtIndex:indx];
            }
            DKUIBezierPathIntersectionPoint* correctedEndIntersection = seg.endIntersection;
            indx = [allSubpathToShapeIntersections indexOfObject:seg.endIntersection];
            if(indx != NSNotFound){
                // we found an intersection in the full scissor path that we can map to,
                // so use that for the end
                correctedEndIntersection = [scissorToShapeIntersections objectAtIndex:indx];
            }
            // now, create a new segment that is in relation to the full scissor path instead
            // of just the scissor subpath
            DKUIBezierPathClippedSegment* correctedSeg = [DKUIBezierPathClippedSegment clippedPairWithStart:correctedStartIntersection
                                                                                                     andEnd:correctedEndIntersection
                                                                                             andPathSegment:seg.pathSegment1
                                                                                               fromFullPath:scissorPath];
            [output addObject:correctedSeg];
        }
    };
    
    // adjust the segments into the full path's intersection list
    fixSegmentIntersections(intersectionSegments, correctedIntersectionSegments);
    fixSegmentIntersections(differenceSegments, correctedDifferenceSegments);
    
    // at this point, we have our full intersection information for the scissors.
    // so we'll manually regenerate the full clipping result across all subpaths
    DKUIBezierPathClippingResult* clipped1 = [[DKUIBezierPathClippingResult alloc] initWithIntersection:entireScissorIntersection
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
+(NSArray*) redAndGreenAndBlueSegmentsCreatedFrom:(UIBezierPath*)shapePath bySlicingWithPath:(UIBezierPath*)scissorPath andNumberOfBlueShellSegments:(NSUInteger*)numberOfBlueShellSegments{
    
    // find the intersections between the two paths. these will be the definitive intersection points,
    // no matter which way we clip the paths later on. if we clip shape to scissors, or scissor to shape,
    // we'll use these same intersections (properly adjusted for each cut).
    NSArray* scissorToShapeIntersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    
    // so our first step is to create arrays of both the red and blue segments.
    //
    // first, find the red segments (scissor intersection with the shape), and connect
    // it's end to its start, if possible.
    DKUIBezierPathClippingResult* clipped1 = [UIBezierPath redAndGreenSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath withIntersections:scissorToShapeIntersections];
    NSMutableArray* redSegments = [NSMutableArray arrayWithArray:clipped1.intersectionSegments];
    NSMutableArray* greenSegments = [NSMutableArray arrayWithArray:clipped1.differenceSegments];
    
    
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
    NSArray* intersectionsWithBoundaryInformation = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];
    //
    // this array will be the intersections between the shape and the scissor.
    // we'll use the exact same intersection objects (flipped, b/c we're attacking from
    // the shape v scissor instead of vice versa). We'll need to order them and
    // set the mayCrossBoundary so that the final array will appear as if it came
    // directly from [shapePath findIntersectionsWithClosedPath:scissorPath...]
    NSMutableArray* shapeToScissorIntersections = [NSMutableArray array];
    // 1. flip
    [scissorToShapeIntersections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        [shapeToScissorIntersections addObject:[obj flipped]];
    }];
    // 2. sort
    [shapeToScissorIntersections sortUsingComparator:^NSComparisonResult(id obj1, id obj2){
        if([obj1 elementIndex1] < [obj2 elementIndex1]){
            return NSOrderedAscending;
        }else if([obj1 elementIndex1] == [obj2 elementIndex1] &&
                 [obj1 tValue1] < [obj2 tValue1]){
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    
    if([shapeToScissorIntersections count] != [intersectionsWithBoundaryInformation count]){
        @throw [NSException exceptionWithName:@"BezierPathIntersectionException" reason:@"mismatched intersection length" userInfo:nil];
    }
    // 3. fix mayCrossBoundary:
    for(int i=0;i<[intersectionsWithBoundaryInformation count];i++){
        [[shapeToScissorIntersections objectAtIndex:i] setMayCrossBoundary:[[intersectionsWithBoundaryInformation objectAtIndex:i] mayCrossBoundary]];
    }
    
    //
    // now we can clip the shape and scissor with essentially the same intersection points
    DKUIBezierPathClippingResult* clipped2 = [UIBezierPath redAndGreenSegmentsCreatedFrom:scissorPath bySlicingWithPath:shapePath withIntersections:shapeToScissorIntersections];
    
    //
    // this output (clipped1 and clipped2) give us the Segment objects for both the scissors and
    // the shape.
    // first check the blue intersection for it's end/start to combine
    NSArray* blueIntersectionSegments = clipped2.intersectionSegments;
    // next, check the blue difference to see if it's end and start should be connected
    NSArray* blueDifferenceSegments = clipped2.differenceSegments;
    // for the blue segments, we need to use both the intersection and difference,
    // so combine them into a single array of blue segments.
    NSMutableArray* blueSegments = [NSMutableArray array];
    
    // shell segments first!
    [blueSegments addObjectsFromArray:[blueIntersectionSegments subarrayWithRange:NSMakeRange(0, clipped2.numberOfShellIntersectionSegments)]];
    [blueSegments addObjectsFromArray:[blueDifferenceSegments subarrayWithRange:NSMakeRange(0, clipped2.numberOfShellDifferenceSegments)]];

    // non-shell next
    if(clipped2.numberOfShellIntersectionSegments < [blueIntersectionSegments count]){
        [blueSegments addObjectsFromArray:[blueIntersectionSegments subarrayWithRange:NSMakeRange(clipped2.numberOfShellIntersectionSegments,
                                                                                                  [blueIntersectionSegments count] - clipped2.numberOfShellIntersectionSegments)]];
    }
    if(clipped2.numberOfShellDifferenceSegments < [blueDifferenceSegments count]){
        [blueSegments addObjectsFromArray:[blueDifferenceSegments subarrayWithRange:NSMakeRange(clipped2.numberOfShellDifferenceSegments,
                                                                                                [blueDifferenceSegments count] - clipped2.numberOfShellDifferenceSegments)]];
    }
    
    if(numberOfBlueShellSegments){
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
+(NSArray*) redAndBlueSegmentsForShapeBuildingCreatedFrom:(UIBezierPath*)shapePath bySlicingWithPath:(UIBezierPath*)scissorPath andNumberOfBlueShellSegments:(NSUInteger*)numberOfBlueShellSegments{
    
    NSArray* redGreenAndBlueSegments = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:numberOfBlueShellSegments];
    
    NSMutableArray* redSegments = [NSMutableArray arrayWithArray:[redGreenAndBlueSegments firstObject]];
    NSMutableArray* blueSegments = [NSMutableArray arrayWithArray:[redGreenAndBlueSegments lastObject]];
    
    //
    // filter out any red segments that have unmatched endpoints.
    // this means the segment started/ended inside the shape and not
    // at an intersection point
    [redSegments filterUsingPredicate:[NSPredicate predicateWithBlock:^(id seg, NSDictionary*bindings){
        return (BOOL)!([[seg startIntersection] isKindOfClass:[DKUIBezierUnmatchedPathIntersectionPoint class]] ||
                       [[seg endIntersection] isKindOfClass:[DKUIBezierUnmatchedPathIntersectionPoint class]]);
    }]];
    
    if([scissorPath isClosed] && ![redSegments count]){
        // if we just filtered out cutting a hole in a path,
        // then re-add those unmatched segments back in
        [redSegments addObjectsFromArray:[redGreenAndBlueSegments firstObject]];
    }
    
    // track all of the intersections that the red segments use
    NSMutableSet* redIntersections = [NSMutableSet set];
    [redSegments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
        [redIntersections addObject:[obj startIntersection]];
        [redIntersections addObject:[obj endIntersection]];
    }];
    NSMutableArray* blueSegmentsThatIntersectWithRedSegments = [NSMutableArray array];
    for(int i=0;i<[blueSegments count];i++){
        DKUIBezierPathClippedSegment* currBlueSeg = [blueSegments objectAtIndex:i];
        // if the blue segment's intersection isn't in the list of
        // red segments intersections, then that means that it intersects
        // one of the redsegments that had an unmatched intersection point.
        // this blue segment should be merged with its adjacent blue segment
        NSSet* matchedIntersections = [redIntersections objectsPassingTest:^(id obj, BOOL*stop){
            for(int j=0;j<[redIntersections count];j++){
                if([[[currBlueSeg endIntersection] flipped] isEqualToIntersection:obj]){
                    return YES;
                }
            }
            return NO;
        }];
        if([matchedIntersections count] < 1){
            // we know that the end intersection did not match,
            // so find the other blue segment whose start intersection
            // does not match
            for(int j=0;j<[blueSegments count];j++){
                DKUIBezierPathClippedSegment* possibleMatchedBlueSeg = [blueSegments objectAtIndex:j];
                if([possibleMatchedBlueSeg.startIntersection isEqualToIntersection:currBlueSeg.endIntersection] &&
                   possibleMatchedBlueSeg != currBlueSeg){
                    // merge the two segments
                    UIBezierPath* newPathSegment = currBlueSeg.pathSegment1;
                    [newPathSegment appendPathRemovingInitialMoveToPoint:possibleMatchedBlueSeg.pathSegment1];
                    
                    DKUIBezierPathClippedSegment* newBlueSeg = [DKUIBezierPathClippedSegment clippedPairWithStart:currBlueSeg.startIntersection
                                                                                                           andEnd:possibleMatchedBlueSeg.endIntersection
                                                                                                   andPathSegment:newPathSegment
                                                                                                     fromFullPath:currBlueSeg.fullPath];
                    [blueSegments replaceObjectAtIndex:i withObject:newBlueSeg];
                    [blueSegments removeObject:possibleMatchedBlueSeg];
                    if(numberOfBlueShellSegments){
                        if(i < numberOfBlueShellSegments[0]){
                            // the merged segments were in the shell, so we need to adjust that
                            // number to reflect the newly merged segments
                            numberOfBlueShellSegments[0]--;
                        }
                    }
                    i--;
                    break;
                }
            }
        }else{
            [blueSegmentsThatIntersectWithRedSegments addObject:currBlueSeg];
        }
    }
    
    //
    // now add all of the reverse of our segments to our output
    // so we can approach shape building from either direction
    NSMutableArray* redSegmentsLeftToUse = [NSMutableArray arrayWithArray:redSegments];
    NSMutableArray* blueSegmentsLeftToUse = [NSMutableArray arrayWithArray:blueSegments];
    [redSegments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
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
-(NSArray*) shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:(UIBezierPath*)scissorPath{
    NSMutableArray* subpaths = [NSMutableArray array];
    NSMutableArray* subpathsSegs = [NSMutableArray array];
    NSArray* shapes = [UIBezierPath subshapesCreatedFrom:self bySlicingWithPath:scissorPath];
    [subpaths addObjectsFromArray:[shapes firstObject]];
    [subpathsSegs addObjectsFromArray:[shapes lastObject]];
    return [NSArray arrayWithObjects:subpaths, subpathsSegs, nil];
}



/**
 * returns only unique subshapes, removing duplicates
 */
-(NSArray*) uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:(UIBezierPath*)scissorPath{
    NSArray* shapeShellsAndSubShapes = [self shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* shapeShells = [shapeShellsAndSubShapes firstObject];
    NSArray* subShapes = [shapeShellsAndSubShapes lastObject];
    
    NSArray* (^deduplicateShapes)(NSArray*inter) = ^NSArray*(NSArray* shapes){
        NSMutableArray* uniquePaths = [NSMutableArray array];
        for(DKUIBezierPathShape* possibleDuplicate in shapes){
            if([possibleDuplicate isClosed]){
                // ignore unclosed shapes
                BOOL foundDuplicate = NO;
                for(DKUIBezierPathShape* uniqueShape in uniquePaths){
                    if([uniqueShape isSameShapeAs:possibleDuplicate]){
                        foundDuplicate = YES;
                        break;
                    }
                }
                if(!foundDuplicate){
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
-(NSArray*) uniqueShapesCreatedFromSlicingWithUnclosedPath:(UIBezierPath*)scissorPath{
    NSArray* shapeShellsAndSubShapes = [self uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* shapeShells = [shapeShellsAndSubShapes firstObject];
    NSArray* subShapes = [shapeShellsAndSubShapes lastObject];

    // now i have shape shells and holes, and need to match them together
    for(DKUIBezierPathShape* shell in shapeShells){
        for(DKUIBezierPathShape* sub in subShapes){
            if(![shell sharesSegmentWith:sub]){
                // they don't share a segment
                if([shell.fullPath containsPoint:sub.fullPath.firstPoint]){
                    // it's a hole
                    [shell.holes addObject:sub];
                }
            }
        }
    }
    return shapeShells;
}


+(NSArray*) subshapesCreatedFrom:(UIBezierPath*)shapePath bySlicingWithPath:(UIBezierPath*)scissorPath{
    NSUInteger numberOfBlueShellSegments = 0;
    NSArray* redBlueSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:&numberOfBlueShellSegments];
    NSArray* redSegments = [redBlueSegments firstObject];
    NSArray* blueSegments = [redBlueSegments lastObject];
    
    // now we have all of the red segments and all of the blue segments.
    // next we need to traverse this graph of segments, starting with each
    // red segment and proceeding along the left most path. this will
    // create all of the new shapes possible from these segments.
    return [UIBezierPath generateShapesFromRedSegments:redSegments andBlueSegments:blueSegments comp:[shapePath isClockwise] shapeShellElementCount:(int)numberOfBlueShellSegments];
}


/**
 * red segments are the segments of the scissors that intersect with the shape.
 * blue segments are the segments of the shape that have been split up by the scissors
 *
 * to find subshapes, we start with a red shape, and the follow along the left-most path
 * until we arrive back at the other end of the red shape
 */
+(NSArray*) generateShapesFromRedSegments:(NSArray*)_redSegments andBlueSegments:(NSArray*)_blueSegments comp:(BOOL)gt shapeShellElementCount:(int)shapeShellElementCount{
    
    NSMutableArray* blueSegments = [NSMutableArray array];
    NSMutableArray* redSegments = [NSMutableArray array];

    NSArray* blueSegmentsOfShell = [_blueSegments subarrayWithRange:NSMakeRange(0, shapeShellElementCount)];
    NSMutableSet* intersectionsOfShell = [NSMutableSet set];
    [blueSegmentsOfShell enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
        [intersectionsOfShell addObject:[obj startIntersection]];
        [intersectionsOfShell addObject:[obj endIntersection]];
    }];
    NSMutableArray* output = [NSMutableArray array];
    
    
    
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
    
    for(DKUIBezierPathClippedSegment* red in _redSegments){
        BOOL shouldAdd = YES;
        for(DKUIBezierPathClippedSegment* blue in _blueSegments){
            DKUIBezierPathClippedSegment* flippedBlue = [blue flippedRedBlueSegment];
            if([[red startIntersection] isEqualToIntersection:[flippedBlue startIntersection]] &&
                [[red endIntersection] isEqualToIntersection:[flippedBlue endIntersection]]){
                CGFloat angleBetween = [[red reversedSegment] angleBetween:flippedBlue];
                if([self round:angleBetween to:6] == [self round:M_PI to:6] ||
                   [self round:angleBetween to:6] == [self round:-M_PI to:6]){
                    //
                    // right now, if a segmetn is tangent for red and blue, then
                    // i need to delete teh blue, delete teh reversed red, and leave
                    // the red that's identical to the blue
//                    shouldAdd = YES;
                    // this is the tangent that's identical to blue
                }
            }else if([[red startIntersection] isEqualToIntersection:[flippedBlue endIntersection]] &&
                [[red endIntersection] isEqualToIntersection:[flippedBlue startIntersection]]){
                CGFloat angleBetween = [red angleBetween:flippedBlue];
                if([self round:angleBetween to:6] == [self round:M_PI to:6] ||
                   [self round:angleBetween to:6] == [self round:-M_PI to:6]){
                    //
                    // right now, if a segmetn is tangent for red and blue, then
                    // i need to delete teh blue, delete teh reversed red, and leave
                    // the red that's identical to the blue
                    shouldAdd = NO;
                    // this is the tangent that's reversed from blue
                }
            }
        }
        if(shouldAdd){
            [redSegments addObject:red];
        }
    }
    
    
    for(DKUIBezierPathClippedSegment* blue in _blueSegments){
        BOOL shouldAdd = YES;
        for(DKUIBezierPathClippedSegment* red in _redSegments){
            DKUIBezierPathClippedSegment* flippedBlue = [blue flippedRedBlueSegment];
            if([[red startIntersection] isEqualToIntersection:[flippedBlue startIntersection]] &&
               [[red endIntersection] isEqualToIntersection:[flippedBlue endIntersection]]){
                CGFloat angleBetween = [[red reversedSegment] angleBetween:flippedBlue];
                if([self round:angleBetween to:6] == [self round:M_PI to:6] ||
                   [self round:angleBetween to:6] == [self round:-M_PI to:6]){
                    //
                    // right now, if a segmetn is tangent for red and blue, then
                    // i need to delete teh blue, delete teh reversed red, and leave
                    // the red that's identical to the blue
                    shouldAdd = NO;
                    // this is the tangent that's identical to blue
                }
            }else if([[red startIntersection] isEqualToIntersection:[flippedBlue endIntersection]] &&
                     [[red endIntersection] isEqualToIntersection:[flippedBlue startIntersection]]){
                CGFloat angleBetween = [red angleBetween:flippedBlue];
                if([self round:angleBetween to:6] == [self round:M_PI to:6] ||
                   [self round:angleBetween to:6] == [self round:-M_PI to:6]){
                    //
                    // right now, if a segmetn is tangent for red and blue, then
                    // i need to delete teh blue, delete teh reversed red, and leave
                    // the red that's identical to the blue
//                    shouldAdd = YES;
                    // this is the tangent that's reversed from blue
                }
            }
        }
        if(shouldAdd){
            [blueSegments addObject:blue];
        }
    }
    NSMutableArray* allUnusedBlueSegments = [NSMutableArray arrayWithArray:blueSegments];
    NSMutableArray* redSegmentsToStartWith = [NSMutableArray arrayWithArray:redSegments];

    
    NSMutableArray* holesInNewShapes = [NSMutableArray array];
    
    
    while([redSegmentsToStartWith count] || [allUnusedBlueSegments count]){
        BOOL failedBuildingShape = NO;
        DKUIBezierPathClippedSegment* startingSegment;
        BOOL startedWithRed;
        if([redSegmentsToStartWith count]){
            startingSegment = [redSegmentsToStartWith firstObject];
            [redSegmentsToStartWith removeObjectAtIndex:0];
            startedWithRed = YES;
        }else{
            startingSegment = [allUnusedBlueSegments firstObject];
            [allUnusedBlueSegments removeObject:startingSegment];
            startingSegment = [startingSegment flippedRedBlueSegment];
            startedWithRed = NO;
        }
        NSMutableArray* usedBlueSegments = [NSMutableArray array];
        DKUIBezierPathShape* currentlyBuiltShape = [UIBezierPath buildShapeWithRedSegments:startedWithRed ? redSegments : @[]
                                                                           andBlueSegments:blueSegments
                                                                        andStartingSegment:startingSegment
                                                                                      comp:gt
                                                                              andSetFailed:&failedBuildingShape
                                                                    andSetUsedBlueSegments:usedBlueSegments];
        
        if(failedBuildingShape){
            NSLog(@"found failed shape");
            // allow any used up blue segments to be used
            // next time, and don't add the shape
//            [output addObject:currentlyBuiltShape];
            [usedBlueSegments removeAllObjects];
        }else{
            //            NSLog(@"adding shape");
            
            NSIndexSet* indexes = [currentlyBuiltShape.segments indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL* stop){
                // all shape segments, when blue, will have been flipped
                return (BOOL)([intersectionsOfShell containsObject:[[obj startIntersection] flipped]] ||
                              [intersectionsOfShell containsObject:[[obj endIntersection] flipped]]);
            }];
            
            if([indexes count]){
                // shape does intersect with the shell
                [output addObject:currentlyBuiltShape];
            }else{
                if(startedWithRed){
                    //
                    // in addition to checking if it intersects with the shell,
                    // i also need to find out if i just found a shape that matches the
                    // shell's clockwise/counterclockwise rotation, or not
                    //
                    // if this shape matches the shell's rotation, then it's a shape.
                    //
                    // if it does not match the shell's rotation, then it's a hole
                    if([currentlyBuiltShape.fullPath isClockwise] == gt){
                        // it's a shape
                        [output addObject:currentlyBuiltShape];
                    }else{
                        [holesInNewShapes addObject:currentlyBuiltShape];
                        if([currentlyBuiltShape.segments count] == 1){
                            [output addObject:currentlyBuiltShape];
                        }
                    }
                }else{
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
    
    return [NSArray arrayWithObjects:output, holesInNewShapes, nil];
}

+(DKUIBezierPathClippedSegment*) getBestMatchSegmentForSegments:(NSArray*)shapeSegments
                                                         forRed:(NSArray*)redSegments
                                                        andBlue:(NSArray*)blueSegments
                                                     lastWasRed:(BOOL)lastWasRed
                                                           comp:(BOOL)gt{
    
    DKUIBezierPathClippedSegment* segment = [shapeSegments lastObject];
    
    NSMutableArray* redSegmentsLeftToUse = [NSMutableArray arrayWithArray:redSegments];
    NSMutableArray* blueSegmentsLeftToUse = [NSMutableArray arrayWithArray:blueSegments];
    
    // first, find the blue segment that can attach to this red segment.
    DKUIBezierPathClippedSegment* currentSegmentCandidate = nil;
    // only allow looking at blue if our last segment was red
    if(lastWasRed){
        for(int bi=0; bi<[blueSegmentsLeftToUse count]; bi++){
            DKUIBezierPathClippedSegment* blueSeg = [blueSegmentsLeftToUse objectAtIndex:bi];
            if([blueSeg.startIntersection crossMatchesIntersection:[segment endIntersection]]){
                if(!currentSegmentCandidate){
                    DKVector* currSeg = [[segment pathSegment1] tangentNearEnd].tangent;
                    DKVector* currPoss = [[blueSeg pathSegment1] tangentNearStart].tangent;
                    //                        NSLog(@"angle: %f", [currSeg angleBetween:currPoss]);
                    if([UIBezierPath round:[currSeg angleBetween:currPoss] to:6] == [UIBezierPath round:M_PI to:6]){
                        // never allow exactly backwards tangents
                    }else if([UIBezierPath round:[currSeg angleBetween:currPoss] to:6] == [UIBezierPath round:-M_PI to:6]){
                        // never allow exactly backwards tangents
                    }else{
                        currentSegmentCandidate = blueSeg;
                        lastWasRed = NO;
                    }
                }else{
                    DKVector* currSeg = [[segment pathSegment1] tangentNearEnd].tangent;
                    DKVector* currPoss = [[currentSegmentCandidate pathSegment1] tangentNearStart].tangent;
                    DKVector* newPoss = [[blueSeg pathSegment1] tangentNearStart].tangent;
                    //                        NSLog(@"angle: %f vs %f", [currSeg angleBetween:currPoss], [currSeg angleBetween:newPoss]);
                    if(gt){
                        if([currSeg angleBetween:newPoss] > [currSeg angleBetween:currPoss]){
                            if([UIBezierPath round:[currSeg angleBetween:newPoss] to:3] == [UIBezierPath round:M_PI to:3]){
                                // never allow exactly backwards tangents
                            }else{
                                currentSegmentCandidate = blueSeg;
                                lastWasRed = NO;
                            }
                        }
                    }else{
                        if([currSeg angleBetween:newPoss] < [currSeg angleBetween:currPoss]){
                            if([UIBezierPath round:[currSeg angleBetween:newPoss] to:3] == [UIBezierPath round:-M_PI to:3]){
                                // never allow exactly backwards tangents
                            }else{
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
    for (int ri = 0; ri<[redSegmentsLeftToUse count]; ri++) {
        DKUIBezierPathClippedSegment* redSeg = [redSegmentsLeftToUse objectAtIndex:ri];
        //
        // i need to track how the segments in the shape are being held. right now
        // crossMatchesIntersection checks the elementIndex1 with elementIndex2. if the segment is set
        // as a red segment, then the red segments here will never match, because the elementIndex1
        // would only ever match elementIndex1. We need to flip the last segment so that
        // it looks like a "blue", which would match a red segment
        DKUIBezierPathClippedSegment* lastSegmentInShapeAsBlue = [segment flippedRedBlueSegment];
        if([redSeg.startIntersection crossMatchesIntersection:[lastSegmentInShapeAsBlue endIntersection]]){
            if(!currentSegmentCandidate){
                DKVector* currSeg = [[segment pathSegment1] tangentNearEnd].tangent;
                DKVector* currPoss = [[redSeg pathSegment1] tangentNearStart].tangent;
                //                    NSLog(@"angle: %f", [currSeg angleBetween:currPoss]);
                if([UIBezierPath round:[currSeg angleBetween:currPoss] to:6] == [UIBezierPath round:M_PI to:6]){
                    // never allow exactly backwards tangents
                }else if([UIBezierPath round:[currSeg angleBetween:currPoss] to:6] == [UIBezierPath round:-M_PI to:6]){
                    // never allow exactly backwards tangents
                }else{
                    currentSegmentCandidate = redSeg;
                    lastWasRed = YES;
                }
            }else{
                DKVector* currSeg = [[segment pathSegment1] tangentNearEnd].tangent;
                DKVector* currPoss = [[currentSegmentCandidate pathSegment1] tangentNearStart].tangent;
                DKVector* newPoss = [[redSeg pathSegment1] tangentNearStart].tangent;
                if(gt){
                    if([currSeg angleBetween:newPoss] >= [currSeg angleBetween:currPoss]){
                        if([UIBezierPath round:[currSeg angleBetween:newPoss] to:3] == [UIBezierPath round:M_PI to:3]){
                            // never allow exactly backwards tangents
                        }else{
                            currentSegmentCandidate = redSeg;
                            lastWasRed = YES;
                        }
                    }
                }else{
                    if([currSeg angleBetween:newPoss] <= [currSeg angleBetween:currPoss]){
                        if([UIBezierPath round:[currSeg angleBetween:newPoss] to:3] == [UIBezierPath round:-M_PI to:3]){
                            // never allow exactly backwards tangents
                        }else{
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
-(UIBezierPath*) differenceOfPathTo:(UIBezierPath*)shapePath{
    BOOL beginsInside1 = NO;
    NSMutableArray* tValuesOfIntersectionPoints = [NSMutableArray arrayWithArray:[self findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside1]];
    DKUIBezierPathClippingResult* clipped = [self clipUnclosedPathToClosedPath:shapePath usingIntersectionPoints:tValuesOfIntersectionPoints andBeginsInside:beginsInside1];
    return clipped.entireDifferencePath;
}


/**
 * points toward the direction of the curve
 * along the tangent of the curve
 * near the end of the curve
 */
-(DKTangentAtPoint*) tangentNearEnd{
//    return [self tangentRoundingNearStartOrEnd:1.0];
    return [self tangentRoundingNearStartOrEnd:.999];
}

/**
 * points toward the direction of the curve
 * along the tangent of the curve
 * near the end of the curve
 */
-(DKTangentAtPoint*) tangentNearStart{
//    DKTangentAtPoint* tan = [self tangentRoundingNearStartOrEnd:0.0];
//    return [DKTangentAtPoint tangent:[tan.tangent flip] atPoint:tan.point];
    return [self tangentRoundingNearStartOrEnd:.001];
}


#pragma mark - Private Helpers

+(DKUIBezierPathShape*) buildShapeWithRedSegments:(NSArray*)redSegments
                                  andBlueSegments:(NSArray*)blueSegments
                               andStartingSegment:(DKUIBezierPathClippedSegment*)startingSegment
                                             comp:(BOOL)gt
                                     andSetFailed:(BOOL*)failedBuildingShape
                           andSetUsedBlueSegments:(NSMutableArray*)usedBlueSegments{
    
    //
    // each shape gets to use all the segments if it wants, just starting
    // with a new segment
    NSMutableArray* redSegmentsLeftToUse = [NSMutableArray arrayWithArray:redSegments];
    NSMutableArray* blueSegmentsLeftToUse = [NSMutableArray arrayWithArray:blueSegments];
    
    DKUIBezierPathShape* currentlyBuiltShape = [[DKUIBezierPathShape alloc] init];
    [currentlyBuiltShape.segments addObject:startingSegment];
    
    failedBuildingShape[0] = NO;
    BOOL lastWasRed = [redSegments containsObject:startingSegment];
    while(!failedBuildingShape[0]){
        // we'll set us to failed unless we can add a segment.
        // when we add a segment below, then that triggers that
        // we've not failed
        failedBuildingShape[0] = YES;
        
        // first, find the blue segment that can attach to this red segment.
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:currentlyBuiltShape.segments
                                                                                                      forRed:redSegmentsLeftToUse
                                                                                                     andBlue:blueSegmentsLeftToUse
                                                                                                  lastWasRed:lastWasRed
                                                                                                        comp:gt];
        if([currentSegmentCandidate isEqualToSegment:[currentlyBuiltShape.segments firstObject]]){
            // shape is complete when we would have chosen the segment that
            // we started with
            failedBuildingShape[0] = NO;
            break;
        }
        
        if(currentSegmentCandidate){
            failedBuildingShape[0] = NO;
            lastWasRed = [redSegmentsLeftToUse containsObject:currentSegmentCandidate];
            if(lastWasRed){
                [currentlyBuiltShape.segments addObject:currentSegmentCandidate];
            }else{
                // it's a blue segment. redefine the segment in terms of red endpoints
                // so that we can know if its closed or not
                [usedBlueSegments addObject:currentSegmentCandidate];
                [currentlyBuiltShape.segments addObject:[currentSegmentCandidate flippedRedBlueSegment]];
            }
            [redSegmentsLeftToUse removeObject:currentSegmentCandidate];
            [blueSegmentsLeftToUse removeObject:currentSegmentCandidate];
        }
    }
    if([currentlyBuiltShape.segments count] == 1){
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
-(DKTangentAtPoint*) tangentRoundingNearStartOrEnd:(CGFloat)tValue{
    if(tValue == 0){
        // return tangentAtStart
        return [DKTangentAtPoint tangent:[DKVector vectorWithAngle:[self tangentAtStart]] atPoint:[self firstPoint]];;
    }else if(tValue == 1){
        // return tangentAtEnd
        return [DKTangentAtPoint tangent:[DKVector vectorWithAngle:[self tangentAtEnd]] atPoint:[self lastPoint]];;
    }
    
    __block CGFloat entireLength = 0;
    __block CGPoint lastPoint = CGNotFoundPoint;
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger idx){
        CGPoint nextLastPoint = lastPoint;
        if(element.type == kCGPathElementAddLineToPoint){
            nextLastPoint = element.points[0];
        }else if(element.type == kCGPathElementAddQuadCurveToPoint){
            nextLastPoint = element.points[1];
        }else if(element.type == kCGPathElementAddCurveToPoint){
            nextLastPoint = element.points[2];
        }else if(element.type == kCGPathElementMoveToPoint){
            nextLastPoint = element.points[0];
        }else if(element.type == kCGPathElementCloseSubpath){
            nextLastPoint = self.firstPoint;
        }
        
        if(CGPointEqualToPoint(lastPoint, CGNotFoundPoint) || element.type == kCGPathElementMoveToPoint){
            lastPoint = element.points[0];
        }else if(element.type != kCGPathElementCloseSubpath){
            entireLength += distance(lastPoint, nextLastPoint);
        }
        
        lastPoint = nextLastPoint;
    }];
    
    // at this point, we have a very rough length of the segment.
    // we treat all curvs as lines, so it's very far from perfect, but
    // good enough for our needs
    
    __block DKTangentAtPoint* ret = nil;
    
    
    const int maxDist = [UIBezierPath maxDistForEndPointTangents];
    CGFloat lengthAtT = entireLength * tValue;
    if(tValue > .5){
        if(lengthAtT < entireLength - maxDist){
            lengthAtT = entireLength - maxDist;
            tValue = lengthAtT / entireLength;
        }
    }else{
        if(lengthAtT > maxDist){
            lengthAtT = maxDist;
            tValue = lengthAtT / entireLength;
        }
    }
    
    __block CGFloat tValueToUse = tValue;
    
    __block CGFloat lengthSoFar = 0;
    lastPoint = CGNotFoundPoint;
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger idx){
        // if we have an answer, just exit
        if(ret) return;
        CGPoint nextLastPoint = lastPoint;
        if(element.type == kCGPathElementAddLineToPoint){
            nextLastPoint = element.points[0];
        }else if(element.type == kCGPathElementAddQuadCurveToPoint){
            nextLastPoint = element.points[1];
        }else if(element.type == kCGPathElementAddCurveToPoint){
            nextLastPoint = element.points[2];
        }else if(element.type == kCGPathElementMoveToPoint){
            nextLastPoint = element.points[0];
        }else if(element.type == kCGPathElementCloseSubpath){
            nextLastPoint = self.firstPoint;
        }
        
        // we're still looking for the element that contains t
        CGFloat lengthOfElement = 0;
        if(CGPointEqualToPoint(lastPoint, CGNotFoundPoint) || element.type == kCGPathElementMoveToPoint){
            lastPoint = element.points[0];
            nextLastPoint = lastPoint;
        }else if(element.type != kCGPathElementCloseSubpath){
            lengthOfElement = distance(lastPoint, nextLastPoint);
        }
        if(lengthSoFar + lengthOfElement > lengthAtT){
            // this is the element to use for our calculation
            // scale the tvalue to this element
            
            // chop the front of the path off
            CGFloat tSoFar = lengthSoFar / entireLength;
            tValueToUse = tValueToUse - tSoFar;
            
            // chop off the end of the path
            CGFloat tDurationOfElement = (lengthOfElement) / entireLength;
            if(tDurationOfElement){
                tValueToUse /= tDurationOfElement;
            }
            
            // use this tvalue
            CGPoint bez[4];
            bez[0] = lastPoint;
            bez[3] = element.points[0];
            if(element.type == kCGPathElementAddLineToPoint){
                CGFloat width = element.points[0].x - lastPoint.x;
                CGFloat height = element.points[0].y - lastPoint.y;
                bez[1] = CGPointMake(lastPoint.x + width/3.0, lastPoint.y + height/3.0);
                bez[2] = CGPointMake(lastPoint.x + width/3.0*2.0, lastPoint.y + height/3.0*2.0);
            }else if(element.type == kCGPathElementAddQuadCurveToPoint){
                bez[0] = lastPoint;
                bez[1] = element.points[0];
                bez[2] = element.points[0];
                bez[3] = element.points[1];
            }else if(element.type == kCGPathElementAddCurveToPoint){
                bez[0] = lastPoint;
                bez[1] = element.points[0];
                bez[2] = element.points[1];
                bez[3] = element.points[2];
            }
            
            CGPoint tangent = [UIBezierPath tangentAtT:tValueToUse forBezier:bez];
            CGPoint point = [UIBezierPath pointAtT:tValueToUse forBezier:bez];
            
            ret = [DKTangentAtPoint tangent:[[DKVector vectorWithX:tangent.x andY:tangent.y] normal]  atPoint:point];
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
+(CGFloat) maxDistForEndPointTangents{
    return 5;
}


/**
 * this will return an unfiltered array of intersections between
 * the two input bezier curves. it will also blindly try to find
 * intersections, even if the two input curves do not share
 * any overlapping bounds (though it would still return quickly)
 */
+(NSArray*) findIntersectionsBetweenBezier:(CGPoint[4])bez1 andBezier:(CGPoint[4])bez2{
    NSMutableArray* intersectionsOutput = [NSMutableArray array];
    NSMutableArray* altIntersectionsOutput = [NSMutableArray array];
    
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
    if([altIntersectionsOutput count] > [intersectionsOutput count]){
        NSMutableArray* altRet = [NSMutableArray array];
        [altIntersectionsOutput enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL*stop){
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
+(CGFloat) estimateArcLengthOf:(CGPoint*)bez1 withSteps:(NSInteger)steps{
    
    CGFloat td = 1.0 / steps;
    CGPoint b = bez1[0];
    CGFloat dX=0, dY=0;
    CGFloat dS = 0;
    CGFloat sumArc = 0;
    CGFloat t = 0;
    
    for (int i=0; i<steps; i++) {
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
+(CGPoint) fillCGPoints:(CGPoint*)bez withElement:(CGPathElement)element givenElementStartingPoint:(CGPoint)startPoint andSubPathStartingPoint:(CGPoint)pathStartPoint{
    if(element.type == kCGPathElementCloseSubpath){
        // treat a close path as a line from the current starting
        // point back to the beginning of the line
        bez[0] = startPoint;
        bez[1] = CGPointMake(startPoint.x + (pathStartPoint.x - startPoint.x)/3.0, startPoint.y + (pathStartPoint.y - startPoint.y)/3.0);
        bez[2] = CGPointMake(startPoint.x + (pathStartPoint.x - startPoint.x)*2.0/3.0, startPoint.y + (pathStartPoint.y - startPoint.y)*2.0/3.0);
        bez[3] = pathStartPoint;
        return pathStartPoint;
    }else if(element.type == kCGPathElementMoveToPoint){
        bez[0] = element.points[0];
        bez[1] = element.points[0];
        bez[2] = element.points[0];
        bez[3] = element.points[0];
        return element.points[0];
    }else if(element.type == kCGPathElementAddLineToPoint){
        bez[0] = startPoint;
        bez[1] = CGPointMake(startPoint.x + (element.points[0].x - startPoint.x)/3.0, startPoint.y + (element.points[0].y - startPoint.y)/3.0);
        bez[2] = CGPointMake(startPoint.x + (element.points[0].x - startPoint.x)*2.0/3.0, startPoint.y + (element.points[0].y - startPoint.y)*2.0/3.0);
        bez[3] = element.points[0];
        return element.points[0];
    }else if(element.type == kCGPathElementAddQuadCurveToPoint){
        bez[0] = startPoint;
        bez[1] = element.points[0];
        bez[2] = element.points[0];
        bez[3] = element.points[1];
        return element.points[1];
    }else if(element.type == kCGPathElementAddCurveToPoint){
        bez[0] = startPoint;
        bez[1] = element.points[0];
        bez[2] = element.points[1];
        bez[3] = element.points[2];
        return element.points[2];
    }else{
        // impossible, but listed for the compiler's
        // happiness (unless new element types are added
        // one day...)
        return CGPointZero;
    }
}

+(CGFloat) round:(CGFloat)val to:(int)digits{
    double factor = pow(10, digits);
    return roundf(val * factor) / factor;
}


CGFloat distance(const CGPoint p1, const CGPoint p2) {
    CGFloat dist = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
    return dist;
}

@end

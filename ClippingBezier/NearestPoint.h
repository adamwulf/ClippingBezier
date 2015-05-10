//
//  NearestPoint.h
//  ClippingBezier
//
//  Created by Adam Wulf on 5/9/15.
//
//

#ifndef __ClippingBezier__NearestPoint__
#define __ClippingBezier__NearestPoint__

#include <stdio.h>
#import <CoreGraphics/CoreGraphics.h>

CGPoint NearestPointOnCurve(CGPoint P, CGPoint* V, double* t);

int FindRoots(CGPoint* w, int degree,double* t, int depth);

#endif /* defined(__ClippingBezier__NearestPoint__) */

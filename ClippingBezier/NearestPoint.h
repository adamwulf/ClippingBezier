//
//  NearestPoint.h
//  ClippingBezier
//
//  Created by Adam Wulf on 5/9/15.
//
//

#ifndef __ClippingBezier__NearestPoint__
#define __ClippingBezier__NearestPoint__

#if defined __cplusplus
extern "C" {
#endif


#include <stdio.h>
#import <CoreGraphics/CoreGraphics.h>

// Bezier functions from git@github.com:erich666/GraphicsGems.git
CGPoint NearestPointOnCurve(const CGPoint P, const CGPoint *V, double *t);

int FindRoots(CGPoint *w, int degree, double *t, int depth);

#if defined __cplusplus
}
#endif

#endif /* defined(__ClippingBezier__NearestPoint__) */

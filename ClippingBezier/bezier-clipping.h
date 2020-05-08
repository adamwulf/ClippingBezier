//
//  bezier-clipping.h
//  ClippingBezier
//
//  Created by Adam Wulf on 5/23/15.
//
//

#ifndef ClippingBezier_bezier_clipping_h
#define ClippingBezier_bezier_clipping_h

#include "interval.h"
#include "point.h"
#import <Foundation/Foundation.h>
#include <vector>

namespace Geom
{
typedef void clip_fnc_t(Interval &,
                        std::vector<Point> const &,
                        std::vector<Point> const &,
                        double);

void intersections_clip(Interval &dom,
                        std::vector<Point> const &A,
                        std::vector<Point> const &B,
                        double precision);

void get_solutions(NSMutableArray *xs,
                   std::vector<Point> const &A,
                   std::vector<Point> const &B,
                   double precision,
                   clip_fnc_t *clip);
}
#endif

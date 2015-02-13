//
//  ClippingBezier.h
//  ClippingBezier
//
//  Created by Adam Wulf on 2/12/15.
//
//

#import <Foundation/Foundation.h>

#import "DKIntersectionOfPaths.h"
#import "DKUIBezierPathShape.h"
#import "DKUIBezierPathClippedSegment.h"
#import "UIBezierPath+Clipping.h"
#import "UIBezierPath+Clipping_Private.h"
#import "UIBezierPath+Intersections.h"
#import "UIBezierPath+GeometryExtras.h"
#import "UIBezierPath+DKOSX.h"
#import "NSArray+FirstObject.h"
#import "DKUIBezierPathClippedSegment.h"
#import "DKUIBezierPathClippingResult.h"
#import "DKUIBezierPathIntersectionPoint.h"
#import "DKUIBezierPathIntersectionPoint+Private.h"
#import "DKUIBezierUnmatchedPathIntersectionPoint.h"
#import "DKUIBezierPathShape.h"
#import "DKTangentAtPoint.h"
#import "JRSwizzle.h"
#import "MMBackwardCompatible.h"
#include "bezierclip.hxx"

#pragma mark - DrawKit
#import "UIBezierPath+GPC.h"
#import "UIBezierPath+Editing.h"
#import "UIBezierPath+Geometry.h"
#import "UIBezierPath+Ahmed.h"
#import "DKGeometryUtilities.h"

#include "math.h"

#pragma mark - PerformanceBezier

#import "UIBezierPathProperties.h"
#import "UIBezierPath+Clockwise.h"
#import "UIBezierPath+Performance.h"
#import "UIBezierPath+NSOSX.h"
#import "UIBezierPath+Equals.h"
#import "UIBezierPath+Center.h"
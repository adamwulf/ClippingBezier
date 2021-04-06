//
//  ClippingBezier.h
//  ClippingBezier
//
//  Created by Adam Wulf on 2/12/15.
//
//

#import <Foundation/Foundation.h>

// SwiftPackageManager needs imports to be "", while frameworks generally want <>
// It's unfortunately not enough to `#if SWIFT_PACKAGE`, as if ClippingBezier
// is a dependency of another SPM package, then the SWIFT_PACKAGE seems to not be
// set when building that dependency. So instead, we'll choose based off of Cocoapods

#if COCOAPODS
#import <ClippingBezier/DKIntersectionOfPaths.h>
#import <ClippingBezier/DKIntersectionOfPaths.h>
#import <ClippingBezier/DKUIBezierPathShape.h>
#import <ClippingBezier/DKUIBezierPathClippedSegment.h>
#import <ClippingBezier/UIBezierPath+Clipping.h>
#import <ClippingBezier/UIBezierPath+Intersections.h>
#import <ClippingBezier/UIBezierPath+GeometryExtras.h>
#import <ClippingBezier/UIBezierPath+DKOSX.h>
#import <ClippingBezier/UIBezierPath+Trimming.h>
#import <ClippingBezier/DKUIBezierPathClippedSegment.h>
#import <ClippingBezier/DKUIBezierPathClippingResult.h>
#import <ClippingBezier/DKUIBezierPathIntersectionPoint.h>
#import <ClippingBezier/DKUIBezierUnmatchedPathIntersectionPoint.h>
#import <ClippingBezier/DKUIBezierPathShape.h>
#import <ClippingBezier/DKTangentAtPoint.h>
#import <ClippingBezier/DKVector.h>
#import <ClippingBezier/MMBackwardCompatible.h>
#else
#import "DKIntersectionOfPaths.h"
#import "DKIntersectionOfPaths.h"
#import "DKUIBezierPathShape.h"
#import "DKUIBezierPathClippedSegment.h"
#import "UIBezierPath+Clipping.h"
#import "UIBezierPath+Intersections.h"
#import "UIBezierPath+GeometryExtras.h"
#import "UIBezierPath+DKOSX.h"
#import "UIBezierPath+Trimming.h"
#import "DKUIBezierPathClippedSegment.h"
#import "DKUIBezierPathClippingResult.h"
#import "DKUIBezierPathIntersectionPoint.h"
#import "DKUIBezierUnmatchedPathIntersectionPoint.h"
#import "DKUIBezierPathShape.h"
#import "DKTangentAtPoint.h"
#import "DKVector.h"
#import "MMBackwardCompatible.h"
#endif
//#include "bezierclip.hxx"

//
//  UIBezierPath+DKOSX.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 2/1/15.
//  Copyright (c) 2015 Adam Wulf. All rights reserved.
//

#import "UIBezierPath+DKOSX.h"
#import "MMBackwardCompatible.h"
#import <DrawKit-iOS/DrawKit-iOS.h>
#import "UIBezierPath+Intersections.h"

@implementation UIBezierPath (DKOSX)

/**
 * ios 6+ reverse bezier paths by reversing each subpath in order
 * so we're going to mimic that here
 */
-(UIBezierPath*) nsosx_backwardcompatible_bezierPathByReversingPath{
    UIBezierPath* output = [UIBezierPath bezierPath];
    for(UIBezierPath* subPath in [self subPaths]){
        [output appendPath:[subPath nsosx_backwardcompatible_bezierPathByReversingPath_helper]];
    }
    return output;
}

-(UIBezierPath*) nsosx_backwardcompatible_bezierPathByReversingPath_helper{
    
    int eleCount = (int) [self elementCount];
    UIBezierPath* output = [UIBezierPath bezierPath];
    [output moveToPoint:[self lastPoint]];
    
    for(int i = eleCount-1; i>=1;i--){
        CGPathElement element = [self elementAtIndex:i];
        CGPathElement prevElement = [self elementAtIndex:i-1];
        
        if(element.type == kCGPathElementMoveToPoint){
            [output moveToPoint:[UIBezierPath endPointForPathElement:prevElement]];
        }else if(element.type == kCGPathElementAddLineToPoint){
            [output addLineToPoint:[UIBezierPath endPointForPathElement:prevElement]];
        }else if(element.type == kCGPathElementAddCurveToPoint){
            [output addCurveToPoint:[UIBezierPath endPointForPathElement:prevElement]
                      controlPoint1:element.points[1]
                      controlPoint2:element.points[0]];
        }else if(element.type == kCGPathElementAddQuadCurveToPoint){
            [output addQuadCurveToPoint:[UIBezierPath endPointForPathElement:prevElement] controlPoint:element.points[0]];
        }else if(element.type == kCGPathElementCloseSubpath){
            [output moveToPoint:[UIBezierPath endPointForPathElement:prevElement]];
        }
    }
    if([self isClosed]){
        [output closePath];
    }
    return output;
}

+(void)load{
    @autoreleasepool {
        NSError *error = nil;

        //
        // the builtin implementation of bezierPathByReversingPath has bugs in it
        // with closed paths
        [UIBezierPath mm_defineOrSwizzleMethod:@selector(bezierPathByReversingPath)
                                    withMethod:@selector(nsosx_backwardcompatible_bezierPathByReversingPath)
                                         error:&error];
    }
}
@end

//
//  DKTangentAtPoint.m
//  ClippingBezier
//
//  Created by Adam Wulf on 11/25/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import "DKTangentAtPoint.h"

@implementation DKTangentAtPoint {
    DKVector *tangent;
    CGPoint point;
}

@synthesize tangent;
@synthesize point;

- (void)setTangent:(DKVector *)_tangent
{
    tangent = _tangent;
}

- (void)setPoint:(CGPoint)_point
{
    point = _point;
}

+ (DKTangentAtPoint *)tangent:(DKVector *)_tangent atPoint:(CGPoint)_point
{
    DKTangentAtPoint *ret = [[DKTangentAtPoint alloc] init];
    ret.tangent = _tangent;
    ret.point = _point;
    return ret;
}

@end

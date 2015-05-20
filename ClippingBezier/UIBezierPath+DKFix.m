//
//  UIBezierPath+DKFix.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/9/15.
//
//

#import "UIBezierPath+DKFix.h"
#import <PerformanceBezier/PerformanceBezier.h>
#import "ClippingBezier.h"

@implementation UIBezierPath (DKFix)

-(void) appendPathRemovingInitialMoveToPoint:(UIBezierPath*)otherPath{
    [otherPath iteratePathWithBlock:^(CGPathElement element, NSUInteger idx) {
        if(idx > 0){
            [self addPathElement:element];
        }
    }];
}

-(NSArray*) subPaths{
    NSMutableArray* output = [NSMutableArray array];
    __block UIBezierPath* subpath = nil;
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger idx) {
        if(element.type == kCGPathElementMoveToPoint){
            if(subpath) [output addObject:subpath];
            subpath = [UIBezierPath bezierPath];
        }
        [subpath addPathElement:element];
    }];
    if(subpath) [output addObject:subpath];
    return output;
}

-(NSInteger) countSubPaths{
    return 0;
}

- (UIBezierPath*) bezierPathByTrimmingFromLength:(CGFloat)trimLength{
    return nil;
}

- (UIBezierPath*) bezierPathByTrimmingToLength:(CGFloat)trimLength{
    return nil;
}

- (NSInteger) subpathIndexForElement:(NSInteger) element{
    return 0;
}

- (CGFloat) length{
    return 0;
}

- (CGFloat) tangentAtStart{
    return 0;
}

+(void) subdivideBezier:(CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2 atT:(CGFloat)t{
    subdivideBezierAtT(bez, bez1, bez2, t);
}


/**
 * will divide a bezier curve into two curves at time t
 * 0 <= t <= 1.0
 *
 * these two curves will exactly match the former single curve
 */
static inline void subdivideBezierAtT(const CGPoint bez[4], CGPoint bez1[4], CGPoint bez2[4], CGFloat t){
    CGPoint q;
    CGFloat mt = 1 - t;
    
    bez1[0].x = bez[0].x;
    bez1[0].y = bez[0].y;
    bez2[3].x = bez[3].x;
    bez2[3].y = bez[3].y;
    
    q.x = mt * bez[1].x + t * bez[2].x;
    q.y = mt * bez[1].y + t * bez[2].y;
    bez1[1].x = mt * bez[0].x + t * bez[1].x;
    bez1[1].y = mt * bez[0].y + t * bez[1].y;
    bez2[2].x = mt * bez[2].x + t * bez[3].x;
    bez2[2].y = mt * bez[2].y + t * bez[3].y;
    
    bez1[2].x = mt * bez1[1].x + t * q.x;
    bez1[2].y = mt * bez1[1].y + t * q.y;
    bez2[1].x = mt * q.x + t * bez2[2].x;
    bez2[1].y = mt * q.y + t * bez2[2].y;
    
    bez1[3].x = bez2[0].x = mt * bez1[2].x + t * bez2[1].x;
    bez1[3].y = bez2[0].y = mt * bez1[2].y + t * bez2[1].y;
}

@end

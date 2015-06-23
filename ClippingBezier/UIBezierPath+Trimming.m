//
//  UIBezierPath+DKFix.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/9/15.
//
//

#import "UIBezierPath+Trimming.h"
#import <PerformanceBezier/PerformanceBezier.h>
#import "ClippingBezier.h"

@implementation UIBezierPath (Trimming)

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
            if(subpath && [subpath elementCount] > 1) [output addObject:subpath];
            subpath = [UIBezierPath bezierPath];
        }
        [subpath addPathElement:element];
    }];
    if(subpath && [subpath elementCount] > 1) [output addObject:subpath];
    return output;
}

-(NSInteger) countSubPaths{
    return [[self subPaths] count];
}

- (UIBezierPath*) bezierPathByTrimmingFromLength:(CGFloat)trimLength{
    return nil;
}

- (UIBezierPath*) bezierPathByTrimmingToLength:(CGFloat)trimLength{
    return nil;
}

- (UIBezierPath*) bezierPathByTrimmingToLength:(CGFloat)trimLength withMaximumError:(CGFloat)err{
    return nil;
}

- (NSInteger) subpathIndexForElement:(NSInteger) element{
    return 0;
}

- (CGFloat) length{
    return 0;
}

- (CGFloat) tangentAtStart{
    if([self elementCount] < 2){
        return 0.0;
    }
    
    CGPathElement ele1 = [self elementAtIndex:0];
    CGPathElement ele2 = [self elementAtIndex:1];
    
    if(ele1.type != kCGPathElementMoveToPoint){
        return 0.0;
    }
    
    CGPoint point1 = ele1.points[0];
    CGPoint point2 = CGPointZero;
    
    switch (ele2.type) {
        case kCGPathElementMoveToPoint:
            return 0.0;
            break;
        case kCGPathElementAddCurveToPoint:
        case kCGPathElementAddQuadCurveToPoint:
        case kCGPathElementAddLineToPoint:
            point2 = ele2.points[0];
            break;
        case kCGPathElementCloseSubpath:
            return 0.0;
            break;
    }

    return atan2f( point2.y - point1.y, point2.x - point1.x ) + M_PI;
}

- (CGFloat) tangentAtStartOfSubpath:(NSInteger)index{
    return [[[self subPaths] objectAtIndex:index] tangentAtStart];
}


@end

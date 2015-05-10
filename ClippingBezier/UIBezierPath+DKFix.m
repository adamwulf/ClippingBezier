//
//  UIBezierPath+DKFix.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/9/15.
//
//

#import "UIBezierPath+DKFix.h"
#import <PerformanceBezier/PerformanceBezier.h>

@implementation UIBezierPath (DKFix)

-(void) appendPathRemovingInitialMoveToPoint:(UIBezierPath*)otherPath{
    
}

-(NSArray*) subPaths{
    return nil;
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

@end

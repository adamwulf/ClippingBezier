//
//  UIBezierPath+DKFix.h
//  ClippingBezier
//
//  Created by Adam Wulf on 5/9/15.
//
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (DKFix)

-(void) appendPathRemovingInitialMoveToPoint:(UIBezierPath*)otherPath;

-(NSArray*) subPaths;

-(NSInteger) countSubPaths;

- (NSInteger) subpathIndexForElement:(NSInteger) element;

- (CGFloat) length;

- (CGFloat) tangentAtStart;

- (UIBezierPath*) bezierPathByTrimmingFromLength:(CGFloat)trimLength;

- (UIBezierPath*) bezierPathByTrimmingToLength:(CGFloat)trimLength;

+(void) subdivideBezier:(CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2 atT:(CGFloat)t;


@end

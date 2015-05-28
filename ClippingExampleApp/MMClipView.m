//
//  MMClipView.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/23/15.
//
//

#import "MMClipView.h"
#import <ClippingBezier/ClippingBezier.h>

@implementation MMClipView

-(void) drawRect:(CGRect)rect{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];

    NSArray* intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray* otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    [[UIColor greenColor] setStroke];
    [shapePath stroke];
    
    [[UIColor purpleColor] setStroke];
    [scissorPath stroke];
    
    for (DKUIBezierPathIntersectionPoint* intersection in otherIntersections) {
        [[UIColor redColor] setFill];
        CGPoint p = intersection.location1;
        NSLog(@"p: %f %f", p.x, p.y);
        [[UIBezierPath bezierPathWithArcCenter:p radius:3 startAngle:0 endAngle:2*M_PI clockwise:YES] fill];
    }
}

@end

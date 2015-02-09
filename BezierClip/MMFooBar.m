//
//  MMFooBar.m
//  BezierClip
//
//  Created by Adam Wulf on 2/9/15.
//
//

#import "MMFooBar.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIBezierPath+Intersections.h"
#import "UIBezierPath+Clipping.h"
#import "BezierClip.h"

@implementation MMFooBar

-(id) init{
    if(self = [super init]){
        UIBezierPath* path = [UIBezierPath bezierPath];
        UIBezierPath* path2 = [UIBezierPath bezierPath];

        CGPathElement foo;
        [path addPathElement:foo];
        [UIBezierPath endPointForPathElement:foo];
        [UIBezierPath getBestMatchSegmentForSegments:nil forRed:nil andBlue:nil lastWasRed:NO comp:NO];
        [UIBezierPath calculateIntersectionAndDifferenceBetween:path
                                                        andPath:path2];
        [UIBezierPath firstIntersectionBetween:path
                                       andPath:path2];
    }
    return self;
}

@end

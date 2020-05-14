//
//  DKUIBezierPathClippingResult.m
//  LooseLeaf
//
//  Created by Adam Wulf on 10/7/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import "DKUIBezierPathClippingResult.h"

@implementation DKUIBezierPathClippingResult {
    UIBezierPath *entireIntersectionPath;
    UIBezierPath *entireDifferencePath;

    NSArray *intersectionSegments;
    NSArray *differenceSegments;

    NSUInteger numberOfShellIntersectionSegments;
    NSUInteger numberOfShellDifferenceSegments;
}

@synthesize entireIntersectionPath;
@synthesize entireDifferencePath;
@synthesize differenceSegments;
@synthesize intersectionSegments;
@synthesize numberOfShellIntersectionSegments;
@synthesize numberOfShellDifferenceSegments;

- (id)initWithIntersection:(UIBezierPath *)_intersection
               andSegments:(NSArray *)_intersectionSegments
             andDifference:(UIBezierPath *)_difference
               andSegments:(NSArray *)_differenceSegments
       andShellIntSegments:(NSUInteger)_numberOfShellIntersectionSegments
      andShellDiffSegments:(NSUInteger)_numberOfShellDifferenceSegments
{
    if (self = [super init]) {
        entireIntersectionPath = _intersection;
        entireDifferencePath = _difference;
        intersectionSegments = _intersectionSegments;
        differenceSegments = _differenceSegments;
        numberOfShellIntersectionSegments = _numberOfShellIntersectionSegments;
        numberOfShellDifferenceSegments = _numberOfShellDifferenceSegments;
    }
    return self;
}

@end

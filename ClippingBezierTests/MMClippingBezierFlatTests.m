//
//  MMClippingBezierFlatTests.m
//  ClippingBezier Tests
//
//  Created by Adam Wulf on 8/7/13.
//  Copyright (c) 2013 Milestone Made LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ClippingBezier/ClippingBezier.h>
#import <PerformanceBezier/PerformanceBezier.h>
#import "MMClippingBezierAbstractTest.h"

@interface MMClippingBezierFlatTests : MMClippingBezierAbstractTest

@end

@implementation MMClippingBezierFlatTests

- (void)testReverseSimplePath
{
    UIBezierPath *testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(1, 1)];
    [testPath addCurveToPoint:CGPointMake(2, 2) controlPoint1:CGPointMake(3, 3) controlPoint2:CGPointMake(4, 4)];

    UIBezierPath *ios7Reversed = [testPath bezierPathByReversingPath];
    UIBezierPath *ios5Reversed = [testPath nsosx_backwardcompatible_bezierPathByReversingPath];

    XCTAssertTrue(CGPathEqualToPath(ios5Reversed.CGPath, ios7Reversed.CGPath), @"paths are the same");
}

- (void)testReversePathWithClose
{
    UIBezierPath *testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(1, 1)];
    [testPath addLineToPoint:CGPointMake(2, 2)];
    [testPath addLineToPoint:CGPointMake(1, 2)];
    //    [testPath closePath];

    UIBezierPath *ios7Reversed = [testPath bezierPathByReversingPath];
    UIBezierPath *ios5Reversed = [testPath nsosx_backwardcompatible_bezierPathByReversingPath];

    XCTAssertEqual([testPath elementCount], [ios7Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed elementCount], [ios5Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed countSubPaths], [ios5Reversed countSubPaths], @"subpath counts are the same");

    NSString *ios7Description = [ios7Reversed description];
    NSString *ios5Description = [ios5Reversed description];

    BOOL isEqual = CGPathEqualToPath(ios5Reversed.CGPath, ios7Reversed.CGPath);

    if (!isEqual) {
        NSLog(@"ios7: %@", ios7Description);
        NSLog(@"ios5: %@", ios5Description);
    }

    XCTAssertTrue(isEqual, @"paths are the same");
}

- (void)testReversePathWithMultipleMoveTo
{
    UIBezierPath *testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(1, 1)];
    [testPath addCurveToPoint:CGPointMake(2, 2) controlPoint1:CGPointMake(3, 3) controlPoint2:CGPointMake(4, 4)];
    [testPath moveToPoint:CGPointMake(5, 5)];
    [testPath addCurveToPoint:CGPointMake(6, 6) controlPoint1:CGPointMake(7, 7) controlPoint2:CGPointMake(8, 8)];

    UIBezierPath *ios7Reversed = [testPath bezierPathByReversingPath];
    UIBezierPath *ios5Reversed = [testPath nsosx_backwardcompatible_bezierPathByReversingPath];

    XCTAssertEqual([testPath elementCount], [ios7Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed elementCount], [ios5Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed countSubPaths], [ios5Reversed countSubPaths], @"subpath counts are the same");

    NSString *ios7Description = [ios7Reversed description];
    NSString *ios5Description = [ios5Reversed description];

    BOOL isEqual = CGPathEqualToPath(ios5Reversed.CGPath, ios7Reversed.CGPath);

    if (!isEqual) {
        NSLog(@"=================");
        NSLog(@"ios7: %@", ios7Description);
        NSLog(@"ios5: %@", ios5Description);
    }

    XCTAssertTrue(isEqual, @"paths are the same");
}

- (void)testReversePathWithMixedElementTypes
{
    UIBezierPath *testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(1, 1)];
    [testPath addCurveToPoint:CGPointMake(2, 2) controlPoint1:CGPointMake(3, 3) controlPoint2:CGPointMake(4, 4)];
    [testPath addQuadCurveToPoint:CGPointMake(5, 5) controlPoint:CGPointMake(6, 6)];
    [testPath addLineToPoint:CGPointMake(7, 7)];

    UIBezierPath *ios7Reversed = [testPath bezierPathByReversingPath];
    UIBezierPath *ios5Reversed = [testPath nsosx_backwardcompatible_bezierPathByReversingPath];

    XCTAssertEqual([testPath elementCount], [ios7Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed elementCount], [ios5Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed countSubPaths], [ios5Reversed countSubPaths], @"subpath counts are the same");

    NSString *ios7Description = [ios7Reversed description];
    NSString *ios5Description = [ios5Reversed description];

    BOOL isEqual = CGPathEqualToPath(ios5Reversed.CGPath, ios7Reversed.CGPath);

    if (!isEqual) {
        NSLog(@"=================");
        NSLog(@"ios7: %@", ios7Description);
        NSLog(@"ios5: %@", ios5Description);
    }

    XCTAssertTrue(isEqual, @"paths are the same");
}


- (void)testCopyPathWithFreedElementCache
{
    NSInteger count1;
    UIBezierPath *copiedPath;
    @autoreleasepool {
        UIBezierPath *testPath = [UIBezierPath bezierPath];
        [testPath moveToPoint:CGPointMake(1, 1)];
        [testPath addCurveToPoint:CGPointMake(2, 2) controlPoint1:CGPointMake(3, 3) controlPoint2:CGPointMake(4, 4)];
        [testPath addQuadCurveToPoint:CGPointMake(5, 5) controlPoint:CGPointMake(6, 6)];
        [testPath addLineToPoint:CGPointMake(7, 7)];

        count1 = [testPath elementCount];
        for (int i = 0; i < [testPath elementCount]; i++) {
            [testPath elementAtIndex:i];
            // prime the element cache
        }

        copiedPath = [testPath copy];

        [testPath applyTransform:CGAffineTransformIdentity];
    }

    [copiedPath elementAtIndex:0];

    XCTAssertEqual([copiedPath elementCount], count1, @"counts are the same");
}


- (void)testCurveIntersectionThroughRect
{
    //
    // testPath is a curved line that starts
    // out above bounds, and curves through the
    // bounds box until it ends outside on the
    // other side

    UIBezierPath *testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(100, 50)];
    [testPath addCurveToPoint:CGPointMake(100, 250)
                controlPoint1:CGPointMake(170, 80)
                controlPoint2:CGPointMake(170, 220)];


    // simple 100x100 box
    UIBezierPath *bounds = [UIBezierPath bezierPath];
    [bounds moveToPoint:CGPointMake(100, 100)];
    [bounds addLineToPoint:CGPointMake(200, 100)];
    [bounds addLineToPoint:CGPointMake(200, 200)];
    [bounds addLineToPoint:CGPointMake(100, 200)];
    [bounds addLineToPoint:CGPointMake(100, 100)];
    [bounds closePath];


    DKIntersectionOfPaths *firstIntersection = [UIBezierPath firstIntersectionBetween:[testPath bezierPathByFlatteningPath] andPath:bounds];


    XCTAssertEqual(firstIntersection.doesIntersect, YES, @"the curves do intersect");
    XCTAssertEqual(firstIntersection.elementNumberOfIntersection, 337, @"the curves do intersect");
    XCTAssertEqual(floorf(100 * firstIntersection.tValueOfIntersection), 57.0, @"the curves do intersect");


    XCTAssertEqual(firstIntersection.start.firstPoint.x, 100.0, @"starts at the right place");
    XCTAssertEqual(firstIntersection.start.firstPoint.y, 50.0, @"starts at the right place");
    XCTAssertEqual(floorf(firstIntersection.start.lastPoint.x), 143.0, @"ends at the right place");
    XCTAssertEqual(firstIntersection.start.lastPoint.y, 100.0, @"ends at the right place");

    XCTAssertEqual(floorf(firstIntersection.end.firstPoint.x), 143.0, @"starts at the right place");
    XCTAssertEqual(firstIntersection.end.firstPoint.y, 100.0, @"starts at the right place");
    XCTAssertEqual(firstIntersection.end.lastPoint.x, 100.0, @"starts at the right place");
    XCTAssertEqual(firstIntersection.end.lastPoint.y, 250.0, @"starts at the right place");
}

- (void)testCurveIntersectionInsideRect
{
    // testPath is a curved line entirely contained
    // inside of bounds

    UIBezierPath *testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(150, 150)];
    [testPath addCurveToPoint:CGPointMake(170, 180)
                controlPoint1:CGPointMake(160, 150)
                controlPoint2:CGPointMake(160, 180)];


    // simple 100x100 box
    UIBezierPath *bounds = [UIBezierPath bezierPath];
    [bounds moveToPoint:CGPointMake(100, 100)];
    [bounds addLineToPoint:CGPointMake(200, 100)];
    [bounds addLineToPoint:CGPointMake(200, 200)];
    [bounds addLineToPoint:CGPointMake(100, 200)];
    [bounds addLineToPoint:CGPointMake(100, 100)];
    [bounds closePath];

    DKIntersectionOfPaths *firstIntersection = [UIBezierPath firstIntersectionBetween:[testPath bezierPathByFlatteningPath] andPath:bounds];


    XCTAssertEqual(firstIntersection.doesIntersect, NO, @"the curves do intersect");
    XCTAssertEqual(firstIntersection.elementNumberOfIntersection, -1, @"the curves do intersect");
    XCTAssertEqual(floorf(100 * firstIntersection.tValueOfIntersection), 0.0, @"the curves do intersect");


    XCTAssertEqual(firstIntersection.start.firstPoint.x, 150.0, @"starts at the right place");
    XCTAssertEqual(firstIntersection.start.firstPoint.y, 150.0, @"starts at the right place");
    XCTAssertEqual(floorf(firstIntersection.start.lastPoint.x), 170.0, @"ends at the right place");
    XCTAssertEqual(firstIntersection.start.lastPoint.y, 180.0, @"ends at the right place");

    XCTAssertEqual([firstIntersection.end elementCount], 0, @"end path is empty");
}


- (void)testCurveIntersectionOutsideRect
{
    // testPath is a curved line entirely contained
    // inside of bounds

    UIBezierPath *testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(250, 250)];
    [testPath addCurveToPoint:CGPointMake(270, 280)
                controlPoint1:CGPointMake(260, 250)
                controlPoint2:CGPointMake(260, 280)];


    // simple 100x100 box
    UIBezierPath *bounds = [UIBezierPath bezierPath];
    [bounds moveToPoint:CGPointMake(100, 100)];
    [bounds addLineToPoint:CGPointMake(200, 100)];
    [bounds addLineToPoint:CGPointMake(200, 200)];
    [bounds addLineToPoint:CGPointMake(100, 200)];
    [bounds addLineToPoint:CGPointMake(100, 100)];
    [bounds closePath];

    DKIntersectionOfPaths *firstIntersection = [UIBezierPath firstIntersectionBetween:[testPath bezierPathByFlatteningPath] andPath:bounds];


    XCTAssertEqual(firstIntersection.doesIntersect, NO, @"the curves do intersect");
    XCTAssertEqual(firstIntersection.elementNumberOfIntersection, -1, @"the curves do intersect");
    XCTAssertEqual(floorf(100 * firstIntersection.tValueOfIntersection), 0.0, @"the curves do intersect");


    XCTAssertEqual(firstIntersection.start.firstPoint.x, 250.0, @"starts at the right place");
    XCTAssertEqual(firstIntersection.start.firstPoint.y, 250.0, @"starts at the right place");
    XCTAssertEqual(floorf(firstIntersection.start.lastPoint.x), 270.0, @"ends at the right place");
    XCTAssertEqual(firstIntersection.start.lastPoint.y, 280.0, @"ends at the right place");

    XCTAssertEqual([firstIntersection.end elementCount], 0, @"end path is empty");
}

@end

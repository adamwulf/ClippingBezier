//
//  MMClippingBezierSelfIntersectionTests.m
//  ClippingBezierTests
//
//  Created by Adam Wulf on 11/17/20.
//

#import <XCTest/XCTest.h>
#import "MMClippingBezierAbstractTest.h"
#import <ClippingBezier/ClippingBezier.h>
#import <PerformanceBezier/PerformanceBezier.h>
#import <ClippingBezier/UIBezierPath+Clipping_Private.h>

@interface MMClippingBezierSelfIntersectionTests : MMClippingBezierAbstractTest

@end

@implementation MMClippingBezierSelfIntersectionTests

- (void)testSelfIntersections1
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(50, 50)];
    [path addLineToPoint:CGPointMake(50, -100)];

    NSArray<DKUIBezierPathIntersectionPoint *> *intersections = [path selfIntersections];

    XCTAssertEqual([intersections count], 1);

    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex1], 1);
    XCTAssertEqualWithAccuracy([[intersections objectAtIndex:0] tValue1], 0.5, 0.000001);
    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex2], 3);
    XCTAssertEqualWithAccuracy([[intersections objectAtIndex:0] tValue2], 0.333333, 0.000001);
}

- (void)testSelfIntersections2
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 100, 100)];

    NSArray<DKUIBezierPathIntersectionPoint *> *intersections = [path selfIntersections];

    XCTAssertEqual([intersections count], 0);
}

- (void)testSelfIntersections3
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(-100, 50)];
    [path addLineToPoint:CGPointMake(100, 100)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path closePath];

    NSArray<DKUIBezierPathIntersectionPoint *> *intersections = [path selfIntersections];

    XCTAssertEqual([intersections count], 2);

    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex1], 2);
    XCTAssertEqualWithAccuracy([[intersections objectAtIndex:0] tValue1], 0.5, 0.000001);
    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex2], 5);
    XCTAssertEqualWithAccuracy([[intersections objectAtIndex:0] tValue2], 0.75, 0.000001);

    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex1], 3);
    XCTAssertEqualWithAccuracy([[intersections objectAtIndex:0] tValue1], 0.5, 0.000001);
    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex2], 5);
    XCTAssertEqualWithAccuracy([[intersections objectAtIndex:1] tValue2], 0.25, 0.000001);
}

- (void)testSplitPath3
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(-100, 50)];
    [path addLineToPoint:CGPointMake(100, 100)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path closePath];

    NSArray<UIBezierPath *> *splitPaths = [path pathsFromSelfIntersections];

    XCTAssertEqual([splitPaths count], 5);


    UIBezierPath *seg1 = [UIBezierPath bezierPath];
    [seg1 moveToPoint:CGPointMake(0, 0)];
    [seg1 addLineToPoint:CGPointMake(100, 0)];
    [seg1 addLineToPoint:CGPointMake(0, 25)];

    UIBezierPath *seg2 = [UIBezierPath bezierPath];
    [seg2 moveToPoint:CGPointMake(0, 25)];
    [seg2 addLineToPoint:CGPointMake(-100, 50)];
    [seg2 addLineToPoint:CGPointMake(0, 75)];

    UIBezierPath *seg3 = [UIBezierPath bezierPath];
    [seg3 moveToPoint:CGPointMake(0, 75)];
    [seg3 addLineToPoint:CGPointMake(100, 100)];
    [seg3 addLineToPoint:CGPointMake(0, 100)];
    [seg3 addLineToPoint:CGPointMake(0, 75)];

    UIBezierPath *seg4 = [UIBezierPath bezierPath];
    [seg4 moveToPoint:CGPointMake(0, 75)];
    [seg4 addLineToPoint:CGPointMake(0, 25)];

    UIBezierPath *seg5 = [UIBezierPath bezierPath];
    [seg5 moveToPoint:CGPointMake(0, 25)];
    [seg5 addLineToPoint:CGPointMake(0, 0)];

    XCTAssert([[splitPaths objectAtIndex:0] isEqualToBezierPath:seg1 withAccuracy:0.00001]);
    XCTAssert([[splitPaths objectAtIndex:1] isEqualToBezierPath:seg2 withAccuracy:0.00001]);
    XCTAssert([[splitPaths objectAtIndex:2] isEqualToBezierPath:seg3 withAccuracy:0.00001]);
    XCTAssert([[splitPaths objectAtIndex:3] isEqualToBezierPath:seg4 withAccuracy:0.00001]);
    XCTAssert([[splitPaths objectAtIndex:4] isEqualToBezierPath:seg5 withAccuracy:0.00001]);
}

- (void)testSplitPath4
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(-100, 50)];
    [path addLineToPoint:CGPointMake(100, 100)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(0, 0)];
    [path closePath];

    NSArray<UIBezierPath *> *splitPaths = [path pathsFromSelfIntersections];

    XCTAssertEqual([splitPaths count], 5);


    UIBezierPath *seg1 = [UIBezierPath bezierPath];
    [seg1 moveToPoint:CGPointMake(0, 0)];
    [seg1 addLineToPoint:CGPointMake(100, 0)];
    [seg1 addLineToPoint:CGPointMake(0, 25)];

    UIBezierPath *seg2 = [UIBezierPath bezierPath];
    [seg2 moveToPoint:CGPointMake(0, 25)];
    [seg2 addLineToPoint:CGPointMake(-100, 50)];
    [seg2 addLineToPoint:CGPointMake(0, 75)];

    UIBezierPath *seg3 = [UIBezierPath bezierPath];
    [seg3 moveToPoint:CGPointMake(0, 75)];
    [seg3 addLineToPoint:CGPointMake(100, 100)];
    [seg3 addLineToPoint:CGPointMake(0, 100)];
    [seg3 addLineToPoint:CGPointMake(0, 75)];

    UIBezierPath *seg4 = [UIBezierPath bezierPath];
    [seg4 moveToPoint:CGPointMake(0, 75)];
    [seg4 addLineToPoint:CGPointMake(0, 25)];

    UIBezierPath *seg5 = [UIBezierPath bezierPath];
    [seg5 moveToPoint:CGPointMake(0, 25)];
    [seg5 addLineToPoint:CGPointMake(0, 0)];

    XCTAssert([[splitPaths objectAtIndex:0] isEqualToBezierPath:seg1 withAccuracy:0.00001]);
    XCTAssert([[splitPaths objectAtIndex:1] isEqualToBezierPath:seg2 withAccuracy:0.00001]);
    XCTAssert([[splitPaths objectAtIndex:2] isEqualToBezierPath:seg3 withAccuracy:0.00001]);
    XCTAssert([[splitPaths objectAtIndex:3] isEqualToBezierPath:seg4 withAccuracy:0.00001]);
    XCTAssert([[splitPaths objectAtIndex:4] isEqualToBezierPath:seg5 withAccuracy:0.00001]);
}

@end

//
//  MMClippingBezierGeometryTest.m
//  ClippingBezier
//
//  Created by Adam Wulf on 6/14/15.
//
//

#import <UIKit/UIKit.h>
#import "MMClippingBezierAbstractTest.h"

@interface MMClippingBezierGeometryTest : MMClippingBezierAbstractTest

@end

@implementation MMClippingBezierGeometryTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testComplexShape
{
    // This is an example of a functional test case.

    CGPoint p = [[UIBezierPath complexShape1] closestPointOnPathTo:CGPointZero];

    XCTAssertEqual([self round:p.x to:6], 183.165312, @"point is correct");
    XCTAssertEqual([self round:p.y to:6], 146.622688, @"point is correct");

    XCTAssert(YES, @"Pass");
}

- (void)testClosestPointOnSimpleCurve
{
    UIBezierPath *bez = [UIBezierPath bezierPathWithArcCenter:CGPointMake(500, 500) radius:300 startAngle:-M_PI / 24 endAngle:-M_PI * 12 / 45 clockwise:YES];

    CGPoint p = [bez closestPointOnPathTo:CGPointZero];

    XCTAssertEqual([self round:p.x to:6], 287.945664, @"point is correct");
    XCTAssertEqual([self round:p.y to:6], 287.768800, @"point is correct");
}

- (void)testSubpathRangeForIndexClosePath
{
    NSRange key = NSMakeRange(0, 4);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path closePath];

    NSRange rng = [path subpathRangeForElement:0];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);

    rng = [path subpathRangeForElement:1];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);

    rng = [path subpathRangeForElement:2];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);

    rng = [path subpathRangeForElement:3];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);
}

- (void)testSubpathRangeForIndexOpenPath
{
    NSRange key = NSMakeRange(0, 3);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(100, 0)];

    NSRange rng = [path subpathRangeForElement:0];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);

    rng = [path subpathRangeForElement:1];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);

    rng = [path subpathRangeForElement:2];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);
}

- (void)testSubpathRangeForIndexMultiplePaths
{
    NSRange key1 = NSMakeRange(0, 3);
    NSRange key2 = NSMakeRange(3, 3);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(100, 0)];

    NSRange rng = [path subpathRangeForElement:0];

    XCTAssertEqual(rng.location, key1.location);
    XCTAssertEqual(rng.length, key1.length);

    rng = [path subpathRangeForElement:1];

    XCTAssertEqual(rng.location, key1.location);
    XCTAssertEqual(rng.length, key1.length);

    rng = [path subpathRangeForElement:2];

    XCTAssertEqual(rng.location, key1.location);
    XCTAssertEqual(rng.length, key1.length);

    rng = [path subpathRangeForElement:3];

    XCTAssertEqual(rng.location, key2.location);
    XCTAssertEqual(rng.length, key2.length);

    rng = [path subpathRangeForElement:4];

    XCTAssertEqual(rng.location, key2.location);
    XCTAssertEqual(rng.length, key2.length);

    rng = [path subpathRangeForElement:5];

    XCTAssertEqual(rng.location, key2.location);
    XCTAssertEqual(rng.length, key2.length);
}

- (void)testSubpathRangeForIndexAdjacentMoveTo
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path moveToPoint:CGPointMake(0, 0)];
    [path moveToPoint:CGPointMake(0, 0)];

    NSRange rng = [path subpathRangeForElement:0];

    XCTAssertEqual(rng.location, 0);
    XCTAssertEqual(rng.length, 1);

    rng = [path subpathRangeForElement:1];

    XCTAssertEqual(rng.location, 1);
    XCTAssertEqual(rng.length, 1);

    rng = [path subpathRangeForElement:2];

    XCTAssertEqual(rng.location, 2);
    XCTAssertEqual(rng.length, 1);
}

- (void)testSubpathRangeForIndexTinyPaths
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path closePath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path closePath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path closePath];

    NSRange rng = [path subpathRangeForElement:0];

    XCTAssertEqual(rng.location, 0);
    XCTAssertEqual(rng.length, 2);

    rng = [path subpathRangeForElement:1];

    XCTAssertEqual(rng.location, 0);
    XCTAssertEqual(rng.length, 2);

    rng = [path subpathRangeForElement:2];

    XCTAssertEqual(rng.location, 2);
    XCTAssertEqual(rng.length, 2);

    rng = [path subpathRangeForElement:3];

    XCTAssertEqual(rng.location, 2);
    XCTAssertEqual(rng.length, 2);

    rng = [path subpathRangeForElement:4];

    XCTAssertEqual(rng.location, 4);
    XCTAssertEqual(rng.length, 2);

    rng = [path subpathRangeForElement:5];

    XCTAssertEqual(rng.location, 4);
    XCTAssertEqual(rng.length, 2);
}

- (void)testTValueDistanceSingleElement
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];

    CGFloat dist = [path effectiveTDistanceFromElement:0 andTValue:0 toElement:0 andTValue:1];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:0 andTValue:0 toElement:0 andTValue:0];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:0 andTValue:1 toElement:0 andTValue:0];
    XCTAssertEqual(dist, 0);
}

- (void)testTValueDistanceTwoElements
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path closePath];

    CGFloat dist = [path effectiveTDistanceFromElement:0 andTValue:0 toElement:0 andTValue:1];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:0 andTValue:0 toElement:1 andTValue:0];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:1 andTValue:0 toElement:0 andTValue:0];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:0 andTValue:1 toElement:0 andTValue:0];
    XCTAssertEqual(dist, 0);
}

- (void)testTValueDistanceThroughLines
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(0, 0)];
    [path closePath];

    CGFloat dist = [path effectiveTDistanceFromElement:0 andTValue:0 toElement:1 andTValue:1];
    XCTAssertEqual(dist, 1);

    dist = [path effectiveTDistanceFromElement:1 andTValue:0.25 toElement:2 andTValue:0.5];
    XCTAssertEqual(dist, 1.25);

    // quicker to go backwards than forwards through 2.25 distance
    dist = [path effectiveTDistanceFromElement:1 andTValue:0.25 toElement:3 andTValue:0.5];
    XCTAssertEqual(dist, -0.75);
}

- (void)testTValueDistanceBackwardThroughLines
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(0, 0)];
    [path closePath];

    CGFloat dist = [path effectiveTDistanceFromElement:1 andTValue:1 toElement:0 andTValue:0];
    XCTAssertEqual(dist, -1);

    dist = [path effectiveTDistanceFromElement:2 andTValue:0.5 toElement:1 andTValue:0.25];
    XCTAssertEqual(dist, -1.25);

    dist = [path effectiveTDistanceFromElement:3 andTValue:0.5 toElement:1 andTValue:0.25];
    XCTAssertEqual(dist, 0.75);

    dist = [path effectiveTDistanceFromElement:1 andTValue:0 toElement:3 andTValue:1];
    XCTAssertEqual(dist, 0.0);

    dist = [path effectiveTDistanceFromElement:3 andTValue:1 toElement:1 andTValue:0];
    XCTAssertEqual(dist, 0.0);
}

- (void)testTValueDistanceClose1
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path closePath];

    CGFloat dist = [path effectiveTDistanceFromElement:0 andTValue:0 toElement:3 andTValue:1];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:3 andTValue:1 toElement:0 andTValue:0];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:3 andTValue:0 toElement:0 andTValue:0];
    XCTAssertEqual(dist, 1);

    dist = [path effectiveTDistanceFromElement:3 andTValue:1 toElement:0 andTValue:.5];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:1 andTValue:0 toElement:2 andTValue:1];
    XCTAssertEqual(dist, -1.0);

    dist = [path effectiveTDistanceFromElement:2 andTValue:1 toElement:1 andTValue:0];
    XCTAssertEqual(dist, 1.0);

    dist = [path effectiveTDistanceFromElement:3 andTValue:0.1 toElement:0 andTValue:.5];
    XCTAssertEqualWithAccuracy(dist, 0.9, 0.000001);

    dist = [path effectiveTDistanceFromElement:0 andTValue:0.5 toElement:3 andTValue:0.1];
    XCTAssertEqualWithAccuracy(dist, -0.9, 0.000001);
}

- (void)testTValueDistanceClose2
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(0, 0)];
    [path closePath];

    CGFloat dist = [path effectiveTDistanceFromElement:0 andTValue:0 toElement:3 andTValue:1];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:3 andTValue:1 toElement:0 andTValue:0];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:3 andTValue:0 toElement:0 andTValue:0];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:3 andTValue:1 toElement:0 andTValue:.5];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:2 andTValue:0 toElement:0 andTValue:0];
    XCTAssertEqual(dist, -1);

    dist = [path effectiveTDistanceFromElement:2 andTValue:1 toElement:0 andTValue:.5];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:1 andTValue:0.5 toElement:2 andTValue:.5];
    XCTAssertEqual(dist, 1);

    dist = [path effectiveTDistanceFromElement:3 andTValue:0.1 toElement:0 andTValue:.5];
    XCTAssertEqual(dist, 0);

    dist = [path effectiveTDistanceFromElement:0 andTValue:0.5 toElement:3 andTValue:0.1];
    XCTAssertEqual(dist, 0);
}

- (void)testTValueDistanceClose3
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(0, 0)];
    [path closePath];

    CGFloat dist = [path effectiveTDistanceFromElement:1 andTValue:0.005 toElement:2 andTValue:0.995];
    XCTAssertEqualWithAccuracy(dist, -0.01, 0.000001);

    dist = [path effectiveTDistanceFromElement:2 andTValue:0.995 toElement:1 andTValue:0.005];
    XCTAssertEqualWithAccuracy(dist, 0.01, 0.000001);

    dist = [path effectiveTDistanceFromElement:1 andTValue:0.995 toElement:2 andTValue:0.005];
    XCTAssertEqualWithAccuracy(dist, 0.01, 0.000001);

    dist = [path effectiveTDistanceFromElement:2 andTValue:0.005 toElement:1 andTValue:0.995];
    XCTAssertEqualWithAccuracy(dist, -0.01, 0.000001);
}

- (void)testTValueIgnoreLineSegment
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)]; // 0: ignore this element
    [path addLineToPoint:CGPointMake(0, 100)]; // 1: [0, 100]
    [path addLineToPoint:CGPointMake(0, 200)]; // 2: [100, 200]
    [path addLineToPoint:CGPointMake(0, 300)]; // 3: [200, 300]
    [path addLineToPoint:CGPointMake(0, 300)]; // 4: ignore this element
    [path addLineToPoint:CGPointMake(0, 400)]; // 5: [300, 400]
    [path addLineToPoint:CGPointMake(0, 0)]; // 6: [400, 0]
    [path closePath];

    CGFloat dist = [path effectiveTDistanceFromElement:1 andTValue:0.005 toElement:2 andTValue:0.995];
    XCTAssertEqualWithAccuracy(dist, 1.99, 0.000001);

    dist = [path effectiveTDistanceFromElement:2 andTValue:0 toElement:3 andTValue:0];
    XCTAssertEqualWithAccuracy(dist, 1, 0.000001);

    dist = [path effectiveTDistanceFromElement:2 andTValue:0 toElement:3 andTValue:1];
    XCTAssertEqualWithAccuracy(dist, 2, 0.000001);

    dist = [path effectiveTDistanceFromElement:2 andTValue:0 toElement:4 andTValue:0];
    XCTAssertEqualWithAccuracy(dist, 2, 0.000001);

    // skip the element since it doesn't move the point
    dist = [path effectiveTDistanceFromElement:2 andTValue:0 toElement:4 andTValue:1];
    XCTAssertEqualWithAccuracy(dist, 2, 0.000001);
}

- (void)testTValueIgnoreLineSegment2
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)]; // 0: ignore this element
    [path addLineToPoint:CGPointMake(0, 100)]; // 1: [0, 100]
    [path addLineToPoint:CGPointMake(0, 200)]; // 2: [100, 200]
    [path addLineToPoint:CGPointMake(0, 300)]; // 3: [200, 300]
    [path addLineToPoint:CGPointMake(0, 300)]; // 4: ignore this element
    [path addLineToPoint:CGPointMake(0, 300)]; // 5: ignore this element
    [path addLineToPoint:CGPointMake(0, 300)]; // 6: ignore this element
    [path addLineToPoint:CGPointMake(0, 300)]; // 7: ignore this element
    [path addLineToPoint:CGPointMake(0, 400)]; // 8: [300, 400]
    [path addLineToPoint:CGPointMake(0, 0)]; // 9: [400, 0]
    [path closePath];

    CGFloat dist = [path effectiveTDistanceFromElement:4 andTValue:0.005 toElement:6 andTValue:0.995];
    XCTAssertEqualWithAccuracy(dist, 0.0, 0.000001);

    dist = [path effectiveTDistanceFromElement:3 andTValue:0.5 toElement:6 andTValue:0.95];
    XCTAssertEqualWithAccuracy(dist, 0.5, 0.000001);
}

- (void)testTValueLoopBackwardClose
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(400, 300)];
    [path addLineToPoint:CGPointMake(300, 400)];
    [path addLineToPoint:CGPointMake(200, 300)];
    [path addLineToPoint:CGPointMake(300, 200)];
    [path addLineToPoint:CGPointMake(400, 300)];
    [path closePath];

    CGFloat dist = [path effectiveTDistanceFromElement:1 andTValue:0 toElement:4 andTValue:1];
    XCTAssertEqual(dist, 0.0);

    dist = [path effectiveTDistanceFromElement:4 andTValue:1 toElement:1 andTValue:0];
    XCTAssertEqual(dist, 0.0);
}

- (void)testTValueClippingCase
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(400, 300)];
    [path addCurveToPoint:CGPointMake(300, 400) controlPoint1:CGPointMake(400, 355.22847498) controlPoint2:CGPointMake(355.22847498, 400)];
    [path addCurveToPoint:CGPointMake(200, 300) controlPoint1:CGPointMake(244.77152502, 400) controlPoint2:CGPointMake(200, 355.22847498)];
    [path addCurveToPoint:CGPointMake(300, 200) controlPoint1:CGPointMake(200, 244.77152502) controlPoint2:CGPointMake(244.77152502, 200)];
    [path addCurveToPoint:CGPointMake(400, 300) controlPoint1:CGPointMake(355.22847498, 200) controlPoint2:CGPointMake(400, 244.77152502)];
    [path closePath];

    CGFloat dist = [path effectiveTDistanceFromElement:4 andTValue:0.99999568124138771 toElement:1 andTValue:0.0000028883736617010538];
    XCTAssertEqualWithAccuracy(dist, 0.000007, 0.000001);
}


@end

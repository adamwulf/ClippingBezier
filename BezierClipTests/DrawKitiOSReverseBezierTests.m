//
//  DrawKitiOSReverseBezierTests.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 1/7/14.
//  Copyright (c) 2014 Adam Wulf. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ClippingBezier/ClippingBezier.h>
#import <DrawKit-iOS/DrawKit-iOS.h>
#import <PerformanceBezier/PerformanceBezier.h>


@interface DrawKitiOSReverseBezierTests : XCTestCase

@end

@implementation DrawKitiOSReverseBezierTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testReverseLine
{
    UIBezierPath* linePath = [UIBezierPath bezierPath];
    [linePath moveToPoint:CGPointMake(100, 100)];
    [linePath addLineToPoint:CGPointMake(200, 300)];
    
    UIBezierPath* reversed = [UIBezierPath bezierPath];
    [reversed moveToPoint:CGPointMake(200, 300)];
    [reversed addLineToPoint:CGPointMake(100, 100)];
    
    XCTAssertTrue(CGPathEqualToPath(reversed.CGPath, [linePath bezierPathByReversingPath].CGPath), @"revesed path is correct");
}

- (void)testReverseQuadCurve
{
    UIBezierPath* curvePath = [UIBezierPath bezierPath];
    [curvePath moveToPoint:CGPointMake(100, 100)];
    [curvePath addQuadCurveToPoint:CGPointMake(200, 100) controlPoint:CGPointMake(150, 0)];
    
    UIBezierPath* reversed = [UIBezierPath bezierPath];
    [reversed moveToPoint:CGPointMake(200, 100)];
    [reversed addQuadCurveToPoint:CGPointMake(100, 100) controlPoint:CGPointMake(150, 0)];
    
    XCTAssertTrue(CGPathEqualToPath(reversed.CGPath, [curvePath bezierPathByReversingPath].CGPath), @"revesed path is correct");
}

- (void)testReverseCubicCurve
{
    UIBezierPath* curvePath = [UIBezierPath bezierPath];
    [curvePath moveToPoint:CGPointMake(100, 100)];
    [curvePath addCurveToPoint:CGPointMake(200, 100) controlPoint1:CGPointMake(100, 0) controlPoint2:CGPointMake(200, 0)];
    
    UIBezierPath* reversed = [UIBezierPath bezierPath];
    [reversed moveToPoint:CGPointMake(200, 100)];
    [reversed addCurveToPoint:CGPointMake(100, 100) controlPoint1:CGPointMake(200, 0) controlPoint2:CGPointMake(100, 0)];
    
    XCTAssertTrue(CGPathEqualToPath(reversed.CGPath, [curvePath bezierPathByReversingPath].CGPath), @"revesed path is correct");
}

- (void)testReverseClosedPath
{
    UIBezierPath* linePath = [UIBezierPath bezierPath];
    [linePath moveToPoint:CGPointMake(100, 100)];
    [linePath addLineToPoint:CGPointMake(200, 300)];
    [linePath addLineToPoint:CGPointMake(200, 500)];
    [linePath closePath];
    
    UIBezierPath* reversed = [UIBezierPath bezierPath];
    [reversed moveToPoint:CGPointMake(200, 500)];
    [reversed addLineToPoint:CGPointMake(200, 300)];
    [reversed addLineToPoint:CGPointMake(100, 100)];
    [reversed closePath];
    
    XCTAssertTrue(CGPathEqualToPath(reversed.CGPath, [linePath bezierPathByReversingPath].CGPath), @"revesed path is correct");
}


- (void)testReverseIncludingSubpaths
{
    UIBezierPath* linePath = [UIBezierPath bezierPath];
    [linePath moveToPoint:CGPointMake(100, 100)];
    [linePath addLineToPoint:CGPointMake(200, 300)];
    [linePath addLineToPoint:CGPointMake(200, 500)];
    [linePath closePath];
    [linePath moveToPoint:CGPointMake(500, 100)];
    [linePath addLineToPoint:CGPointMake(600, 300)];
    [linePath addLineToPoint:CGPointMake(600, 500)];
    [linePath closePath];
    
    UIBezierPath* reversed = [UIBezierPath bezierPath];
    [reversed moveToPoint:CGPointMake(200, 500)];
    [reversed addLineToPoint:CGPointMake(200, 300)];
    [reversed addLineToPoint:CGPointMake(100, 100)];
    [reversed closePath];
    [reversed moveToPoint:CGPointMake(600, 500)];
    [reversed addLineToPoint:CGPointMake(600, 300)];
    [reversed addLineToPoint:CGPointMake(500, 100)];
    [reversed closePath];
    
    XCTAssertTrue(CGPathEqualToPath(reversed.CGPath, [linePath bezierPathByReversingPath].CGPath), @"revesed path is correct");
}

@end

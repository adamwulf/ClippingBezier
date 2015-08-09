//
//  MMClippingBezierTrimmingTests.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/20/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MMClippingBezierAbstractTest.h"
#import <PerformanceBezier/PerformanceBezier.h>

@interface MMClippingBezierTrimmingTests : MMClippingBezierAbstractTest

@end

@implementation MMClippingBezierTrimmingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAppendWithoutMoveTo {
    // This is an example of a functional test case.
    
    UIBezierPath* path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointZero];
    [path1 addLineToPoint:CGPointMake(10, 10)];
    
    UIBezierPath* path2 = [UIBezierPath bezierPath];
    [path2 moveToPoint:CGPointMake(20, 20)];
    [path2 addLineToPoint:CGPointMake(30, 30)];
    
    [path1 appendPathRemovingInitialMoveToPoint:path2];
    
    
    XCTAssertEqual([path1 elementCount], 3, "element count is correct");
    XCTAssertEqual([path1 lastPoint].x, (CGFloat) 30, "element count is correct");
    XCTAssertEqual([path1 lastPoint].y, (CGFloat) 30, "element count is correct");
}

- (void)testSubPaths {
    // This is an example of a functional test case.
    
    UIBezierPath* path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointZero];
    [path1 addLineToPoint:CGPointMake(10, 10)];
    [path1 moveToPoint:CGPointMake(20, 20)];
    [path1 addLineToPoint:CGPointMake(30, 30)];
    UIBezierPath* path2 = [UIBezierPath bezierPath];
    
    XCTAssertEqual([[path1 subPaths] count], 2, "element count is correct");
    XCTAssertEqual([path1 countSubPaths], 2, "element count is correct");
    XCTAssertEqual([path2 countSubPaths], 0, "element count is correct");
    
    UIBezierPath* sub1 = [[path1 subPaths] objectAtIndex:0];
    XCTAssertEqual([sub1 firstPoint].x, (CGFloat) 0, "element count is correct");
    XCTAssertEqual([sub1 firstPoint].y, (CGFloat) 0, "element count is correct");
    XCTAssertEqual([sub1 lastPoint].x, (CGFloat) 10, "element count is correct");
    XCTAssertEqual([sub1 lastPoint].y, (CGFloat) 10, "element count is correct");

    UIBezierPath* sub2 = [[path1 subPaths] objectAtIndex:1];
    XCTAssertEqual([sub2 firstPoint].x, (CGFloat) 20, "element count is correct");
    XCTAssertEqual([sub2 firstPoint].y, (CGFloat) 20, "element count is correct");
    XCTAssertEqual([sub2 lastPoint].x, (CGFloat) 30, "element count is correct");
    XCTAssertEqual([sub2 lastPoint].y, (CGFloat) 30, "element count is correct");
}

- (void)testStartTangent {
    // This is an example of a functional test case.
    
    UIBezierPath* path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointZero];
    [path1 addLineToPoint:CGPointMake(10, 10)];
    
    CGFloat tangent = [path1 tangentAtStart];
    XCTAssertEqual((CGFloat)tangent, (CGFloat) 3.92699075, "tangent is correct");
}

- (void)testStartTangentOfSubpath {
    // This is an example of a functional test case.
    
    UIBezierPath* path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointMake(20, 20)];
    [path1 addLineToPoint:CGPointMake(30, 20)];
    [path1 moveToPoint:CGPointZero];
    [path1 addLineToPoint:CGPointMake(10, 10)];
    
    CGFloat tangent = [path1 tangentAtStartOfSubpath:1];
    XCTAssertEqual((CGFloat)tangent, (CGFloat) 3.92699075, "tangent is correct");
}

- (void)testStartTangentOfSubpath2 {
    // This is an example of a functional test case.
    
    UIBezierPath* path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointMake(20, 20)];
    [path1 addLineToPoint:CGPointMake(30, 20)];
    [path1 moveToPoint:CGPointZero];
    [path1 addLineToPoint:CGPointMake(10, 10)];
    
    CGFloat tangent = [path1 tangentAtStartOfSubpath:0];
    XCTAssertEqual((CGFloat)tangent, (CGFloat) 3.14159274, "tangent is correct");
}

- (void)testTrimmingFromLength {
    XCTAssertTrue(NO, @"test needs writing");
    return;
}

- (void)testTrimmingToLength {
    XCTAssertTrue(NO, @"test needs writing");
    return;
}

- (void)testTrimmingToLengthWithMaximumError {
    XCTAssertTrue(NO, @"test needs writing");
    return;
}

- (void)testLinePathLength {
    UIBezierPath* unitPath = [UIBezierPath bezierPath];
    [unitPath moveToPoint:CGPointMake(0, 0)];
    [unitPath addLineToPoint:CGPointMake(0, 1)];
    
    XCTAssertEqual([unitPath length], (CGFloat) 1.0, "path length is correct");
}

- (void)testLongerLinePathLength {
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(3, 4)];
    
    XCTAssertEqual([path length], (CGFloat) 5.0, "path length is correct");
}

- (void)testShortLinePathLength {
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(1, 1)];
    
    XCTAssertEqual([self round:[path length] to:6], (CGFloat) 1.414214, "path length is correct");
}

- (void)testRectangleLength {
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 4, 3)];
    
    XCTAssertEqual([path length], (CGFloat) 14.0, "path length is correct");
}

- (void)testZeroLength {
    UIBezierPath* zeroPath = [UIBezierPath bezierPath];
    [zeroPath moveToPoint:CGPointMake(1, 1)];
    [zeroPath closePath];
    
    XCTAssertEqual([zeroPath length], (CGFloat) 0.0, "path length is correct");
}

- (void)testCircleCircumference{
    CGFloat r = 5;
    UIBezierPath* path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 2*r, 2*r)];
    
    XCTAssertTrue([self check:[path length] isEqualTo:[self round:M_PI * 2 * r to:6] within:.5]);
}

- (void)testStraightCurve{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addCurveToPoint:CGPointMake(100, 0) controlPoint1:CGPointMake(10, 0) controlPoint2:CGPointMake(20, 0)];
    
    
    XCTAssertEqual([path length], (CGFloat) 100.0, "path length is correct");
}

@end

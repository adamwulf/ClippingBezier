//
//  DKFixTests.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/20/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MMClippingBezierAbstractTest.h"
#import <PerformanceBezier/PerformanceBezier.h>

@interface DKFixTests : MMClippingBezierAbstractTest

@end

@implementation DKFixTests

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
@end

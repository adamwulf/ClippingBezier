//
//  DKFixTests.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/20/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "DrawKitiOSAbstractTest.h"
#import <PerformanceBezier/PerformanceBezier.h>

@interface DKFixTests : DrawKitiOSAbstractTest

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

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

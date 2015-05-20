//
//  DrawKit_Tests.m
//  DrawKit Tests
//
//  Created by Adam Wulf on 5/20/15.
//  Copyright (c) 2015 Adam Wulf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <DrawKit-iOS/DrawKit-iOS.h>

@interface DrawKit_Tests : XCTestCase

@end

@implementation DrawKit_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStartTangent {
    // This is an example of a functional test case.
    
    UIBezierPath* path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointZero];
    [path1 addLineToPoint:CGPointMake(10, 10)];
    
    CGFloat tangent = [path1 tangentAtStart];
    XCTAssertEqual((CGFloat)tangent, (CGFloat) -2.3561945, "tangent is correct");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

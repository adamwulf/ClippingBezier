//
//  MMClippingBezierUnionTest.m
//  ClippingBezierTests
//
//  Created by Adam Wulf on 5/21/20.
//

#import <XCTest/XCTest.h>
#import "MMClippingBezierAbstractTest.h"
#import <ClippingBezier/ClippingBezier.h>
#import <PerformanceBezier/PerformanceBezier.h>
#import <ClippingBezier/UIBezierPath+Clipping_Private.h>

@interface MMClippingBezierUnionTest : MMClippingBezierAbstractTest

@end

@implementation MMClippingBezierUnionTest

- (void)testSimpleUnionStep1
{
    UIBezierPath *path1 = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 100, 100)];
    UIBezierPath *path2 = [UIBezierPath bezierPathWithRect:CGRectMake(50, 20, 100, 60)];

    NSArray<DKUIBezierPathShape *> *finalShapes = [path1 allUniqueShapesWithPath:path2];

    XCTAssertEqual([finalShapes count], 3);

    XCTAssert([finalShapes[0] canGlueToShape:finalShapes[1]]);
    XCTAssert([finalShapes[0] canGlueToShape:finalShapes[2]]);

    DKUIBezierPathShape *unionShape = [[finalShapes[0] glueToShape:finalShapes[1]] glueToShape:finalShapes[2]];

    XCTAssertNotNil(unionShape);

    UIBezierPath *unionPath = [UIBezierPath bezierPath];
    [unionPath moveToPoint:CGPointMake(100, 20)];
    [unionPath addLineToPoint:CGPointMake(150, 20)];
    [unionPath addLineToPoint:CGPointMake(150, 80)];
    [unionPath addLineToPoint:CGPointMake(100, 80)];
    [unionPath addLineToPoint:CGPointMake(100, 100)];
    [unionPath addLineToPoint:CGPointMake(0, 100)];
    [unionPath addLineToPoint:CGPointMake(0, 0)];
    [unionPath addLineToPoint:CGPointMake(100, 0)];
    [unionPath addLineToPoint:CGPointMake(100, 20)];
    [unionPath closePath];

    XCTAssert([unionPath isEqualToBezierPath:[unionShape fullPath] withAccuracy:0.00001]);
}

- (void)testSimpleUnionStep2
{
    UIBezierPath *path1 = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 100, 100)];
    UIBezierPath *path2 = [UIBezierPath bezierPathWithRect:CGRectMake(50, 20, 100, 60)];

    NSArray<DKUIBezierPathShape *> *finalShapes = [path1 uniqueGluedShapesWithPath:path2];

    XCTAssertEqual([finalShapes count], 1);

    DKUIBezierPathShape *unionShape = finalShapes[0];

    UIBezierPath *unionPath = [UIBezierPath bezierPath];
    [unionPath moveToPoint:CGPointMake(100, 20)];
    [unionPath addLineToPoint:CGPointMake(150, 20)];
    [unionPath addLineToPoint:CGPointMake(150, 80)];
    [unionPath addLineToPoint:CGPointMake(100, 80)];
    [unionPath addLineToPoint:CGPointMake(100, 100)];
    [unionPath addLineToPoint:CGPointMake(0, 100)];
    [unionPath addLineToPoint:CGPointMake(0, 0)];
    [unionPath addLineToPoint:CGPointMake(100, 0)];
    [unionPath addLineToPoint:CGPointMake(100, 20)];
    [unionPath closePath];

    XCTAssert([unionPath isEqualToBezierPath:[unionShape fullPath] withAccuracy:0.00001]);
}

- (void)testSimpleUnionStep3
{
    UIBezierPath *path1 = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 100, 100)];
    UIBezierPath *path2 = [UIBezierPath bezierPathWithRect:CGRectMake(50, 20, 100, 60)];

    NSArray<UIBezierPath *> *finalShapes = [path1 unionWithPath:path2];

    XCTAssertEqual([finalShapes count], 1);

    UIBezierPath *unionShape = finalShapes[0];

    UIBezierPath *unionPath = [UIBezierPath bezierPath];
    [unionPath moveToPoint:CGPointMake(100, 20)];
    [unionPath addLineToPoint:CGPointMake(150, 20)];
    [unionPath addLineToPoint:CGPointMake(150, 80)];
    [unionPath addLineToPoint:CGPointMake(100, 80)];
    [unionPath addLineToPoint:CGPointMake(100, 100)];
    [unionPath addLineToPoint:CGPointMake(0, 100)];
    [unionPath addLineToPoint:CGPointMake(0, 0)];
    [unionPath addLineToPoint:CGPointMake(100, 0)];
    [unionPath addLineToPoint:CGPointMake(100, 20)];
    [unionPath closePath];

    XCTAssert([unionPath isEqualToBezierPath:unionShape withAccuracy:0.00001]);
}

- (void)testFullOverlapUnionStep1
{
    UIBezierPath *path1 = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 100, 100)];
    UIBezierPath *path2 = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 200, 100)];

    NSArray<DKUIBezierPathShape *> *finalShapes = [path1 allUniqueShapesWithPath:path2];

    XCTAssertEqual([finalShapes count], 2);

    XCTAssert([finalShapes[0] canGlueToShape:finalShapes[1]]);

    DKUIBezierPathShape *unionShape = [finalShapes[0] glueToShape:finalShapes[1]];

    XCTAssertNotNil(unionShape);

    UIBezierPath *unionPath = [UIBezierPath bezierPath];
    [unionPath moveToPoint:CGPointMake(0, 0)];
    [unionPath addLineToPoint:CGPointMake(100, 0)];
    [unionPath addLineToPoint:CGPointMake(200, 0)];
    [unionPath addLineToPoint:CGPointMake(200, 100)];
    [unionPath addLineToPoint:CGPointMake(100, 100)];
    [unionPath addLineToPoint:CGPointMake(0, 100)];
    [unionPath addLineToPoint:CGPointMake(0, 0)];
    [unionPath closePath];

    XCTAssert([unionPath isEqualToBezierPath:[unionShape fullPath] withAccuracy:0.00001]);
}

- (void)testFullOverlapUnion
{
    UIBezierPath *path1 = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 100, 100)];
    UIBezierPath *path2 = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 200, 100)];

    NSArray<UIBezierPath *> *finalShapes = [path1 unionWithPath:path2];

    XCTAssertEqual([finalShapes count], 1);

    UIBezierPath *unionPath = [UIBezierPath bezierPath];
    [unionPath moveToPoint:CGPointMake(0, 0)];
    [unionPath addLineToPoint:CGPointMake(100, 0)];
    [unionPath addLineToPoint:CGPointMake(200, 0)];
    [unionPath addLineToPoint:CGPointMake(200, 100)];
    [unionPath addLineToPoint:CGPointMake(100, 100)];
    [unionPath addLineToPoint:CGPointMake(0, 100)];
    [unionPath addLineToPoint:CGPointMake(0, 0)];
    [unionPath closePath];

    XCTAssert([unionPath isEqualToBezierPath:[finalShapes firstObject] withAccuracy:0.00001]);
}

- (void)testUnionToHole
{
    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointMake(100, 20)];
    [path1 addLineToPoint:CGPointMake(50, 20)];
    [path1 addLineToPoint:CGPointMake(50, 80)];
    [path1 addLineToPoint:CGPointMake(100, 80)];
    [path1 addLineToPoint:CGPointMake(100, 100)];
    [path1 addLineToPoint:CGPointMake(0, 100)];
    [path1 addLineToPoint:CGPointMake(0, 0)];
    [path1 addLineToPoint:CGPointMake(100, 0)];
    [path1 addLineToPoint:CGPointMake(100, 20)];
    [path1 closePath];

    UIBezierPath *path2 = [UIBezierPath bezierPath];
    [path2 moveToPoint:CGPointMake(70, 10)];
    [path2 addLineToPoint:CGPointMake(80, 10)];
    [path2 addLineToPoint:CGPointMake(80, 90)];
    [path2 addLineToPoint:CGPointMake(70, 90)];
    [path2 addLineToPoint:CGPointMake(70, 10)];
    [path2 closePath];

    NSArray<UIBezierPath *> *finalShapes = [path1 unionWithPath:path2];

    XCTAssertEqual([finalShapes count], 1);

    UIBezierPath *unionPath = [UIBezierPath bezierPath];
    [unionPath moveToPoint:CGPointMake(70.000000, 80.000000)];
    [unionPath addLineToPoint:CGPointMake(70.000000, 20.000000)];
    [unionPath addLineToPoint:CGPointMake(50.000000, 20.000000)];
    [unionPath addLineToPoint:CGPointMake(50.000000, 80.000000)];
    [unionPath addLineToPoint:CGPointMake(70.000000, 80.000000)];
    [unionPath addLineToPoint:CGPointMake(100.000000, 80.000000)];
    [unionPath addLineToPoint:CGPointMake(100.000000, 100.000000)];
    [unionPath addLineToPoint:CGPointMake(0.000000, 100.000000)];
    [unionPath addLineToPoint:CGPointMake(0.000000, 0.000000)];
    [unionPath addLineToPoint:CGPointMake(100.000000, 0.000000)];
    [unionPath addLineToPoint:CGPointMake(100.000000, 20.000000)];
    [unionPath addLineToPoint:CGPointMake(100.000000, 20.000000)];
    [unionPath addLineToPoint:CGPointMake(80.000000, 20.000000)];
    [unionPath addLineToPoint:CGPointMake(80.000000, 80.000000)];

    XCTAssert([unionPath isEqualToBezierPath:[finalShapes firstObject] withAccuracy:0.00001]);
}

@end

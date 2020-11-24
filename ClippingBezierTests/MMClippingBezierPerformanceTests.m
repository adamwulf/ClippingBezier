//
//  MMClippingBezierPerformanceTests.m
//  ClippingBezier
//
//  Created by Adam Wulf on 11/20/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MMClippingBezierAbstractTest.h"
#import <ClippingBezier/ClippingBezier.h>
#import <PerformanceBezier/PerformanceBezier.h>
#import <ClippingBezier/UIBezierPath+Clipping_Private.h>

@interface MMClippingBezierPerformanceTests : MMClippingBezierAbstractTest

@end

@implementation MMClippingBezierPerformanceTests {
    UIBezierPath *_cachedComplexShape;
}

- (void)setUp
{
    [super setUp];
    _cachedComplexShape = [UIBezierPath complexShape1];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


#pragma mark - Helpers

- (void)testScissorsThroughMultipleShapeHoles
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 300)];
    [scissorPath addLineToPoint:CGPointMake(800, 300)];

    UIBezierPath *shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 400, 200)];
    [shapePath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)] bezierPathByReversingPath]];
    [shapePath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(450, 250, 100, 100)] bezierPathByReversingPath]];

    [self measureBlock:^{
        [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    }];
}

#pragma mark - Performance for Flat

- (void)testCalculateUnclosedPathThroughClosedBoundsFast
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

    [self measureBlock:^{
        for (int i = 0; i < 5; i++) {
            [UIBezierPath calculateIntersectionAndDifferenceBetween:testPath andPath:bounds];
        }
    }];
}

- (void)testFindIntersectionPerformance
{
    UIBezierPath *complex1 = [UIBezierPath complexShape1];
    UIBezierPath *complex2 = [UIBezierPath complexShape1];

    [self measureBlock:^{
        UIBezierPath *path1 = [complex1 copy];
        UIBezierPath *path2 = [complex2 copy];

        [path1 findIntersectionsWithClosedPath:path2 andBeginsInside:NULL];
        [path1 allUniqueShapesWithPath:path2];
    }];
}

- (void)testFindOnlyIntersectionPerformance
{
    UIBezierPath *complex1 = [UIBezierPath complexShape1];
    UIBezierPath *complex2 = [UIBezierPath complexShape1];

    [self measureBlock:^{
        UIBezierPath *path1 = [complex1 copy];
        UIBezierPath *path2 = [complex2 copy];

        [path1 findIntersectionsWithClosedPath:path2 andBeginsInside:NULL];
    }];
}

- (void)testIntersectionAndDifference
{
    [self measureBlock:^{
        for (int i = 0; i < 100; i++) {
            CGPoint bez1_[4], bez2_[4];

            bez1_[0] = CGPointMake(100.0, 50.0);
            bez1_[1] = CGPointMake(370.0, 80.0);
            bez1_[2] = CGPointMake(570.0, 520.0);
            bez1_[3] = CGPointMake(600.0, 850.0);


            UIBezierPath *line = [UIBezierPath bezierPath];
            [line moveToPoint:bez1_[0]];
            [line addCurveToPoint:bez1_[3] controlPoint1:bez1_[1] controlPoint2:bez1_[2]];

            CGPoint *bez1 = bez1_;
            CGPoint *bez2 = bez2_;

            __block int found = 0;
            __block CGPoint lastPoint;

            NSMutableArray *output = [NSMutableArray array];

            [_cachedComplexShape iteratePathWithBlock:^(CGPathElement element, NSUInteger idx) {
                if (element.type == kCGPathElementCloseSubpath) {
                    // noop
                } else {
                    if (element.type == kCGPathElementAddCurveToPoint) {
                        bez2[0] = lastPoint;
                        bez2[1] = element.points[0];
                        bez2[2] = element.points[1];
                        bez2[3] = element.points[2];
                    } else if (element.type == kCGPathElementAddLineToPoint) {
                        bez2[0] = lastPoint;
                        bez2[1] = lastPoint;
                        bez2[2] = element.points[0];
                        bez2[3] = element.points[0];
                    }
                    lastPoint = element.points[[UIBezierPath numberOfPointsForElement:element] - 1];

                    if (element.type != kCGPathElementMoveToPoint) {
                        NSArray *intersections = [UIBezierPath findIntersectionsBetweenBezier:bez1 andBezier:bez2];
                        found += [intersections count];
                        [output addObjectsFromArray:intersections];
                    }
                }
            }];


            [line findIntersectionsWithClosedPath:_cachedComplexShape andBeginsInside:nil];
        }
    }];
}

@end

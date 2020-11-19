//
//  MMClippingBezierTodoTests.m
//  ClippingBezierTests
//
//  Created by Adam Wulf on 11/13/20.
//

#import <XCTest/XCTest.h>
#import "MMClippingBezierAbstractTest.h"
#import <ClippingBezier/ClippingBezier.h>
#import <PerformanceBezier/PerformanceBezier.h>
#import <ClippingBezier/UIBezierPath+Clipping_Private.h>

@interface MMClippingBezierTodoTests : MMClippingBezierAbstractTest

@end

@implementation MMClippingBezierTodoTests

#pragma mark - Flat Tests

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

    NSArray *output = [UIBezierPath calculateIntersectionAndDifferenceBetween:testPath andPath:bounds];


    //    NSLog(@"cropped path: %@", [[output firstObject] bezierPathByUnflatteningPath]);
    //    NSLog(@"cropped path: %@", [[output lastObject] bezierPathByUnflatteningPath]);

    UIBezierPath *inter = [output firstObject];
    UIBezierPath *diff = [output lastObject];


    XCTAssertEqual([inter elementCount], 1556, @"the curves do intersect");
    XCTAssertEqual([diff elementCount], 1184, @"the curves do intersect");

    XCTAssertEqual([[inter subPaths] count], (NSUInteger)2, @"the curves do intersect");
    XCTAssertEqual([[diff subPaths] count], (NSUInteger)1, @"the curves do intersect");

    XCTAssertEqual(inter.firstPoint.x, 100.0, @"starts at the right place");
    XCTAssertEqual(inter.firstPoint.y, 50.0, @"starts at the right place");
    XCTAssertEqual(floorf(inter.lastPoint.x), 100.0, @"ends at the right place");
    XCTAssertEqual(inter.lastPoint.y, 250.0, @"ends at the right place");

    XCTAssertEqual(floorf(diff.firstPoint.x), 143.0, @"starts at the right place");
    XCTAssertEqual(diff.firstPoint.y, 100.0, @"starts at the right place");
    XCTAssertEqual(floorf(diff.lastPoint.x), 143.0, @"starts at the right place");
    XCTAssertEqual(diff.lastPoint.y, 200.0, @"starts at the right place");
}

#pragma mark - Intersection Tests

- (void)testFindingIntersectionsForVerticalTangentLines
{
    // there is a TODO in UIBezierPath+Clipping.m to handle tangent lines
    XCTAssertTrue(NO, @"functionality needs defining");
    return;
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300.0, 100.0)];
    [scissorPath addLineToPoint:CGPointMake(300.0, 200.0)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(300.0, 50.0)];
    [shapePath addLineToPoint:CGPointMake(300.0, 250.0)];


    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)2, @"the curves do intersect");
}

- (void)testFindingIntersectionsForDiagonalTangentLines
{
    // there is a TODO in UIBezierPath+Clipping.m to handle tangent lines
    XCTAssertTrue(NO, @"functionality needs defining");
    return;
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300.0, 300.0)];
    [scissorPath addLineToPoint:CGPointMake(500.0, 500.0)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(50.0, 50.0)];
    [shapePath addLineToPoint:CGPointMake(600.0, 600.0)];


    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)2, @"the curves do intersect");
}

#pragma mark - Segment Tangent Tests

- (void)testLineNearBoundary2
{
    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(0.000000, 0.000000)];
    [shapePath addLineToPoint:CGPointMake(768.000000, 0.000000)];
    [shapePath addLineToPoint:CGPointMake(768.000000, 1024.000000)];
    [shapePath addLineToPoint:CGPointMake(0.000000, 1024.000000)];
    [shapePath closePath];

    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(478.500000, 1024.000000)];
    [scissorPath addCurveToPoint:CGPointMake(484.000000, 1024.000000) controlPoint1:CGPointMake(480.562500, 1024.000000) controlPoint2:CGPointMake(481.937500, 1024.000000)];


    XCTAssertTrue(NO, @"incorrect intersection count");

    // This is an example where the two paths generate different intersection
    // counts depending on which path is comparing to the other
    NSArray *redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];

    NSArray *redSegments = [redGreenBlueSegs firstObject];
    NSArray *greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray *blueSegments = [redGreenBlueSegs lastObject];

    XCTAssertEqual([redSegments count], (NSUInteger)3, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)0, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)2, @"correct number of segments");
}

- (void)testLineNearBoundary3
{
    // path is tangent that is 2pts long
    // intersections are allowed to be .5 distnace away
    // from each other, so max of 4 intersections might
    // happen

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(0.000000, 0.000000)];
    [shapePath addLineToPoint:CGPointMake(768.000000, 0.000000)];
    [shapePath addLineToPoint:CGPointMake(768.000000, 1024.000000)];
    [shapePath addLineToPoint:CGPointMake(0.000000, 1024.000000)];
    [shapePath closePath];

    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(478.500000, 1024.000000)];
    [scissorPath addCurveToPoint:CGPointMake(484.000000, 1024.000000) controlPoint1:CGPointMake(480.562500, 1024.000000) controlPoint2:CGPointMake(481.937500, 1024.000000)];


    BOOL beginsInside = NO;
    NSArray *scissorToShapeIntersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    NSArray *shapeToScissorIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:&beginsInside];

    XCTAssertEqual([scissorToShapeIntersections count], [shapeToScissorIntersections count], @"count of intersections matches");
    XCTAssertEqual([scissorToShapeIntersections count], (NSUInteger)2, @"count of intersections matches");
}

#pragma mark - Segment Tests

- (void)testReversedSquaredCircleIntersections
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath *shapePath = [[UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)] bezierPathByReversingPath];

    XCTAssertTrue(![shapePath isClockwise], @"shape is correct direction");

    NSArray *allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray *redSegments = [allSegments firstObject];
    NSArray *blueSegments = [allSegments lastObject];

    XCTAssertEqual([redSegments count], (NSUInteger)8, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)4, @"correct number of segments");

    DKUIBezierPathClippedSegment *redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment *correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment *currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");

    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], 0.999995, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], .999997, @"correct intersection");

    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.500001, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 0.500002, @"correct intersection");
}

- (void)testRedBlueSegmentsFromLooseLeafCrash
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0.000000, 0.000000)];
    [path addLineToPoint:CGPointMake(768.000000, 0.000000)];
    [path addLineToPoint:CGPointMake(768.000000, 1024.000000)];
    [path addLineToPoint:CGPointMake(0.000000, 1024.000000)];
    [path closePath];
    UIBezierPath *shapePath = path;


    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(492.000000, 1024.000000)];
    [path addCurveToPoint:CGPointMake(496.000000, 1024.000000) controlPoint1:CGPointMake(493.500000, 1024.000000) controlPoint2:CGPointMake(494.500000, 1024.000000)];
    UIBezierPath *scissorPath = path;

    // TODO: define correct behavior

    XCTAssertTrue(NO, @"define correct behavior for segments along a tangent");
    return;

    NSArray *allSegments = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray *redSegments = [allSegments firstObject];
    NSArray *greenSegments = [allSegments objectAtIndex:1];
    NSArray *blueSegments = [allSegments lastObject];

    XCTAssertEqual([redSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)10, @"correct number of segments");
}

#pragma mark - Subshape Tests

- (void)testShapeWithLoop
{
    XCTAssertTrue(NO, @"functionality needs defining");
    return;

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(100, 100)];
    [path addLineToPoint:CGPointMake(250, 200)];
    [path addLineToPoint:CGPointMake(150, 200)];
    [path addLineToPoint:CGPointMake(300, 100)];
    [path addLineToPoint:CGPointMake(300, 300)];
    [path addLineToPoint:CGPointMake(100, 300)];
    [path closePath];

    UIBezierPath *shapePath = path;

    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(50, 180)];
    [path addLineToPoint:CGPointMake(400, 180)];

    UIBezierPath *scissorPath = path;

    XCTAssertTrue([shapePath isClockwise], @"correct direction for shape");

    NSArray *subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray *foundShapes = [subShapePaths firstObject];

    XCTAssertEqual([foundShapes count], (NSUInteger)6, @"found intersection");

    XCTAssertTrue(![[foundShapes objectAtIndex:0] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:1] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:2] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:3] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:4] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:5] isClosed], @"shape is closed");

    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)3, @"found closed shape");
}


- (void)testCurveThroughKnottedBlob
{
    XCTAssertTrue(NO, @"functionality needs defining (same as loop)");
    return;

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(371.500000, 266.000000)];
    [path addCurveToPoint:CGPointMake(369.000000, 276.000000) controlPoint1:CGPointMake(371.637207, 295.950989) controlPoint2:CGPointMake(369.272766, 286.009338)];
    [path addCurveToPoint:CGPointMake(420.000000, 157.000000) controlPoint1:CGPointMake(371.004883, 232.057419) controlPoint2:CGPointMake(390.991333, 189.956833)];
    [path addCurveToPoint:CGPointMake(506.000000, 106.000000) controlPoint1:CGPointMake(440.922211, 129.376144) controlPoint2:CGPointMake(474.516174, 116.712044)];
    [path addCurveToPoint:CGPointMake(615.000000, 115.000000) controlPoint1:CGPointMake(536.984070, 106.796577) controlPoint2:CGPointMake(589.646912, 83.388374)];
    [path addCurveToPoint:CGPointMake(546.000000, 373.000000) controlPoint1:CGPointMake(626.037476, 204.520370) controlPoint2:CGPointMake(495.768799, 280.938873)];
    [path addCurveToPoint:CGPointMake(623.000000, 384.000000) controlPoint1:CGPointMake(567.335999, 391.972473) controlPoint2:CGPointMake(598.341125, 379.906830)];
    [path addCurveToPoint:CGPointMake(774.000000, 375.000000) controlPoint1:CGPointMake(671.968994, 382.345123) controlPoint2:CGPointMake(724.617249, 361.854858)];
    [path addCurveToPoint:CGPointMake(781.000000, 413.000000) controlPoint1:CGPointMake(787.511475, 382.723633) controlPoint2:CGPointMake(784.593323, 401.081268)];
    [path addCurveToPoint:CGPointMake(692.000000, 474.000000) controlPoint1:CGPointMake(759.329468, 443.872040) controlPoint2:CGPointMake(723.033691, 455.754028)];
    [path addCurveToPoint:CGPointMake(549.000000, 514.000000) controlPoint1:CGPointMake(646.779175, 495.459320) controlPoint2:CGPointMake(597.793274, 505.253662)];
    [path addCurveToPoint:CGPointMake(450.000000, 505.000000) controlPoint1:CGPointMake(518.306885, 508.762817) controlPoint2:CGPointMake(478.378906, 526.811340)];
    [path addCurveToPoint:CGPointMake(430.000000, 475.000000) controlPoint1:CGPointMake(439.507996, 498.173584) controlPoint2:CGPointMake(432.429626, 487.065155)];
    [path addCurveToPoint:CGPointMake(445.000000, 393.000000) controlPoint1:CGPointMake(425.595398, 446.551178) controlPoint2:CGPointMake(437.583923, 419.706482)];
    [path addCurveToPoint:CGPointMake(457.000000, 320.000000) controlPoint1:CGPointMake(455.314575, 369.826050) controlPoint2:CGPointMake(457.307068, 344.823364)];
    [path addCurveToPoint:CGPointMake(435.000000, 313.000000) controlPoint1:CGPointMake(453.216187, 311.635437) controlPoint2:CGPointMake(442.641693, 309.512451)];
    [path addCurveToPoint:CGPointMake(376.000000, 339.000000) controlPoint1:CGPointMake(411.457245, 308.111420) controlPoint2:CGPointMake(394.201599, 328.960175)];
    [path addCurveToPoint:CGPointMake(312.000000, 385.000000) controlPoint1:CGPointMake(351.608612, 349.994873) controlPoint2:CGPointMake(334.147675, 370.701691)];
    [path addCurveToPoint:CGPointMake(216.000000, 451.000000) controlPoint1:CGPointMake(281.791748, 408.852356) controlPoint2:CGPointMake(253.632233, 438.732269)];
    [path addCurveToPoint:CGPointMake(153.000000, 456.000000) controlPoint1:CGPointMake(196.110214, 459.443695) controlPoint2:CGPointMake(173.923309, 459.282318)];
    [path addCurveToPoint:CGPointMake(96.000000, 384.000000) controlPoint1:CGPointMake(121.299950, 445.098145) controlPoint2:CGPointMake(106.937531, 413.023285)];
    [path addCurveToPoint:CGPointMake(90.000000, 251.000000) controlPoint1:CGPointMake(82.571686, 341.199219) controlPoint2:CGPointMake(81.054222, 294.931030)];
    [path addCurveToPoint:CGPointMake(153.000000, 153.000000) controlPoint1:CGPointMake(99.254639, 214.629913) controlPoint2:CGPointMake(116.462486, 171.269882)];
    [path addLineToPoint:CGPointMake(153.000000, 153.000000)];
    [path addLineToPoint:CGPointMake(224.000000, 164.000000)];
    [path addCurveToPoint:CGPointMake(314.000000, 254.000000) controlPoint1:CGPointMake(267.577942, 177.148834) controlPoint2:CGPointMake(254.564407, 275.088074)];
    [path addLineToPoint:CGPointMake(314.000000, 254.000000)];
    [path addLineToPoint:CGPointMake(371.500000, 266.000000)];
    [path closePath];

    UIBezierPath *shapePath = path;


    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(755.000000, 236.000000)];
    [path addCurveToPoint:CGPointMake(116.000000, 307.000000) controlPoint1:CGPointMake(543.220825, 192.273193) controlPoint2:CGPointMake(328.863098, 304.263763)];
    [path addCurveToPoint:CGPointMake(142.000000, 277.000000) controlPoint1:CGPointMake(103.893066, 293.674683) controlPoint2:CGPointMake(129.960800, 273.840576)];
    [path addCurveToPoint:CGPointMake(275.000000, 240.000000) controlPoint1:CGPointMake(184.754257, 259.168274) controlPoint2:CGPointMake(230.349365, 251.159592)];
    [path addCurveToPoint:CGPointMake(445.000000, 200.000000) controlPoint1:CGPointMake(330.876129, 223.224686) controlPoint2:CGPointMake(388.530731, 214.236267)];
    [path addCurveToPoint:CGPointMake(612.000000, 169.000000) controlPoint1:CGPointMake(499.946594, 185.988968) controlPoint2:CGPointMake(555.905518, 176.790924)];
    [path addCurveToPoint:CGPointMake(830.000000, 126.000000) controlPoint1:CGPointMake(683.244446, 153.338440) controlPoint2:CGPointMake(761.097961, 150.868408)];

    UIBezierPath *scissorPath = path;

    XCTAssertTrue([shapePath isClockwise], @"correct direction for shape");

    NSArray *subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray *foundShapes = [subShapePaths firstObject];

    XCTAssertEqual([foundShapes count], (NSUInteger)8, @"found intersection");

    XCTAssertTrue([[foundShapes objectAtIndex:0] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:1] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:2] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:3] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:4] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:5] isClosed], @"shape is closed");
    XCTAssertTrue(![[foundShapes objectAtIndex:6] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:7] isClosed], @"shape is closed");

    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)5, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)5, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)5, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:6] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:7] segments] count], (NSUInteger)2, @"found closed shape");


    CGRect b = [[foundShapes objectAtIndex:5] fullPath].bounds;
    CGRect container = CGRectMake(b.origin.x, b.origin.y, 20, 20);
    XCTAssertTrue(CGRectContainsRect(container, b), @"shape is very small from the knot");
}

- (void)testShapesFromReversedPath
{
    UIBezierPath *splitterPath = [UIBezierPath bezierPath];
    [splitterPath moveToPoint:CGPointMake(12.000000, 16.970563)];
    [splitterPath addLineToPoint:CGPointMake(208.000000, 16.970563)];
    [splitterPath addLineToPoint:CGPointMake(208.000000, 128.000000)];
    [splitterPath addLineToPoint:CGPointMake(12.000000, 128.000000)];
    [splitterPath closePath];

    UIBezierPath *splittingPath = splittingPath = [UIBezierPath bezierPath];
    [splittingPath moveToPoint:CGPointMake(12.000000, 32.000000)];
    [splittingPath addCurveToPoint:CGPointMake(12.000000, 32.000000) controlPoint1:CGPointMake(12.000000, 32.000000) controlPoint2:CGPointMake(12.000000, 32.000000)];
    [splittingPath addLineToPoint:CGPointMake(12.000000, 12.000000)];
    [splittingPath addLineToPoint:CGPointMake(12.000000, 128.000000)];
    [splittingPath addCurveToPoint:CGPointMake(12.000000, 128.000000) controlPoint1:CGPointMake(12.000000, 128.000000) controlPoint2:CGPointMake(12.000000, 128.000000)];
    [splittingPath addLineToPoint:CGPointMake(208.000000, 128.000000)];
    [splittingPath addLineToPoint:CGPointMake(208.000000, 128.000000)];
    [splittingPath addCurveToPoint:CGPointMake(208.000000, 128.000000) controlPoint1:CGPointMake(208.000000, 128.000000) controlPoint2:CGPointMake(208.000000, 128.000000)];
    [splittingPath addLineToPoint:CGPointMake(208.000000, 32.000000)];
    [splittingPath addLineToPoint:CGPointMake(208.000000, 32.000000)];
    [splittingPath addCurveToPoint:CGPointMake(208.000000, 32.000000) controlPoint1:CGPointMake(208.000000, 32.000000) controlPoint2:CGPointMake(208.000000, 32.000000)];
    [splittingPath addLineToPoint:CGPointMake(220.000000, 32.000000)];
    [splittingPath addLineToPoint:CGPointMake(220.000000, 32.000000)];
    [splittingPath addCurveToPoint:CGPointMake(211.514719, 28.485281) controlPoint1:CGPointMake(216.817402, 32.000000) controlPoint2:CGPointMake(213.765155, 30.735718)];
    [splittingPath addLineToPoint:CGPointMake(200.000000, 16.970563)];
    [splittingPath addLineToPoint:CGPointMake(190.828427, 26.142136)];
    [splittingPath addLineToPoint:CGPointMake(190.828427, 26.142136)];
    [splittingPath addCurveToPoint:CGPointMake(176.686292, 32.000000) controlPoint1:CGPointMake(187.077700, 29.892863) controlPoint2:CGPointMake(181.990621, 32.000000)];
    [splittingPath addLineToPoint:CGPointMake(12.000000, 32.000000)];
    [splittingPath closePath];

    NSArray *shapes1 = [splittingPath uniqueShapesCreatedFromSlicingWithUnclosedPath:splitterPath];
    NSArray *shapes2 = [splittingPath uniqueShapesCreatedFromSlicingWithUnclosedPath:[splitterPath bezierPathByReversingPath]];

    XCTAssertEqual([shapes1 count], [shapes2 count]);
}

@end

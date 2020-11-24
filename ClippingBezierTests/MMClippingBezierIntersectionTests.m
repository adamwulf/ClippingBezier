//
//  MMClippingBezierIntersectionTests.m
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

@interface MMClippingBezierIntersectionTests : MMClippingBezierAbstractTest

@end

@implementation MMClippingBezierIntersectionTests

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

- (void)testIntersectionByClipping
{
    //
    // testPath is a curved line that starts
    // out above bounds, and curves through the
    // bounds box until it ends outside on the
    // other side

    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 50)];
    [scissorPath addCurveToPoint:CGPointMake(100, 250)
                   controlPoint1:CGPointMake(170, 80)
                   controlPoint2:CGPointMake(170, 220)];

    // simple 100x100 box
    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(100, 100)];
    [shapePath addLineToPoint:CGPointMake(200, 100)];


    CGPoint bez1[4], bez2[4];
    bez1[0] = CGPointMake(100, 50);
    bez1[1] = CGPointMake(170, 80);
    bez1[2] = CGPointMake(170, 220);
    bez1[3] = CGPointMake(100, 250);

    bez2[0] = CGPointMake(100, 100);
    bez2[1] = CGPointMake(100, 100);
    bez2[2] = CGPointMake(200, 100);
    bez2[3] = CGPointMake(200, 100);

    NSArray *intersections = [UIBezierPath findIntersectionsBetweenBezier:bez1 andBezier:bez2];
    NSArray *otherIntersections = [UIBezierPath findIntersectionsBetweenBezier:bez2 andBezier:bez1];

    CGPoint int1 = [[intersections firstObject] CGPointValue];

    CGPoint val1 = [UIBezierPath pointAtT:int1.y forBezier:bez1];
    CGPoint val2 = [UIBezierPath pointAtT:int1.x forBezier:bez2];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)1, @"found intersections");

    XCTAssertEqual(floorf(val1.x), 143.0, @"ends at the right place");
    XCTAssertEqual(floorf(val2.x), 143.0, @"ends at the right place");
    XCTAssertEqual(roundf(val1.y), 100.0, @"ends at the right place");
    XCTAssertEqual(roundf(val2.y), 100.0, @"ends at the right place");
}

- (void)testIntersectionWithComplexShape
{
    CGPoint bez1_[4], bez2_[4];

    bez1_[0] = CGPointMake(100.0, 50.0);
    bez1_[1] = CGPointMake(370.0, 80.0);
    bez1_[2] = CGPointMake(570.0, 520.0);
    bez1_[3] = CGPointMake(600.0, 850.0);


    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:bez1_[0]];
    [scissorPath addCurveToPoint:bez1_[3] controlPoint1:bez1_[1] controlPoint2:bez1_[2]];

    CGPoint *bez1 = bez1_;
    CGPoint *bez2 = bez2_;

    __block int found = 0;
    __block CGPoint lastPoint;

    NSMutableArray *output = [NSMutableArray array];

    [[UIBezierPath complexShape1] iteratePathWithBlock:^(CGPathElement element, NSUInteger idx) {
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

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:[UIBezierPath complexShape1] andBeginsInside:nil];
    NSArray *otherIntersections = [[UIBezierPath complexShape1] findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)8, @"the curves do intersect");
    XCTAssertEqual(found, 8, @"the curves do intersect");

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:3] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:4] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:5] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:6] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:7] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:3] location1] isNearTo:[[intersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:4] location1] isNearTo:[[intersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:5] location1] isNearTo:[[intersections objectAtIndex:5] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:6] location1] isNearTo:[[intersections objectAtIndex:6] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:7] location1] isNearTo:[[intersections objectAtIndex:7] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:3] location1] isNearTo:[[otherIntersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:4] location1] isNearTo:[[otherIntersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:5] location1] isNearTo:[[otherIntersections objectAtIndex:5] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:6] location1] isNearTo:[[otherIntersections objectAtIndex:6] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:7] location1] isNearTo:[[otherIntersections objectAtIndex:7] location2]], @"locations match");
}


- (void)testFindingTwoIntersectionsWithinSingleElement
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300.0, 50.0)];
    [scissorPath addLineToPoint:CGPointMake(300.0, 600.0)];

    UIBezierPath *shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];


    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)2, @"the curves do intersect");

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");

    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
}

- (void)testFindingTwoIntersectionsWithinSingleElementFlattened
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300.0, 50.0)];
    [scissorPath addLineToPoint:CGPointMake(300.0, 600.0)];

    UIBezierPath *shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];


    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)2, @"the curves do intersect");

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");

    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
}

- (void)testPossiblyImpreciseIntersectionWithPaths
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100.0, 50.0)];
    [scissorPath addCurveToPoint:CGPointMake(600.0, 850.0) controlPoint1:CGPointMake(370.0, 80.0) controlPoint2:CGPointMake(570.0, 520.0)];

    UIBezierPath *complexShape = [UIBezierPath bezierPath];
    [complexShape moveToPoint:CGPointMake(395.000000, 297.000000)];
    [complexShape addCurveToPoint:CGPointMake(413.000000, 285.000000) controlPoint1:CGPointMake(401.931854, 294.629944) controlPoint2:CGPointMake(408.147980, 290.431854)];


    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:complexShape andBeginsInside:nil];
    NSArray *otherIntersections = [complexShape findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)1, @"the curves do intersect");

    XCTAssertTrue(![[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
}

- (void)testPossiblyImpreciseIntersectionWithPathsFlattened
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100.0, 50.0)];
    [scissorPath addCurveToPoint:CGPointMake(600.0, 850.0) controlPoint1:CGPointMake(370.0, 80.0) controlPoint2:CGPointMake(570.0, 520.0)];

    UIBezierPath *complexShape = [UIBezierPath bezierPath];
    [complexShape moveToPoint:CGPointMake(395.000000, 297.000000)];
    [complexShape addCurveToPoint:CGPointMake(413.000000, 285.000000) controlPoint1:CGPointMake(401.931854, 294.629944) controlPoint2:CGPointMake(408.147980, 290.431854)];


    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:complexShape andBeginsInside:nil];
    NSArray *otherIntersections = [complexShape findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)1, @"the curves do intersect");

    XCTAssertTrue(![[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
}


- (void)testTangentialLineToBox
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 50)];
    [scissorPath addLineToPoint:CGPointMake(200, 50)];

    UIBezierPath *shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(110, 50, 50, 50)];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];
    int found = (int)[intersections count];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual(found, 2, @"the curves do intersect");

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");

    for (DKUIBezierPathIntersectionPoint *inter in intersections) {
        XCTAssertTrue([otherIntersections containsObject:[inter flipped]], @"share all intersections");
    }
    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
}


- (void)testCroppedLineNearBox
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(228.740005, 677.400024)];
    [scissorPath addCurveToPoint:CGPointMake(364.369995, 785.309998) controlPoint1:CGPointMake(277.583832, 720.138367) controlPoint2:CGPointMake(312.374023, 746.360291)];


    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(242.346939, 728.551025)];
    [shapePath addLineToPoint:CGPointMake(216.000000, 571.000000)];
    [shapePath addLineToPoint:CGPointMake(441.000000, 581.000000)];
    [shapePath addLineToPoint:CGPointMake(456.000000, 738.000000)];
    [shapePath addLineToPoint:CGPointMake(242.346939, 728.551025)];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];
    int found = (int)[intersections count];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual(found, 2, @"the curves do intersect");

    for (DKUIBezierPathIntersectionPoint *inter in intersections) {
        XCTAssertTrue([otherIntersections containsObject:[inter flipped]], @"share all intersections");
    }

    // does not cross boundary because the shape is not closed
    XCTAssertTrue(![[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue(![[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
}


- (void)testCroppedLineNearBox2
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(319.820007, 570.479980)];
    [scissorPath addCurveToPoint:CGPointMake(403.970001, 640.770020) controlPoint1:CGPointMake(348.899170, 599.428711) controlPoint2:CGPointMake(371.487671, 615.596191)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(255.457962, 575.995605)];
    [shapePath addLineToPoint:CGPointMake(255.457962, 575.995605)];
    [shapePath addLineToPoint:CGPointMake(210.000000, 352.000000)];
    [shapePath addCurveToPoint:CGPointMake(542.000000, 325.000000) controlPoint1:CGPointMake(320.657410, 363.659424) controlPoint2:CGPointMake(432.170624, 330.984741)];
    [shapePath addCurveToPoint:CGPointMake(668.000000, 614.000000) controlPoint1:CGPointMake(598.006409, 414.584595) controlPoint2:CGPointMake(631.124756, 515.893066)];
    [shapePath addCurveToPoint:CGPointMake(635.000000, 614.000000) controlPoint1:CGPointMake(656.999756, 614.000183) controlPoint2:CGPointMake(646.000244, 613.999878)];
    [shapePath addCurveToPoint:CGPointMake(482.000000, 607.000000) controlPoint1:CGPointMake(583.930847, 615.116699) controlPoint2:CGPointMake(532.702637, 613.585693)];
    [shapePath addCurveToPoint:CGPointMake(255.457962, 575.995605) controlPoint1:CGPointMake(409.848999, 595.660767) controlPoint2:CGPointMake(337.250244, 587.611084)];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)1, @"the curves do intersect");

    // does not cross boundary because the shape is not closed
    XCTAssertTrue(![[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
}


- (void)testIntersectionBetweenPathElements
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 100)];
    [scissorPath addCurveToPoint:CGPointMake(400, 400) controlPoint1:CGPointMake(100, 100) controlPoint2:CGPointMake(400, 400)];

    UIBezierPath *shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(50, 50, 100, 100)];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];
    int found = (int)[intersections count];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual(found, 1, @"the curves do intersect");

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
}

- (void)testScissorAtShapeBeginningWithComplexShape
{
    // the scissor approaches the first point of the closed shape,
    // and does so at a near tangent to a curve at that point,
    // so it registers a false positive intersection point.
    //
    // this test confirms that we filter out that point to get
    // the correct number of 8 intersections instead of incorrect
    // number of 9
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(210.500000, 376.000000)];
    [scissorPath addLineToPoint:CGPointMake(218.500000, 376.000000)];
    [scissorPath addCurveToPoint:CGPointMake(229.500000, 376.000000)
                   controlPoint1:CGPointMake(210.500000, 376.000000)
                   controlPoint2:CGPointMake(229.500000, 376.000000)];
    [scissorPath addCurveToPoint:CGPointMake(290, 360)
                   controlPoint1:CGPointMake(229.500000, 376.000000)
                   controlPoint2:CGPointMake(290, 360)];

    [scissorPath addCurveToPoint:CGPointMake(500, 560)
                   controlPoint1:CGPointMake(290, 360)
                   controlPoint2:CGPointMake(500, 560)];

    [scissorPath addCurveToPoint:CGPointMake(750, 750)
                   controlPoint1:CGPointMake(500, 560)
                   controlPoint2:CGPointMake(720, 750)];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:[UIBezierPath complexShape1] andBeginsInside:nil];
    NSArray *otherIntersections = [[UIBezierPath complexShape1] findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    // we add 1 because the complex shape is being clipped to the unclosed shape,
    // which means it'll get an intersection at the start + end of it's paths.
    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)9, @"found 9 intersections");

    XCTAssertFalse([[intersections objectAtIndex:0] mayCrossBoundary], @"doesn't cross boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:3] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:4] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:5] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:6] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:7] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:8] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:3] location1] isNearTo:[[intersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:4] location1] isNearTo:[[intersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:5] location1] isNearTo:[[intersections objectAtIndex:5] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:6] location1] isNearTo:[[intersections objectAtIndex:6] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:7] location1] isNearTo:[[intersections objectAtIndex:7] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:8] location1] isNearTo:[[intersections objectAtIndex:8] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:3] location1] isNearTo:[[otherIntersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:4] location1] isNearTo:[[otherIntersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:5] location1] isNearTo:[[otherIntersections objectAtIndex:5] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:6] location1] isNearTo:[[otherIntersections objectAtIndex:6] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:7] location1] isNearTo:[[otherIntersections objectAtIndex:7] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:8] location1] isNearTo:[[otherIntersections objectAtIndex:8] location2]], @"locations match");
}

- (void)testScissorAtShapeBeginningWithComplexShapeFlattened
{
    // the scissor approaches the first point of the closed shape,
    // and does so at a near tangent to a curve at that point,
    // so it registers a false positive intersection point.
    //
    // this test confirms that we filter out that point to get
    // the correct number of 8 intersections instead of incorrect
    // number of 9
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(210.500000, 376.000000)];
    [scissorPath addLineToPoint:CGPointMake(218.500000, 376.000000)];
    [scissorPath addCurveToPoint:CGPointMake(229.500000, 376.000000)
                   controlPoint1:CGPointMake(210.500000, 376.000000)
                   controlPoint2:CGPointMake(229.500000, 376.000000)];
    [scissorPath addCurveToPoint:CGPointMake(290, 360)
                   controlPoint1:CGPointMake(229.500000, 376.000000)
                   controlPoint2:CGPointMake(290, 360)];

    [scissorPath addCurveToPoint:CGPointMake(500, 560)
                   controlPoint1:CGPointMake(290, 360)
                   controlPoint2:CGPointMake(500, 560)];

    [scissorPath addCurveToPoint:CGPointMake(750, 750)
                   controlPoint1:CGPointMake(500, 560)
                   controlPoint2:CGPointMake(720, 750)];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:[UIBezierPath complexShape1] andBeginsInside:nil];
    NSArray *otherIntersections = [[UIBezierPath complexShape1] findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    // we add 1 because the complex shape is being clipped to the unclosed shape,
    // which means it'll get an intersection at the start + end of it's paths.
    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)9, @"found 9 intersections");

    XCTAssertFalse([[intersections objectAtIndex:0] mayCrossBoundary], @"doesn't cross boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:3] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:4] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:5] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:6] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:7] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:8] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:3] location1] isNearTo:[[intersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:4] location1] isNearTo:[[intersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:5] location1] isNearTo:[[intersections objectAtIndex:5] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:6] location1] isNearTo:[[intersections objectAtIndex:6] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:7] location1] isNearTo:[[intersections objectAtIndex:7] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:8] location1] isNearTo:[[intersections objectAtIndex:8] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:3] location1] isNearTo:[[otherIntersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:4] location1] isNearTo:[[otherIntersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:5] location1] isNearTo:[[otherIntersections objectAtIndex:5] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:6] location1] isNearTo:[[otherIntersections objectAtIndex:6] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:7] location1] isNearTo:[[otherIntersections objectAtIndex:7] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:8] location1] isNearTo:[[otherIntersections objectAtIndex:8] location2]], @"locations match");
}


- (void)testScissorAtShapeBeginningWithComplexShape2
{
    // slightly different start point than the above test
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(210.500000, 386.000000)];
    [scissorPath addLineToPoint:CGPointMake(218.500000, 376.000000)];
    [scissorPath addCurveToPoint:CGPointMake(229.500000, 376.000000)
                   controlPoint1:CGPointMake(210.500000, 376.000000)
                   controlPoint2:CGPointMake(229.500000, 376.000000)];
    [scissorPath addCurveToPoint:CGPointMake(290, 360)
                   controlPoint1:CGPointMake(229.500000, 376.000000)
                   controlPoint2:CGPointMake(290, 360)];

    [scissorPath addCurveToPoint:CGPointMake(500, 560)
                   controlPoint1:CGPointMake(290, 360)
                   controlPoint2:CGPointMake(500, 560)];

    [scissorPath addCurveToPoint:CGPointMake(750, 750)
                   controlPoint1:CGPointMake(500, 560)
                   controlPoint2:CGPointMake(720, 750)];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:[UIBezierPath complexShape1] andBeginsInside:nil];
    NSArray *otherIntersections = [[UIBezierPath complexShape1] findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)9, @"found 9 intersections");

    XCTAssertFalse([[intersections objectAtIndex:0] mayCrossBoundary], @"doesn't cross boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:3] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:4] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:5] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:6] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:7] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:8] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:3] location1] isNearTo:[[intersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:4] location1] isNearTo:[[intersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:5] location1] isNearTo:[[intersections objectAtIndex:5] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:6] location1] isNearTo:[[intersections objectAtIndex:6] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:7] location1] isNearTo:[[intersections objectAtIndex:7] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:8] location1] isNearTo:[[intersections objectAtIndex:8] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:3] location1] isNearTo:[[otherIntersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:4] location1] isNearTo:[[otherIntersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:5] location1] isNearTo:[[otherIntersections objectAtIndex:5] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:6] location1] isNearTo:[[otherIntersections objectAtIndex:6] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:7] location1] isNearTo:[[otherIntersections objectAtIndex:7] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:8] location1] isNearTo:[[otherIntersections objectAtIndex:8] location2]], @"locations match");
}


- (void)testStraightLineThroughNotchedRectangle
{
    // a simple straight line scissor
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 300)];
    [scissorPath addLineToPoint:CGPointMake(600, 300)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150, 200)];
    // first V through intersection
    [shapePath addLineToPoint:CGPointMake(200, 200)];
    [shapePath addLineToPoint:CGPointMake(250, 350)];
    [shapePath addLineToPoint:CGPointMake(300, 200)];
    // continue top
    [shapePath addLineToPoint:CGPointMake(550, 200)];
    [shapePath addLineToPoint:CGPointMake(550, 400)];
    // second vertical V through intersection
    [shapePath addLineToPoint:CGPointMake(500, 400)];
    [shapePath addLineToPoint:CGPointMake(450, 250)];
    [shapePath addLineToPoint:CGPointMake(400, 400)];
    [shapePath addLineToPoint:CGPointMake(150, 400)];
    [shapePath addLineToPoint:CGPointMake(150, 200)];
    [shapePath closePath];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)6, @"found intersections");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue1] to:6], (CGFloat)0.1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue1] to:6], (CGFloat)0.266667, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:2] tValue1] to:6], (CGFloat)0.333333, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:3] tValue1] to:6], (CGFloat)0.666667, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:4] tValue1] to:6], (CGFloat)0.733333, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:5] tValue1] to:6], (CGFloat)0.900000, @"found correct intersection location");

    for (DKUIBezierPathIntersectionPoint *inter in intersections) {
        XCTAssertTrue([otherIntersections containsObject:[inter flipped]], @"share all intersections");
    }
    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:3] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:4] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:5] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:3] location1] isNearTo:[[intersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:4] location1] isNearTo:[[intersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:5] location1] isNearTo:[[intersections objectAtIndex:5] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:3] location1] isNearTo:[[otherIntersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:4] location1] isNearTo:[[otherIntersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:5] location1] isNearTo:[[otherIntersections objectAtIndex:5] location2]], @"locations match");
}


- (void)testTangentThroughNotchedRectangle
{
    // a simple straight line scissor
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 300)];
    [scissorPath addLineToPoint:CGPointMake(600, 300)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150, 200)];
    // first V through intersection
    [shapePath addLineToPoint:CGPointMake(200, 200)];
    [shapePath addLineToPoint:CGPointMake(250, 300)];
    [shapePath addLineToPoint:CGPointMake(300, 200)];
    // continue top
    [shapePath addLineToPoint:CGPointMake(550, 200)];
    [shapePath addLineToPoint:CGPointMake(550, 400)];
    // second vertical V through intersection
    [shapePath addLineToPoint:CGPointMake(500, 400)];
    [shapePath addLineToPoint:CGPointMake(450, 300)];
    [shapePath addLineToPoint:CGPointMake(400, 400)];
    [shapePath addLineToPoint:CGPointMake(150, 400)];
    [shapePath addLineToPoint:CGPointMake(150, 200)];
    [shapePath closePath];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)4, @"found intersections");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue1] to:6], (CGFloat)0.1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue1] to:6], (CGFloat)0.3, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:2] tValue1] to:6], (CGFloat)0.7, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:3] tValue1] to:6], (CGFloat)0.9, @"found correct intersection location");

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue(![[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue(![[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:3] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:3] location1] isNearTo:[[intersections objectAtIndex:3] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:3] location1] isNearTo:[[otherIntersections objectAtIndex:3] location2]], @"locations match");
}


- (void)testTangentAcrossNotchedRectangle
{
    // a simple straight line scissor
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 200)];
    [scissorPath addLineToPoint:CGPointMake(600, 200)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150, 200)];
    // first V through intersection
    [shapePath addLineToPoint:CGPointMake(200, 200)];
    [shapePath addLineToPoint:CGPointMake(250, 300)];
    [shapePath addLineToPoint:CGPointMake(300, 200)];
    // continue top
    [shapePath addLineToPoint:CGPointMake(550, 200)];
    [shapePath addLineToPoint:CGPointMake(550, 400)];
    // second vertical V through intersection
    [shapePath addLineToPoint:CGPointMake(500, 400)];
    [shapePath addLineToPoint:CGPointMake(450, 300)];
    [shapePath addLineToPoint:CGPointMake(400, 400)];
    [shapePath addLineToPoint:CGPointMake(150, 400)];
    [shapePath addLineToPoint:CGPointMake(150, 200)];
    [shapePath closePath];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)4, @"found intersections");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue1] to:6], (CGFloat)0.1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue1] to:6], (CGFloat)0.2, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:2] tValue1] to:6], (CGFloat)0.4, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:3] tValue1] to:6], (CGFloat)0.9, @"found correct intersection location");

    for (DKUIBezierPathIntersectionPoint *inter in intersections) {
        XCTAssertTrue([otherIntersections containsObject:[inter flipped]], @"share all intersections");
    }

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:3] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:3] location1] isNearTo:[[intersections objectAtIndex:3] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:3] location1] isNearTo:[[otherIntersections objectAtIndex:3] location2]], @"locations match");
}


- (void)testTangentAcrossNotchedRectangleWithTangentPoint
{
    // a simple straight line scissor
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 200)];
    [scissorPath addLineToPoint:CGPointMake(600, 200)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150, 200)];
    // first V through intersection, creates point tangent
    [shapePath addLineToPoint:CGPointMake(250, 300)];
    [shapePath addLineToPoint:CGPointMake(300, 200)];
    // continue top
    [shapePath addLineToPoint:CGPointMake(550, 200)];
    [shapePath addLineToPoint:CGPointMake(550, 400)];
    // second vertical V through intersection
    [shapePath addLineToPoint:CGPointMake(500, 400)];
    [shapePath addLineToPoint:CGPointMake(450, 300)];
    [shapePath addLineToPoint:CGPointMake(400, 400)];
    [shapePath addLineToPoint:CGPointMake(150, 400)];
    [shapePath addLineToPoint:CGPointMake(150, 200)];
    [shapePath closePath];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)3, @"found intersections");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue1] to:6], (CGFloat)0.1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue1] to:6], (CGFloat)0.4, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:2] tValue1] to:6], (CGFloat)0.9, @"found correct intersection location");

    for (DKUIBezierPathIntersectionPoint *inter in intersections) {
        XCTAssertTrue([otherIntersections containsObject:[inter flipped]], @"share all intersections");
    }

    XCTAssertTrue(![[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
}


- (void)testLineThroughOval
{
    // a simple straight line scissor
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 300)];
    [scissorPath addLineToPoint:CGPointMake(600, 300)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150, 300)];
    [shapePath addCurveToPoint:CGPointMake(450, 300) controlPoint1:CGPointMake(150, 200) controlPoint2:CGPointMake(450, 200)];
    [shapePath addCurveToPoint:CGPointMake(150, 300) controlPoint1:CGPointMake(450, 400) controlPoint2:CGPointMake(150, 400)];
    [shapePath closePath];


    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)2, @"found intersections");

    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue1] to:6], (CGFloat)0.1, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue1] to:6], (CGFloat)0.7, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex2], 2, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue2] to:6], (CGFloat)1.0, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex2], 2, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue2] to:6], 0.0, @"found correct intersection location");

    XCTAssertEqual([[otherIntersections objectAtIndex:0] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:0] tValue1] to:6], (CGFloat)1.0, @"found correct intersection location");
    XCTAssertEqual([[otherIntersections objectAtIndex:1] elementIndex1], 2, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:1] tValue1] to:6], (CGFloat)1.0, @"found correct intersection location");
    XCTAssertEqual([[otherIntersections objectAtIndex:0] elementIndex2], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:0] tValue2] to:6], (CGFloat)0.7, @"found correct intersection location");
    XCTAssertEqual([[otherIntersections objectAtIndex:1] elementIndex2], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:1] tValue2] to:6], (CGFloat)0.1, @"found correct intersection location");

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
}


- (void)testLineThroughOvalFlattened
{
    // a simple straight line scissor
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 300)];
    [scissorPath addLineToPoint:CGPointMake(600, 300)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150, 300)];
    [shapePath addCurveToPoint:CGPointMake(450, 300) controlPoint1:CGPointMake(150, 200) controlPoint2:CGPointMake(450, 200)];
    [shapePath addCurveToPoint:CGPointMake(150, 300) controlPoint1:CGPointMake(450, 400) controlPoint2:CGPointMake(150, 400)];
    [shapePath closePath];


    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)2, @"found intersections");

    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue1] to:6], (CGFloat)0.1, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue1] to:6], (CGFloat)0.7, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex2], 2, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue2] to:6], (CGFloat)1.0, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex2], 2, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue2] to:6], 0.0, @"found correct intersection location");

    XCTAssertEqual([[otherIntersections objectAtIndex:0] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:0] tValue1] to:6], (CGFloat)1.0, @"found correct intersection location");
    XCTAssertEqual([[otherIntersections objectAtIndex:1] elementIndex1], 2, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:1] tValue1] to:6], (CGFloat)1.0, @"found correct intersection location");
    XCTAssertEqual([[otherIntersections objectAtIndex:0] elementIndex2], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:0] tValue2] to:6], (CGFloat)0.7, @"found correct intersection location");
    XCTAssertEqual([[otherIntersections objectAtIndex:1] elementIndex2], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:1] tValue2] to:6], (CGFloat)0.1, @"found correct intersection location");

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
}


- (void)testOffsetLineThroughOval
{
    // a simple straight line scissor
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 300)];
    [scissorPath addLineToPoint:CGPointMake(600, 300)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150, 310)];
    [shapePath addCurveToPoint:CGPointMake(450, 310) controlPoint1:CGPointMake(150, 210) controlPoint2:CGPointMake(450, 210)];
    [shapePath addCurveToPoint:CGPointMake(150, 310) controlPoint1:CGPointMake(450, 410) controlPoint2:CGPointMake(150, 410)];
    [shapePath closePath];


    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)2, @"found intersections");

    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue1] to:6], (CGFloat)0.102096, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex2], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue2] to:6], (CGFloat)0.034525, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue1] to:6], (CGFloat)0.697904, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex2], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue2] to:6], (CGFloat)0.965475, @"found correct intersection location");

    XCTAssertEqual([[otherIntersections objectAtIndex:0] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:0] tValue1] to:6], (CGFloat)0.034525, @"found correct intersection location");
    XCTAssertEqual([[otherIntersections objectAtIndex:0] elementIndex2], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:0] tValue2] to:6], (CGFloat)0.102096, @"found correct intersection location");
    XCTAssertEqual([[otherIntersections objectAtIndex:1] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:1] tValue1] to:6], (CGFloat)0.965475, @"found correct intersection location");
    XCTAssertEqual([[otherIntersections objectAtIndex:1] elementIndex2], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[otherIntersections objectAtIndex:1] tValue2] to:6], (CGFloat)0.697904, @"found correct intersection location");

    for (DKUIBezierPathIntersectionPoint *inter in intersections) {
        XCTAssertTrue([otherIntersections containsObject:[inter flipped]], @"share all intersections");
    }

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
}

- (void)testStraightLineThroughSingleNotchedRectangle
{
    // a simple straight line scissor
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 300)];
    [scissorPath addLineToPoint:CGPointMake(600, 300)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150, 200)];
    // first V through intersection
    [shapePath addLineToPoint:CGPointMake(200, 200)];
    [shapePath addLineToPoint:CGPointMake(250, 350)];
    [shapePath addLineToPoint:CGPointMake(300, 200)];
    // continue top
    [shapePath addLineToPoint:CGPointMake(550, 200)];
    [shapePath addLineToPoint:CGPointMake(550, 400)];
    [shapePath addLineToPoint:CGPointMake(150, 400)];
    [shapePath addLineToPoint:CGPointMake(150, 200)];
    [shapePath closePath];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)4, @"found intersections");

    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue1] to:6], (CGFloat)0.1, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex2], 7, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue2] to:6], (CGFloat)0.5, @"found correct intersection location");

    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue1] to:6], (CGFloat)0.266667, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex2], 2, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:1] tValue2] to:6], (CGFloat)0.666667, @"found correct intersection location");

    XCTAssertEqual([[intersections objectAtIndex:2] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:2] tValue1] to:6], (CGFloat)0.333333, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:2] elementIndex2], 3, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:2] tValue2] to:6], (CGFloat)0.333333, @"found correct intersection location");

    XCTAssertEqual([[intersections objectAtIndex:3] elementIndex1], 1, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:3] tValue1] to:6], (CGFloat)0.9, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:3] elementIndex2], 5, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:3] tValue2] to:6], (CGFloat)0.5, @"found correct intersection location");

    for (DKUIBezierPathIntersectionPoint *inter in intersections) {
        XCTAssertTrue([otherIntersections containsObject:[inter flipped]], @"share all intersections");
    }

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:3] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:3] location1] isNearTo:[[intersections objectAtIndex:3] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:3] location1] isNearTo:[[otherIntersections objectAtIndex:3] location2]], @"locations match");
}


- (void)testStraightLineThroughComplexShapeAnomaly
{
    // a simple straight line scissor
    // through the complex shape
    //
    // this will send a line straight through the complex shape
    // at a point where the shape has a small zigzag in it
    // that causes potentially duplicate intersection points.
    //
    // these intersections were being filtered out sometimes
    // causing 3 intersections output instead of 4.
    //
    // this test makes sure i track both the intersection
    // location and their distance along the path

    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(200, 1000)];
    [scissorPath addLineToPoint:CGPointMake(450, 710)];

    UIBezierPath *shapePath = [UIBezierPath complexShape1];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)4, @"found intersections");

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:3] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:3] location1] isNearTo:[[intersections objectAtIndex:3] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:3] location1] isNearTo:[[otherIntersections objectAtIndex:3] location2]], @"locations match");
}


- (void)testAwkwardScissorThroughComplexShape
{
    //
    // this is a very tricky case where the shape has a V in it
    // and the scissor slices through that very thin V, finding 2
    // intersections. but the 2 intersections are thought to be the
    // same b/c of rounding error, so it changes them to just 1.
    //
    // that might be ok if i treated that 1 intersection as a tangent,
    // but i don't believe i do, so it throws off the segment generation
    // later i believe.

    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(269.85718, 893.39087)];
    [scissorPath addCurveToPoint:CGPointMake(281.25815, 719.66113) controlPoint1:CGPointMake(269.72565, 768.16583) controlPoint2:CGPointMake(262.18225, 738.20679)];
    [scissorPath addCurveToPoint:CGPointMake(321.1615, 712.60956) controlPoint1:CGPointMake(293.37863, 710.72461) controlPoint2:CGPointMake(307.53641, 713.44592)];
    [scissorPath addCurveToPoint:CGPointMake(407.71021, 771.54443) controlPoint1:CGPointMake(398.63846, 747.31854) controlPoint2:CGPointMake(407.46439, 758.34375)];
    [scissorPath addCurveToPoint:CGPointMake(370.28271, 814.02014) controlPoint1:CGPointMake(386.05728, 802.76263) controlPoint2:CGPointMake(378.29507, 808.56891)];
    [scissorPath closePath];

    UIBezierPath *shapePath = [UIBezierPath complexShape1];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)6, @"found intersections");

    XCTAssertTrue([[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:3] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:4] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:5] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:3] location1] isNearTo:[[intersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:4] location1] isNearTo:[[intersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:5] location1] isNearTo:[[intersections objectAtIndex:5] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:3] location1] isNearTo:[[otherIntersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:4] location1] isNearTo:[[otherIntersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:5] location1] isNearTo:[[otherIntersections objectAtIndex:5] location2]], @"locations match");
}


- (void)testLotsOfExternalTangents
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300, 100)];
    [scissorPath addLineToPoint:CGPointMake(300, 800)];
    [scissorPath addLineToPoint:CGPointMake(200, 800)];
    [scissorPath addLineToPoint:CGPointMake(200, 100)];
    [scissorPath closePath];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(100, 300)];
    [shapePath addLineToPoint:CGPointMake(300, 300)];
    [shapePath addLineToPoint:CGPointMake(200, 500)];
    [shapePath addLineToPoint:CGPointMake(600, 500)];
    [shapePath addLineToPoint:CGPointMake(600, 800)];
    [shapePath addLineToPoint:CGPointMake(100, 800)];
    [shapePath closePath];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)6, @"found intersections");

    XCTAssertTrue(![[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue(![[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue(![[intersections objectAtIndex:3] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue(![[intersections objectAtIndex:4] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:5] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:3] location1] isNearTo:[[intersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:4] location1] isNearTo:[[intersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:5] location1] isNearTo:[[intersections objectAtIndex:5] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:3] location1] isNearTo:[[otherIntersections objectAtIndex:3] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:4] location1] isNearTo:[[otherIntersections objectAtIndex:4] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:5] location1] isNearTo:[[otherIntersections objectAtIndex:5] location2]], @"locations match");
}

- (void)testSingleExternalTangents
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300, 100)];
    [scissorPath addLineToPoint:CGPointMake(300, 900)];


    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(100, 300)];
    [shapePath addLineToPoint:CGPointMake(300, 300)];
    [shapePath addLineToPoint:CGPointMake(200, 500)];
    [shapePath addLineToPoint:CGPointMake(600, 500)];
    [shapePath addLineToPoint:CGPointMake(600, 800)];
    [shapePath addLineToPoint:CGPointMake(100, 800)];
    [shapePath closePath];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)3, @"found intersections");

    XCTAssertTrue(![[intersections objectAtIndex:0] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:1] mayCrossBoundary], @"crosses boundary");
    XCTAssertTrue([[intersections objectAtIndex:2] mayCrossBoundary], @"crosses boundary");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:1] location1] isNearTo:[[intersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[intersections objectAtIndex:2] location1] isNearTo:[[intersections objectAtIndex:2] location2]], @"locations match");

    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:1] location1] isNearTo:[[otherIntersections objectAtIndex:1] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:2] location1] isNearTo:[[otherIntersections objectAtIndex:2] location2]], @"locations match");
}


- (void)testSimpleCurveNextToSimpleCurvedShape
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(474.06448, 444.72607)];
    [scissorPath addCurveToPoint:CGPointMake(525.73999, 462.57001) controlPoint1:CGPointMake(492.95575, 451.31042) controlPoint2:CGPointMake(506.19031, 456.05344)];

    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(404.00003, 852.5)];
    [shapePath addCurveToPoint:CGPointMake(383.00003, 854) controlPoint1:CGPointMake(393.74905, 860.89905) controlPoint2:CGPointMake(387.84512, 858.07825)];
    [shapePath addCurveToPoint:CGPointMake(332.00003, 803) controlPoint1:CGPointMake(363.08359, 840.23792) controlPoint2:CGPointMake(347.37476, 821.42029)];
    [shapePath addCurveToPoint:CGPointMake(258.00003, 713) controlPoint1:CGPointMake(309.37256, 771.40741) controlPoint2:CGPointMake(285.08795, 740.91602)];
    [shapePath addCurveToPoint:CGPointMake(192.00003, 590) controlPoint1:CGPointMake(235.35789, 678.67316) controlPoint2:CGPointMake(186.18558, 638.5871)];
    [shapePath addLineToPoint:CGPointMake(192.00003, 590)];
    [shapePath addLineToPoint:CGPointMake(296, 510)];
    [shapePath addCurveToPoint:CGPointMake(295.00003, 438.00003) controlPoint1:CGPointMake(307.78754, 487.84625) controlPoint2:CGPointMake(306.79474, 460.05682)];
    [shapePath addCurveToPoint:CGPointMake(222.00003, 312) controlPoint1:CGPointMake(272.12451, 395.19107) controlPoint2:CGPointMake(245.84305, 354.29807)];
    [shapePath addCurveToPoint:CGPointMake(213.00002, 249.00002) controlPoint1:CGPointMake(211.81715, 292.51044) controlPoint2:CGPointMake(212.96744, 270.18738)];
    [shapePath addCurveToPoint:CGPointMake(320, 211.00002) controlPoint1:CGPointMake(228.65277, 205.46693) controlPoint2:CGPointMake(281.86935, 211.3221)];
    [shapePath addCurveToPoint:CGPointMake(498, 349.00003) controlPoint1:CGPointMake(390.99924, 235.61562) controlPoint2:CGPointMake(459.26001, 283.01178)];
    [shapePath addCurveToPoint:CGPointMake(503.00003, 383.00003) controlPoint1:CGPointMake(502.76978, 359.65356) controlPoint2:CGPointMake(504.42484, 371.5065)];
    [shapePath addCurveToPoint:CGPointMake(477, 439.00003) controlPoint1:CGPointMake(500.39777, 404.08139) controlPoint2:CGPointMake(486.43228, 420.80826)];
    [shapePath addCurveToPoint:CGPointMake(461.00003, 530) controlPoint1:CGPointMake(461.88455, 466.73669) controlPoint2:CGPointMake(457.76151, 498.98572)];
    [shapePath addCurveToPoint:CGPointMake(490.00003, 575) controlPoint1:CGPointMake(468.90933, 546.05383) controlPoint2:CGPointMake(478.66397, 561.17078)];
    [shapePath addCurveToPoint:CGPointMake(550, 642) controlPoint1:CGPointMake(510.01849, 597.32031) controlPoint2:CGPointMake(533.14478, 616.93121)];
    [shapePath addCurveToPoint:CGPointMake(601, 725) controlPoint1:CGPointMake(572.90356, 665.82397) controlPoint2:CGPointMake(583.8941, 697.40222)];
    [shapePath addCurveToPoint:CGPointMake(627.00006, 848) controlPoint1:CGPointMake(615.28241, 762.28046) controlPoint2:CGPointMake(639.95856, 806.46075)];
    [shapePath addLineToPoint:CGPointMake(627.00006, 848)];
    [shapePath addLineToPoint:CGPointMake(608, 870)];
    [shapePath addCurveToPoint:CGPointMake(404.00003, 852.5) controlPoint1:CGPointMake(539.55231, 889.62732) controlPoint2:CGPointMake(476.2829, 844.33203)];
    [shapePath closePath];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)1, @"found intersections");

    XCTAssertTrue([self point:[[intersections objectAtIndex:0] location1] isNearTo:[[intersections objectAtIndex:0] location2]], @"locations match");
    XCTAssertTrue([self point:[[otherIntersections objectAtIndex:0] location1] isNearTo:[[otherIntersections objectAtIndex:0] location2]], @"locations match");
}


- (void)testSquaredCircleIntersections
{
    UIBezierPath *shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath *scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)4, @"found intersections");
}

- (void)testComplexShapeWithInternalTangentLine
{
    UIBezierPath *shapePath = [UIBezierPath complexShape1];
    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(200, 301.7455)];
    [scissorPath addLineToPoint:CGPointMake(700, 301.7455)];

    NSArray *intersections1 = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];
    NSArray *intersections2 = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];

    XCTAssertEqual([intersections1 count], (NSUInteger)5, @"5 intersections so we can check for the tangent case");
    XCTAssertEqual([intersections2 count], (NSUInteger)5, @"5 intersections so we can check for the tangent case");
}

- (void)testLineThroughNearTangent
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(434, 139)];
    [path addCurveToPoint:CGPointMake(405, 136) controlPoint1:CGPointMake(419.31439, 138.24297) controlPoint2:CGPointMake(412.20261, 136.55988)];
    [path addCurveToPoint:CGPointMake(334, 159) controlPoint1:CGPointMake(379.15393, 131.06366) controlPoint2:CGPointMake(353.60638, 143.34953)];
    [path addCurveToPoint:CGPointMake(268, 242) controlPoint1:CGPointMake(308.45203, 183.46036) controlPoint2:CGPointMake(283.20477, 209.47534)];
    [path addCurveToPoint:CGPointMake(233, 481) controlPoint1:CGPointMake(228.24142, 315.83215) controlPoint2:CGPointMake(230.29984, 399.91275)];
    [path addCurveToPoint:CGPointMake(257, 553) controlPoint1:CGPointMake(234.57622, 506.81796) controlPoint2:CGPointMake(243.05113, 531.66156)];
    [path addCurveToPoint:CGPointMake(302, 585) controlPoint1:CGPointMake(264.3107, 570.68347) controlPoint2:CGPointMake(281.87143, 586.08862)];
    [path addCurveToPoint:CGPointMake(410, 569) controlPoint1:CGPointMake(338.89066, 591.18964) controlPoint2:CGPointMake(375.0018, 578.1427)];
    [path addCurveToPoint:CGPointMake(541, 561) controlPoint1:CGPointMake(448.95407, 567.50714) controlPoint2:CGPointMake(501.26468, 539.41791)];
    [path addCurveToPoint:CGPointMake(560, 569) controlPoint1:CGPointMake(545.36719, 568.49097) controlPoint2:CGPointMake(553.87787, 565.18091)];
    [path addCurveToPoint:CGPointMake(565, 406) controlPoint1:CGPointMake(583.72577, 524.01349) controlPoint2:CGPointMake(580.91907, 458.31393)];
    [path addCurveToPoint:CGPointMake(520, 377) controlPoint1:CGPointMake(555.8418, 389.33487) controlPoint2:CGPointMake(538.3692, 378.92123)];
    [path addCurveToPoint:CGPointMake(426, 362) controlPoint1:CGPointMake(489.28839, 369.62112) controlPoint2:CGPointMake(455.92944, 373.30957)];
    [path addCurveToPoint:CGPointMake(409, 344) controlPoint1:CGPointMake(418.1489, 358.60522) controlPoint2:CGPointMake(412.04929, 351.8891)];
    [path addCurveToPoint:CGPointMake(422, 257) controlPoint1:CGPointMake(407.73981, 314.5719) controlPoint2:CGPointMake(403.55063, 283.01636)];
    [path addCurveToPoint:CGPointMake(487, 159) controlPoint1:CGPointMake(433.01163, 217.17958) controlPoint2:CGPointMake(472.03311, 196.10237)];
    [path addLineToPoint:CGPointMake(487, 159)];
    [path addLineToPoint:CGPointMake(434, 139)];
    [path closePath];

    UIBezierPath *shapePath = path;


    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(221, 167.833)];
    [path addLineToPoint:CGPointMake(662, 463.833)];

    UIBezierPath *scissorPath = path;

    NSArray *intersections1 = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];
    NSArray *intersections2 = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];

    XCTAssertEqual([intersections1 count], (NSUInteger)3, @"intersections so we can check for the tangent case");
    XCTAssertEqual([intersections2 count], (NSUInteger)3, @"intersections so we can check for the tangent case");
}

- (void)testShapeWithLoop
{
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

    NSArray *intersections1 = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];
    NSArray *intersections2 = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];

    XCTAssertEqual([intersections1 count], (NSUInteger)4, @"intersections so we can check for the tangent case");
    XCTAssertEqual([intersections2 count], (NSUInteger)4, @"intersections so we can check for the tangent case");
}

- (void)testScissorWithSubpaths
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(620.783142, 484.064148)];
    [path addCurveToPoint:CGPointMake(597.000000, 488.000000) controlPoint1:CGPointMake(612.874512, 485.515564) controlPoint2:CGPointMake(604.941284, 486.818604)];
    [path addCurveToPoint:CGPointMake(409.000000, 502.000000) controlPoint1:CGPointMake(535.071350, 499.932739) controlPoint2:CGPointMake(471.676086, 498.750000)];
    [path addCurveToPoint:CGPointMake(220.665222, 519.890259) controlPoint1:CGPointMake(346.017273, 505.736145) controlPoint2:CGPointMake(283.259094, 512.045227)];
    [path addLineToPoint:CGPointMake(205.000046, 624.999939)];
    [path addCurveToPoint:CGPointMake(245.000031, 618.999878) controlPoint1:CGPointMake(218.530685, 625.288086) controlPoint2:CGPointMake(232.138092, 623.228394)];
    [path addCurveToPoint:CGPointMake(361.000031, 609.999878) controlPoint1:CGPointMake(282.913940, 609.217407) controlPoint2:CGPointMake(322.320343, 611.649658)];
    [path addCurveToPoint:CGPointMake(498.000031, 601.999878) controlPoint1:CGPointMake(406.743195, 608.775024) controlPoint2:CGPointMake(452.362152, 605.105835)];
    [path addCurveToPoint:CGPointMake(593.000000, 596.999939) controlPoint1:CGPointMake(529.735901, 601.523193) controlPoint2:CGPointMake(561.264526, 597.370117)];
    [path addCurveToPoint:CGPointMake(634.000061, 559.999878) controlPoint1:CGPointMake(621.450134, 606.875610) controlPoint2:CGPointMake(643.551392, 586.054749)];
    [path addCurveToPoint:CGPointMake(620.783142, 484.064148) controlPoint1:CGPointMake(627.813049, 534.893433) controlPoint2:CGPointMake(623.662170, 509.549316)];
    [path closePath];
    UIBezierPath *shapePath = path;

    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(325.000000, 685.000000)];
    [path addCurveToPoint:CGPointMake(325.326447, 508.398987) controlPoint1:CGPointMake(322.225037, 626.788940) controlPoint2:CGPointMake(321.756714, 567.465637)];
    [path moveToPoint:CGPointMake(339.770569, 382.814758)];
    [path addCurveToPoint:CGPointMake(433.000000, 125.000000) controlPoint1:CGPointMake(355.745178, 292.115295) controlPoint2:CGPointMake(384.615021, 204.432404)];
    [path addCurveToPoint:CGPointMake(461.000000, 108.000000) controlPoint1:CGPointMake(438.030334, 113.612007) controlPoint2:CGPointMake(449.595703, 107.629082)];
    [path addCurveToPoint:CGPointMake(487.000000, 197.000000) controlPoint1:CGPointMake(491.494110, 125.164238) controlPoint2:CGPointMake(483.883057, 169.148575)];
    [path addCurveToPoint:CGPointMake(484.000000, 375.000000) controlPoint1:CGPointMake(487.564270, 256.347900) controlPoint2:CGPointMake(486.092896, 315.694214)];
    [path addCurveToPoint:CGPointMake(484.009064, 376.793701) controlPoint1:CGPointMake(484.003174, 375.597900) controlPoint2:CGPointMake(484.006195, 376.195801)];
    [path moveToPoint:CGPointMake(483.251282, 499.150879)];
    [path addCurveToPoint:CGPointMake(487.000000, 732.000000) controlPoint1:CGPointMake(482.415894, 576.811340) controlPoint2:CGPointMake(481.856079, 654.491333)];
    UIBezierPath *scissorPath = path;

    NSArray *intersections1 = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];
    NSArray *intersections2 = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];

    XCTAssertEqual([intersections1 count], (NSUInteger)3, @"intersections so we can check for the tangent case");
    XCTAssertEqual([intersections2 count], (NSUInteger)3, @"intersections so we can check for the tangent case");
}

- (void)testZigZagLineThroughSloppyBox
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(324.500000, 214.500000)];
    [path addLineToPoint:CGPointMake(324.500000, 214.500000)];
    [path addLineToPoint:CGPointMake(308.000000, 330.000000)];
    [path addLineToPoint:CGPointMake(308.000000, 330.000000)];
    [path addLineToPoint:CGPointMake(417.000000, 330.000000)];
    [path addCurveToPoint:CGPointMake(440.000000, 241.000000) controlPoint1:CGPointMake(412.503845, 297.977478) controlPoint2:CGPointMake(427.308289, 269.161133)];
    [path addLineToPoint:CGPointMake(440.000000, 241.000000)];
    [path addLineToPoint:CGPointMake(324.500000, 214.500000)];
    [path closePath];

    UIBezierPath *shapePath = path;


    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(421.000000, 370.000000)];
    [path addCurveToPoint:CGPointMake(387.000000, 169.000000) controlPoint1:CGPointMake(394.666168, 309.850830) controlPoint2:CGPointMake(452.226837, 150.381851)];
    [path addCurveToPoint:CGPointMake(353.000000, 375.000000) controlPoint1:CGPointMake(320.444397, 187.997421) controlPoint2:CGPointMake(389.789246, 314.899323)];
    [path addCurveToPoint:CGPointMake(346.000000, 381.000000) controlPoint1:CGPointMake(351.378052, 377.649658) controlPoint2:CGPointMake(348.693909, 379.487122)];
    [path addCurveToPoint:CGPointMake(336.000000, 376.000000) controlPoint1:CGPointMake(342.446350, 379.722534) controlPoint2:CGPointMake(335.710663, 384.064972)];
    [path addCurveToPoint:CGPointMake(334.000000, 319.000000) controlPoint1:CGPointMake(334.906860, 357.017212) controlPoint2:CGPointMake(332.773987, 338.058167)];
    [path addCurveToPoint:CGPointMake(329.000000, 255.000000) controlPoint1:CGPointMake(334.787476, 297.469727) controlPoint2:CGPointMake(329.478668, 276.451782)];
    [path addCurveToPoint:CGPointMake(321.000000, 156.000000) controlPoint1:CGPointMake(326.492584, 221.951874) controlPoint2:CGPointMake(320.427063, 189.185196)];
    [path addLineToPoint:CGPointMake(321.000000, 156.000000)];
    [path addLineToPoint:CGPointMake(328.000000, 142.000000)];

    UIBezierPath *scissorPath = path;

    BOOL beginsInside = NO;
    NSArray *intersections1 = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    NSArray *intersections2 = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:&beginsInside];

    XCTAssertEqual([intersections1 count], (NSUInteger)6, @"intersections so we can check for the tangent case");
    XCTAssertEqual([intersections2 count], (NSUInteger)6, @"intersections so we can check for the tangent case");
}

- (void)testSquiggleThroughLongRectangle
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(127.500000, 121.000000)];
    [path addCurveToPoint:CGPointMake(119.000000, 126.000000) controlPoint1:CGPointMake(111.740646, 111.826790) controlPoint2:CGPointMake(117.062279, 122.276443)];
    [path addCurveToPoint:CGPointMake(115.000000, 156.000000) controlPoint1:CGPointMake(117.584236, 135.994080) controlPoint2:CGPointMake(117.569023, 146.173431)];
    [path addCurveToPoint:CGPointMake(111.000000, 179.000000) controlPoint1:CGPointMake(112.933540, 163.542007) controlPoint2:CGPointMake(112.493446, 171.356430)];
    [path addCurveToPoint:CGPointMake(110.000000, 189.000000) controlPoint1:CGPointMake(112.509949, 182.632477) controlPoint2:CGPointMake(108.890198, 185.432465)];
    [path addCurveToPoint:CGPointMake(119.000000, 189.000000) controlPoint1:CGPointMake(112.999985, 188.999985) controlPoint2:CGPointMake(116.000008, 189.000015)];
    [path addCurveToPoint:CGPointMake(147.000000, 189.000000) controlPoint1:CGPointMake(128.333328, 189.000000) controlPoint2:CGPointMake(137.666656, 189.000000)];
    [path addCurveToPoint:CGPointMake(196.000000, 189.000000) controlPoint1:CGPointMake(163.333282, 188.999939) controlPoint2:CGPointMake(179.666687, 189.000031)];
    [path addCurveToPoint:CGPointMake(264.000000, 189.000000) controlPoint1:CGPointMake(218.666733, 189.000061) controlPoint2:CGPointMake(241.333298, 188.999969)];
    [path addCurveToPoint:CGPointMake(343.000000, 191.000000) controlPoint1:CGPointMake(290.302979, 191.183914) controlPoint2:CGPointMake(316.693359, 188.843384)];
    [path addCurveToPoint:CGPointMake(441.000000, 192.000000) controlPoint1:CGPointMake(375.639862, 192.948700) controlPoint2:CGPointMake(408.334991, 191.561615)];
    [path addCurveToPoint:CGPointMake(545.000000, 194.000000) controlPoint1:CGPointMake(475.642548, 194.206146) controlPoint2:CGPointMake(510.354370, 191.825272)];
    [path addCurveToPoint:CGPointMake(644.000000, 197.000000) controlPoint1:CGPointMake(577.913574, 197.956650) controlPoint2:CGPointMake(611.022339, 194.519608)];
    [path addCurveToPoint:CGPointMake(727.000000, 202.000000) controlPoint1:CGPointMake(671.580994, 200.227661) controlPoint2:CGPointMake(699.413574, 198.835251)];
    [path addCurveToPoint:CGPointMake(907.000000, 201.000000) controlPoint1:CGPointMake(784.276306, 190.771973) controlPoint2:CGPointMake(852.270386, 222.807465)];
    [path addCurveToPoint:CGPointMake(908.000000, 196.000000) controlPoint1:CGPointMake(908.796021, 200.284348) controlPoint2:CGPointMake(908.923218, 197.582565)];
    [path addCurveToPoint:CGPointMake(910.000000, 175.000000) controlPoint1:CGPointMake(907.313416, 188.906937) controlPoint2:CGPointMake(910.008484, 182.067001)];
    [path addCurveToPoint:CGPointMake(913.000000, 146.000000) controlPoint1:CGPointMake(910.472778, 165.276352) controlPoint2:CGPointMake(912.353943, 155.706558)];
    [path addCurveToPoint:CGPointMake(916.000000, 127.000000) controlPoint1:CGPointMake(913.647400, 139.617294) controlPoint2:CGPointMake(914.649536, 133.271133)];
    [path addCurveToPoint:CGPointMake(916.000000, 122.000000) controlPoint1:CGPointMake(916.000000, 125.333336) controlPoint2:CGPointMake(916.000000, 123.666664)];
    [path addCurveToPoint:CGPointMake(904.000000, 120.000000) controlPoint1:CGPointMake(916.959106, 116.651031) controlPoint2:CGPointMake(904.744141, 124.911003)];
    [path addCurveToPoint:CGPointMake(871.000000, 118.000000) controlPoint1:CGPointMake(893.073486, 118.518951) controlPoint2:CGPointMake(882.046326, 117.385658)];
    [path addCurveToPoint:CGPointMake(817.000000, 116.000000) controlPoint1:CGPointMake(853.045105, 115.811974) controlPoint2:CGPointMake(834.960388, 118.160645)];
    [path addCurveToPoint:CGPointMake(747.000000, 114.000000) controlPoint1:CGPointMake(793.654297, 115.632294) controlPoint2:CGPointMake(770.373535, 112.968056)];
    [path addCurveToPoint:CGPointMake(671.000000, 112.000000) controlPoint1:CGPointMake(721.696838, 111.823479) controlPoint2:CGPointMake(696.303162, 114.176529)];
    [path addCurveToPoint:CGPointMake(595.000000, 109.000000) controlPoint1:CGPointMake(645.780273, 108.040375) controlPoint2:CGPointMake(620.304993, 111.479752)];
    [path addCurveToPoint:CGPointMake(519.000000, 108.000000) controlPoint1:CGPointMake(569.697021, 107.147278) controlPoint2:CGPointMake(544.332947, 108.353180)];
    [path addCurveToPoint:CGPointMake(439.000000, 108.000000) controlPoint1:CGPointMake(492.333344, 108.000000) controlPoint2:CGPointMake(465.666687, 108.000000)];
    [path addCurveToPoint:CGPointMake(361.000000, 109.000000) controlPoint1:CGPointMake(413.001434, 108.396584) controlPoint2:CGPointMake(386.966797, 107.074242)];
    [path addCurveToPoint:CGPointMake(289.000000, 109.000000) controlPoint1:CGPointMake(337.000000, 109.000000) controlPoint2:CGPointMake(313.000000, 109.000000)];
    [path addCurveToPoint:CGPointMake(127.500000, 121.000000) controlPoint1:CGPointMake(236.254852, 109.084534) controlPoint2:CGPointMake(176.274368, 149.390594)];
    [path closePath];

    UIBezierPath *shapePath = path;

    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(185.000000, 85.000000)];
    [path addLineToPoint:CGPointMake(185.000000, 85.000000)];
    [path addLineToPoint:CGPointMake(179.000000, 201.000000)];
    [path addCurveToPoint:CGPointMake(199.000000, 208.000000) controlPoint1:CGPointMake(183.169250, 207.988388) controlPoint2:CGPointMake(191.811218, 210.232590)];
    [path addCurveToPoint:CGPointMake(240.000000, 167.000000) controlPoint1:CGPointMake(218.260406, 201.410797) controlPoint2:CGPointMake(226.571762, 180.229294)];
    [path addCurveToPoint:CGPointMake(281.000000, 110.000000) controlPoint1:CGPointMake(254.023346, 148.253647) controlPoint2:CGPointMake(266.453552, 128.362030)];
    [path addCurveToPoint:CGPointMake(321.000000, 82.000000) controlPoint1:CGPointMake(289.584106, 98.633614) controlPoint2:CGPointMake(303.611298, 80.088783)];
    [path addLineToPoint:CGPointMake(321.000000, 82.000000)];
    [path addLineToPoint:CGPointMake(349.000000, 204.000000)];
    [path addCurveToPoint:CGPointMake(379.000000, 219.000000) controlPoint1:CGPointMake(355.820831, 214.351547) controlPoint2:CGPointMake(367.497803, 219.492905)];
    [path addCurveToPoint:CGPointMake(424.000000, 196.000000) controlPoint1:CGPointMake(397.342316, 222.437271) controlPoint2:CGPointMake(413.514099, 209.252762)];
    [path addCurveToPoint:CGPointMake(471.000000, 126.000000) controlPoint1:CGPointMake(444.182159, 175.710922) controlPoint2:CGPointMake(453.117493, 147.947327)];
    [path addCurveToPoint:CGPointMake(537.000000, 75.000000) controlPoint1:CGPointMake(486.431824, 107.937866) controlPoint2:CGPointMake(507.281738, 70.157906)];
    [path addCurveToPoint:CGPointMake(545.000000, 88.000000) controlPoint1:CGPointMake(543.005005, 75.978416) controlPoint2:CGPointMake(545.940125, 82.543968)];
    [path addCurveToPoint:CGPointMake(545.000000, 142.000000) controlPoint1:CGPointMake(546.712952, 105.950813) controlPoint2:CGPointMake(546.324829, 124.040375)];
    [path addCurveToPoint:CGPointMake(560.000000, 217.000000) controlPoint1:CGPointMake(550.012024, 165.627167) controlPoint2:CGPointMake(532.225525, 199.793015)];
    [path addCurveToPoint:CGPointMake(594.000000, 223.000000) controlPoint1:CGPointMake(570.120972, 223.270233) controlPoint2:CGPointMake(582.546997, 223.506073)];
    [path addCurveToPoint:CGPointMake(661.000000, 157.000000) controlPoint1:CGPointMake(624.375000, 210.730530) controlPoint2:CGPointMake(642.187439, 182.167542)];
    [path addCurveToPoint:CGPointMake(727.000000, 85.000000) controlPoint1:CGPointMake(683.615417, 135.833450) controlPoint2:CGPointMake(693.794373, 92.635178)];
    [path addCurveToPoint:CGPointMake(749.000000, 93.000000) controlPoint1:CGPointMake(732.356323, 83.768387) controlPoint2:CGPointMake(752.187988, 77.657463)];
    [path addCurveToPoint:CGPointMake(750.000000, 160.000000) controlPoint1:CGPointMake(750.542664, 115.286949) controlPoint2:CGPointMake(749.837524, 137.660080)];
    [path addCurveToPoint:CGPointMake(767.000000, 218.000000) controlPoint1:CGPointMake(749.102722, 176.247742) controlPoint2:CGPointMake(744.132019, 214.832230)];
    [path addCurveToPoint:CGPointMake(899.000000, 96.000000) controlPoint1:CGPointMake(834.042908, 227.287048) controlPoint2:CGPointMake(843.633057, 56.858723)];
    [path addCurveToPoint:CGPointMake(921.000000, 210.000000) controlPoint1:CGPointMake(930.653442, 118.377151) controlPoint2:CGPointMake(891.765564, 177.428665)];
    [path addLineToPoint:CGPointMake(921.000000, 210.000000)];
    [path addLineToPoint:CGPointMake(972.000000, 255.000000)];

    UIBezierPath *scissorPath = path;

    BOOL beginsInside = NO;
    NSArray *intersections1 = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    NSArray *intersections2 = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:&beginsInside];

    XCTAssertEqual([intersections1 count], (NSUInteger)18, @"intersections so we can check for the tangent case");
    XCTAssertEqual([intersections2 count], (NSUInteger)18, @"intersections so we can check for the tangent case");
}

- (void)testLineIntersectsCubic
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(321, 82)];
    [path addLineToPoint:CGPointMake(349, 204)];

    UIBezierPath *shapePath = path;

    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(361, 109)];
    [path addCurveToPoint:CGPointMake(289, 109) controlPoint1:CGPointMake(337, 109) controlPoint2:CGPointMake(313, 109)];

    UIBezierPath *scissorPath = path;

    BOOL beginsInside = NO;
    NSArray *intersections1 = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    NSArray *intersections2 = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:&beginsInside];

    XCTAssertEqual([intersections1 count], (NSUInteger)1, @"intersections so we can check for the tangent case");
    XCTAssertEqual([intersections2 count], (NSUInteger)1, @"intersections so we can check for the tangent case");
}

- (void)testSimpleHoleInRectangle
{
    UIBezierPath *path;
    path = [UIBezierPath bezierPathWithRect:CGRectMake(100, 100, 600, 400)];
    [path appendPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(150, 150, 200, 200)] bezierPathByReversingPath]];
    UIBezierPath *shapePath = path;

    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(175, 800)];
    [path addLineToPoint:CGPointMake(175, 50)];
    UIBezierPath *scissorPath = path;

    BOOL beginsInside = NO;
    NSArray *intersections1 = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    NSArray *intersections2 = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:&beginsInside];

    XCTAssertEqual([intersections1 count], (NSUInteger)4, @"intersections so we can check for the tangent case");
    XCTAssertEqual([intersections2 count], (NSUInteger)4, @"intersections so we can check for the tangent case");
}

- (void)testTangentToHoleInRectangle
{
    UIBezierPath *path;
    path = [UIBezierPath bezierPathWithRect:CGRectMake(100, 100, 600, 400)];
    [path appendPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(150, 150, 200, 200)] bezierPathByReversingPath]];
    UIBezierPath *shapePath = path;

    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(150, 800)];
    [path addLineToPoint:CGPointMake(150, 50)];
    UIBezierPath *scissorPath = path;

    NSArray *intersections1 = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];
    NSArray *intersections2 = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];

    XCTAssertEqual([intersections1 count], (NSUInteger)3, @"intersections so we can check for the tangent case");
    XCTAssertEqual([intersections2 count], (NSUInteger)3, @"intersections so we can check for the tangent case");
}

- (void)testScissorsCreatingHole
{
    UIBezierPath *scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)];

    UIBezierPath *shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];

    BOOL beginsInside = NO;
    NSArray *intersections1 = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    NSArray *intersections2 = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:&beginsInside];

    XCTAssertEqual([intersections1 count], (NSUInteger)0, @"intersections so we can check for the tangent case");
    XCTAssertEqual([intersections2 count], (NSUInteger)0, @"intersections so we can check for the tangent case");
}

- (void)testDrawnScissorsCreatingHole
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(196.085602, 247.683899)];
    [path addCurveToPoint:CGPointMake(518.999939, 253.999939) controlPoint1:CGPointMake(270.145935, 282.188782) controlPoint2:CGPointMake(463.317017, 200.644287)];
    [path addCurveToPoint:CGPointMake(510.000000, 647.000000) controlPoint1:CGPointMake(496.792603, 382.674805) controlPoint2:CGPointMake(502.925476, 517.541626)];
    [path addCurveToPoint:CGPointMake(427.999969, 659.999939) controlPoint1:CGPointMake(483.820770, 657.256348) controlPoint2:CGPointMake(455.160248, 654.878540)];
    [path addCurveToPoint:CGPointMake(302.000000, 671.999939) controlPoint1:CGPointMake(385.977142, 663.402283) controlPoint2:CGPointMake(343.752563, 665.726318)];
    [path addCurveToPoint:CGPointMake(181.000031, 692.000000) controlPoint1:CGPointMake(261.176727, 675.663452) controlPoint2:CGPointMake(221.829315, 688.545044)];
    [path addCurveToPoint:CGPointMake(125.000015, 701.000000) controlPoint1:CGPointMake(161.059967, 688.420532) controlPoint2:CGPointMake(143.938034, 699.357910)];
    [path addCurveToPoint:CGPointMake(119.000008, 665.999939) controlPoint1:CGPointMake(104.217941, 707.529663) controlPoint2:CGPointMake(121.172516, 674.727112)];
    [path addCurveToPoint:CGPointMake(196.085602, 247.683899) controlPoint1:CGPointMake(158.682663, 528.713684) controlPoint2:CGPointMake(138.724899, 381.213013)];
    [path closePath];
    UIBezierPath *shapePath = path;


    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(267.307678, 387.000000)];
    [path addLineToPoint:CGPointMake(267.307678, 387.000000)];
    [path addLineToPoint:CGPointMake(396.000000, 381.000000)];
    [path addLineToPoint:CGPointMake(396.000000, 381.000000)];
    [path addLineToPoint:CGPointMake(384.000000, 585.000000)];
    [path addCurveToPoint:CGPointMake(375.000000, 587.000000) controlPoint1:CGPointMake(382.235931, 588.528870) controlPoint2:CGPointMake(377.849335, 588.849365)];
    [path addCurveToPoint:CGPointMake(353.000000, 583.000000) controlPoint1:CGPointMake(367.851257, 584.742798) controlPoint2:CGPointMake(360.167114, 585.259399)];
    [path addCurveToPoint:CGPointMake(303.000000, 580.000000) controlPoint1:CGPointMake(336.341034, 581.878723) controlPoint2:CGPointMake(319.680664, 580.755920)];
    [path addCurveToPoint:CGPointMake(257.000000, 577.000000) controlPoint1:CGPointMake(287.847992, 576.041077) controlPoint2:CGPointMake(272.279388, 579.514587)];
    [path addCurveToPoint:CGPointMake(228.000000, 557.000000) controlPoint1:CGPointMake(248.341064, 574.169495) controlPoint2:CGPointMake(211.572083, 583.869507)];
    [path addLineToPoint:CGPointMake(228.000000, 557.000000)];
    [path addLineToPoint:CGPointMake(267.307678, 387.000000)];
    [path closePath];
    UIBezierPath *scissorPath = path;

    BOOL beginsInside = NO;
    NSArray *intersections1 = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    NSArray *intersections2 = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:&beginsInside];

    XCTAssertEqual([intersections1 count], (NSUInteger)0, @"intersections so we can check for the tangent case");
    XCTAssertEqual([intersections2 count], (NSUInteger)0, @"intersections so we can check for the tangent case");
}

- (void)testLineNearBoundary
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
    [scissorPath moveToPoint:CGPointMake(493.500000, 1024.000000)];
    [scissorPath addCurveToPoint:CGPointMake(495.500000, 1024.000000) controlPoint1:CGPointMake(494.250000, 1024.000000) controlPoint2:CGPointMake(494.750000, 1024.000000)];


    BOOL beginsInside = NO;
    NSArray *scissorToShapeIntersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    NSArray *shapeToScissorIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:&beginsInside];

    XCTAssertEqual([scissorToShapeIntersections count], [shapeToScissorIntersections count], @"count of intersections matches");
    XCTAssertEqual([scissorToShapeIntersections count], (NSUInteger)2, @"count of intersections matches");
}

- (void)testCircleThroughRectangleCompareTangents2
{
    UIBezierPath *shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath *scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];

    NSArray *intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:nil];
    NSArray *otherIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:nil];

    XCTAssertEqual([intersections count], [otherIntersections count], @"found intersections");
    XCTAssertEqual([intersections count], (NSUInteger)3, @"found intersections");

    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex1], 2, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue1] to:6], 1.0, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:0] elementIndex2], 4, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:0] tValue2] to:6], 0.0, @"found correct intersection location");

    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex1], 3, @"found correct intersection location");
    XCTAssertEqualWithAccuracy([[intersections objectAtIndex:1] tValue1], 1.0, 0.000001);
    XCTAssertEqual([[intersections objectAtIndex:1] elementIndex2], 1, @"found correct intersection location");
    XCTAssertEqualWithAccuracy([[intersections objectAtIndex:1] tValue2], 0.5, 0.000002);

    XCTAssertEqual([[intersections objectAtIndex:2] elementIndex1], 4, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:2] tValue1] to:6], 0.999997, @"found correct intersection location");
    XCTAssertEqual([[intersections objectAtIndex:2] elementIndex2], 2, @"found correct intersection location");
    XCTAssertEqual([self round:[[intersections objectAtIndex:2] tValue2] to:6], 0.999998, @"found correct intersection location");

    DKUIBezierPathIntersectionPoint *intersection = [intersections objectAtIndex:0];
    XCTAssertEqual(roundf([intersection location1].x), 200.0, @"intersects at the right place");
    XCTAssertEqual(roundf([intersection location1].y), 300.0, @"intersects at the right place");

    intersection = [intersections objectAtIndex:1];
    XCTAssertTrue([self point:intersection.location1 isNearTo:CGPointMake(300, 200)], @"correct location");

    intersection = [intersections objectAtIndex:2];
    XCTAssertTrue([self point:intersection.location1 isNearTo:CGPointMake(400, 300)], @"correct location");

    intersection = [otherIntersections objectAtIndex:0];
    XCTAssertTrue([self point:intersection.location1 isNearTo:CGPointMake(300, 200)], @"correct location");

    intersection = [otherIntersections objectAtIndex:1];
    XCTAssertTrue([self point:intersection.location1 isNearTo:CGPointMake(400, 300)], @"correct location");

    intersection = [otherIntersections objectAtIndex:2];
    XCTAssertTrue([self point:intersection.location1 isNearTo:CGPointMake(200, 300)], @"correct location");
}

- (void)testQuadraticIntersections1
{
    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(100, 100)];
    [shapePath addQuadCurveToPoint:CGPointMake(200, 100) controlPoint:CGPointMake(150, 250)];

    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 200)];
    [scissorPath addQuadCurveToPoint:CGPointMake(200, 200) controlPoint:CGPointMake(150, 50)];

    BOOL beginsInside = NO;
    NSArray<DKUIBezierPathIntersectionPoint *> *scissorToShapeIntersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    NSArray<DKUIBezierPathIntersectionPoint *> *shapeToScissorIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:&beginsInside];

    XCTAssertEqual([scissorToShapeIntersections count], [shapeToScissorIntersections count], @"count of intersections matches");
    XCTAssertEqual([shapeToScissorIntersections count], (NSUInteger)2, @"count of intersections matches");

    XCTAssertEqual([[scissorToShapeIntersections objectAtIndex:0] elementIndex1], 1);
    XCTAssertEqualWithAccuracy([[scissorToShapeIntersections objectAtIndex:0] tValue1], 0.211324864211, 0.000001);
    XCTAssertEqual([[scissorToShapeIntersections objectAtIndex:0] elementIndex2], 1);
    XCTAssertEqualWithAccuracy([[scissorToShapeIntersections objectAtIndex:0] tValue2], 0.211324869337, 0.000001);
    XCTAssertEqual([[scissorToShapeIntersections objectAtIndex:1] elementIndex1], 1);
    XCTAssertEqualWithAccuracy([[scissorToShapeIntersections objectAtIndex:1] tValue1], 0.788675135789, 0.000001);
    XCTAssertEqual([[scissorToShapeIntersections objectAtIndex:1] elementIndex2], 1);
    XCTAssertEqualWithAccuracy([[scissorToShapeIntersections objectAtIndex:1] tValue2], 0.788675130663, 0.000001);
}

- (void)testQuadraticIntersections2
{
    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(100, 100)];
    [shapePath addQuadCurveToPoint:CGPointMake(200, 100) controlPoint:CGPointMake(150, 250)];

    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(80, 200)];
    [scissorPath addQuadCurveToPoint:CGPointMake(200, 50) controlPoint:CGPointMake(150, 50)];

    BOOL beginsInside = NO;
    NSArray<DKUIBezierPathIntersectionPoint *> *scissorToShapeIntersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    NSArray<DKUIBezierPathIntersectionPoint *> *shapeToScissorIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:&beginsInside];

    XCTAssertEqual([scissorToShapeIntersections count], [shapeToScissorIntersections count], @"count of intersections matches");
    XCTAssertEqual([shapeToScissorIntersections count], (NSUInteger)1, @"count of intersections matches");

    XCTAssertEqual([[scissorToShapeIntersections objectAtIndex:0] elementIndex1], 1);
    XCTAssertEqualWithAccuracy([[scissorToShapeIntersections objectAtIndex:0] tValue1], 0.247638207846, 0.000001);
    XCTAssertEqual([[scissorToShapeIntersections objectAtIndex:0] elementIndex2], 1);
    XCTAssertEqualWithAccuracy([[scissorToShapeIntersections objectAtIndex:0] tValue2], 0.134428499067, 0.000001);
}

- (void)testQuadraticIntersections3
{
    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(100, 100)];
    [shapePath addQuadCurveToPoint:CGPointMake(200, 100) controlPoint:CGPointMake(150, 200)];

    UIBezierPath *scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 200)];
    [scissorPath addQuadCurveToPoint:CGPointMake(200, 200) controlPoint:CGPointMake(150, 100)];

    BOOL beginsInside = NO;
    NSArray<DKUIBezierPathIntersectionPoint *> *scissorToShapeIntersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    NSArray<DKUIBezierPathIntersectionPoint *> *shapeToScissorIntersections = [shapePath findIntersectionsWithClosedPath:scissorPath andBeginsInside:&beginsInside];

    XCTAssertEqual([scissorToShapeIntersections count], [shapeToScissorIntersections count], @"count of intersections matches");
    XCTAssertEqual([shapeToScissorIntersections count], (NSUInteger)1, @"count of intersections matches");

    XCTAssertEqual([[scissorToShapeIntersections objectAtIndex:0] elementIndex1], 1);
    XCTAssertEqualWithAccuracy([[scissorToShapeIntersections objectAtIndex:0] tValue1], 0.5, 0.000001);
    XCTAssertEqual([[scissorToShapeIntersections objectAtIndex:0] elementIndex2], 1);
    XCTAssertEqualWithAccuracy([[scissorToShapeIntersections objectAtIndex:0] tValue2], 0.5, 0.000001);
}

@end

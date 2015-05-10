//
//  DrawKitiOSClippingSegmentTangentTests.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 11/21/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DrawKitiOSAbstractTest.h"
#import <ClippingBezier/ClippingBezier.h>
#import <PerformanceBezier/PerformanceBezier.h>
#import <ClippingBezier/UIBezierPath+Clipping_Private.h>

@interface DrawKitiOSClippingSegmentTangentTests : DrawKitiOSAbstractTest

@end

@implementation DrawKitiOSClippingSegmentTangentTests

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

-(void) testIntersectionOfHorizontalPath{
    
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(0, 50)];
    [scissorPath addLineToPoint:CGPointMake(200, 90)];
    
    // this square starts halfway through the left side,
    // where it intersections with the line
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(50, 50)];
    [shapePath addLineToPoint:CGPointMake(50, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 150)];
    [shapePath addLineToPoint:CGPointMake(50, 150)];
    [shapePath closePath];

    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];

    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}


-(void) testIntersectionOfHorizontalPathWithReversedShape{
    
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(0, 50)];
    [scissorPath addLineToPoint:CGPointMake(200, 90)];
    
    // this square starts halfway through the left side,
    // where it intersections with the line
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(50, 50)];
    [shapePath addLineToPoint:CGPointMake(50, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 150)];
    [shapePath addLineToPoint:CGPointMake(50, 150)];
    [shapePath closePath];
    shapePath = [shapePath bezierPathByReversingPath];
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] < 0, @"angle is left turn");
    }
}


-(void) testUIBezierTangentNearT{
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(100, 100)];
    [bezierPath addLineToPoint:CGPointMake(150, 100)];
    [bezierPath addLineToPoint:CGPointMake(200, 100)];
    
    DKTangentAtPoint* tan = [bezierPath tangentNearStart];
    
    XCTAssertTrue([self checkTanPoint:distance(CGPointMake(100.0f, 100.0f), tan.point) isLessThan:[UIBezierPath maxDistForEndPointTangents]], @"good rounding error for tangent ends");
    
    tan = [bezierPath tangentNearEnd];
    
    XCTAssertTrue([self checkTanPoint:distance(CGPointMake(200.0f, 100.0f), tan.point) isLessThan:[UIBezierPath maxDistForEndPointTangents]], @"good rounding error for tangent ends");
}



-(void) testCircleThroughRectangleFirstSegmentTangent{
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is clockwise");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}


-(void) testCircleThroughReversedRectangleFirstSegmentTangent{
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    shapePath = [shapePath bezierPathByReversingPath];
    
    XCTAssertTrue(![shapePath isClockwise], @"shape is clockwise");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] < 0, @"angle is left turn");
    }
}

-(void) testIntersectionAtT1{
    
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(0, 50)];
    [scissorPath addLineToPoint:CGPointMake(50, 50)];
    [scissorPath addLineToPoint:CGPointMake(150, 50)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(50, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 150)];
    [shapePath addLineToPoint:CGPointMake(50, 150)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testIntersectionAtT0{
    //
    // this test square
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(50, 50)];
    [scissorPath addLineToPoint:CGPointMake(150, 50)];
    [scissorPath addLineToPoint:CGPointMake(250, 50)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(50, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 150)];
    [shapePath addLineToPoint:CGPointMake(50, 150)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testIntersectionAtT0OfCurve{
    
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(50, 50)];
    [scissorPath addLineToPoint:CGPointMake(250, 50)];
    
    // this square starts halfway through the left side,
    // where it intersections with the line
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(50, 50)];
    [shapePath addLineToPoint:CGPointMake(50, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 150)];
    [shapePath addLineToPoint:CGPointMake(50, 150)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testScissorAtShapeBeginningWithComplexShape2{
    // this is a long unclosed scissor path that cuts first
    // through the exact start of the closed shape
    //
    // this is different than testScissorAtShapeBeginningWithComplexShape
    // in that the approach to the first intersection is not
    // near-tangent to the curve.
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(210.500000,386.000000)];
    [scissorPath addLineToPoint:CGPointMake(218.500000,376.000000)];
    [scissorPath addCurveToPoint:CGPointMake(229.500000,376.000000)
                   controlPoint1:CGPointMake(210.500000,376.000000)
                   controlPoint2:CGPointMake(229.500000,376.000000)];
    [scissorPath addCurveToPoint:CGPointMake(290, 360)
                   controlPoint1:CGPointMake(229.500000,376.000000)
                   controlPoint2:CGPointMake(290, 360)];
    
    [scissorPath addCurveToPoint:CGPointMake(500, 560)
                   controlPoint1:CGPointMake(290, 360)
                   controlPoint2:CGPointMake(500, 560)];
    
    [scissorPath addCurveToPoint:CGPointMake(750, 750)
                   controlPoint1:CGPointMake(500, 560)
                   controlPoint2:CGPointMake(720, 750)];
    
    UIBezierPath* shapePath = self.complexShape;
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");


    //
    //
    // This is the tricky piece of this test!
    // the turn from this red segment is visually a right turn, but
    // the beginning of the path has a knot that makes it mathematically
    // a left turn.
    //
    // this algorithm makes sure to still find the correct blue segment
    redSegment = [redSegments objectAtIndex:4];
    currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] < 0, @"angle is left turn");
}

-(void) testIntersectionSplittingLineElement{
    
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(0, 350)];
    [scissorPath addLineToPoint:CGPointMake(150, 350)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(50, 300)];
    [shapePath addLineToPoint:CGPointMake(150, 300)];
    [shapePath addLineToPoint:CGPointMake(150, 450)];
    [shapePath addLineToPoint:CGPointMake(50, 450)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}



-(void) testSquaredCircleIntersections{
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is clockwise");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testRectangleScissorsThroughCircleShape{
    // here, the scissor is a square that contains a circle shape
    // the square wraps around the outside of the circle
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(100, 250, 400, 100)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testClippingVerticalOvalThroughHorizontalRectangle{
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 100, 200, 400)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(100, 200, 400, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");

    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testClippingReversedVerticalOvalThroughHorizontalRectangle{
    UIBezierPath* scissorPath = [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 100, 200, 400)] bezierPathByReversingPath];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(100, 200, 400, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");

    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testClippingVerticalOvalThroughReversedHorizontalRectangle{
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 100, 200, 400)];
    UIBezierPath* shapePath = [[UIBezierPath bezierPathWithRect:CGRectMake(100, 200, 400, 200)] bezierPathByReversingPath];
    
    XCTAssertTrue(![shapePath isClockwise], @"shape is correct direction");

    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] < 0, @"angle is left turn");
    }
}

//
// https://github.com/adamwulf/loose-leaf/issues/296
// the scissor begins slicing at its begin/end point
-(void) testRectangleThatSlicesThroughRectangleAtEndpoint{
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(200, 300)];
    [scissorPath addLineToPoint:CGPointMake(600, 300)];
    [scissorPath addLineToPoint:CGPointMake(600, 800)];
    [scissorPath addLineToPoint:CGPointMake(100, 800)];
    [scissorPath addLineToPoint:CGPointMake(100, 300)];
    [scissorPath addLineToPoint:CGPointMake(200, 300)];
    [scissorPath closePath];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(200, 250)];
    [shapePath addLineToPoint:CGPointMake(380, 250)];
    [shapePath addLineToPoint:CGPointMake(380, 350)];
    [shapePath addLineToPoint:CGPointMake(200, 350)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testStraightLineThroughNotchedRectangle{
    // a simple straight line scissor
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(600,300)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150,200)];
    // first V through intersection
    [shapePath addLineToPoint:CGPointMake(200,200)];
    [shapePath addLineToPoint:CGPointMake(250,350)];
    [shapePath addLineToPoint:CGPointMake(300,200)];
    // continue top
    [shapePath addLineToPoint:CGPointMake(550,200)];
    [shapePath addLineToPoint:CGPointMake(550,400)];
    // second vertical V through intersection
    [shapePath addLineToPoint:CGPointMake(500,400)];
    [shapePath addLineToPoint:CGPointMake(450,250)];
    [shapePath addLineToPoint:CGPointMake(400,400)];
    [shapePath addLineToPoint:CGPointMake(150,400)];
    [shapePath addLineToPoint:CGPointMake(150,200)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testTangentThroughNotchedRectangle{
    // a simple straight line scissor
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(600,300)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150,200)];
    // first V through intersection
    [shapePath addLineToPoint:CGPointMake(200,200)];
    [shapePath addLineToPoint:CGPointMake(250,300)];
    [shapePath addLineToPoint:CGPointMake(300,200)];
    // continue top
    [shapePath addLineToPoint:CGPointMake(550,200)];
    [shapePath addLineToPoint:CGPointMake(550,400)];
    // second vertical V through intersection
    [shapePath addLineToPoint:CGPointMake(500,400)];
    [shapePath addLineToPoint:CGPointMake(450,300)];
    [shapePath addLineToPoint:CGPointMake(400,400)];
    [shapePath addLineToPoint:CGPointMake(150,400)];
    [shapePath addLineToPoint:CGPointMake(150,200)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] >= 0, @"angle is right turn");
    }
}



-(void) testTangentAcrossNotchedRectangle{
    // a simple straight line scissor
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,200)];
    [scissorPath addLineToPoint:CGPointMake(600,200)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150,200)];
    // first V through intersection
    [shapePath addLineToPoint:CGPointMake(200,200)];
    [shapePath addLineToPoint:CGPointMake(250,300)];
    [shapePath addLineToPoint:CGPointMake(300,200)];
    // continue top
    [shapePath addLineToPoint:CGPointMake(550,200)];
    [shapePath addLineToPoint:CGPointMake(550,400)];
    // second vertical V through intersection
    [shapePath addLineToPoint:CGPointMake(500,400)];
    [shapePath addLineToPoint:CGPointMake(450,300)];
    [shapePath addLineToPoint:CGPointMake(400,400)];
    [shapePath addLineToPoint:CGPointMake(150,400)];
    [shapePath addLineToPoint:CGPointMake(150,200)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in [redSegments subarrayWithRange:NSMakeRange(0, 2)]){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }

    // but the reverse scissor, since it's tangent to the shape, will end up taking left turns.
    for(DKUIBezierPathClippedSegment* redSegment in [redSegments subarrayWithRange:NSMakeRange(2, 2)]){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] < 0, @"angle is right turn");
    }
}

-(void) testTangentAcrossNotchedRectangleWithTangentPoint{
    // a simple straight line scissor
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,200)];
    [scissorPath addLineToPoint:CGPointMake(600,200)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150,200)];
    // first V through intersection, creates point tangent
    [shapePath addLineToPoint:CGPointMake(250,300)];
    [shapePath addLineToPoint:CGPointMake(300,200)];
    // continue top
    [shapePath addLineToPoint:CGPointMake(550,200)];
    [shapePath addLineToPoint:CGPointMake(550,400)];
    // second vertical V through intersection
    [shapePath addLineToPoint:CGPointMake(500,400)];
    [shapePath addLineToPoint:CGPointMake(450,300)];
    [shapePath addLineToPoint:CGPointMake(400,400)];
    [shapePath addLineToPoint:CGPointMake(150,400)];
    [shapePath addLineToPoint:CGPointMake(150,200)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    DKUIBezierPathClippedSegment* redSegment = [redSegments firstObject];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
}

-(void) testLineThroughOval{
    // a simple straight line scissor
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(600,300)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150,300)];
    [shapePath addCurveToPoint:CGPointMake(450, 300) controlPoint1:CGPointMake(150, 200) controlPoint2:CGPointMake(450, 200)];
    [shapePath addCurveToPoint:CGPointMake(150, 300) controlPoint1:CGPointMake(450, 400) controlPoint2:CGPointMake(150, 400)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}


-(void) testLineThroughOffsetOval{
    // a simple straight line scissor
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(600,300)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150,310)];
    [shapePath addCurveToPoint:CGPointMake(450, 310) controlPoint1:CGPointMake(150, 210) controlPoint2:CGPointMake(450, 210)];
    [shapePath addCurveToPoint:CGPointMake(150, 310) controlPoint1:CGPointMake(450, 410) controlPoint2:CGPointMake(150, 410)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testStraightLineThroughSingleNotchedRectangle{
    // a simple straight line scissor
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(600,300)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150,200)];
    // first V through intersection
    [shapePath addLineToPoint:CGPointMake(200,200)];
    [shapePath addLineToPoint:CGPointMake(250,350)];
    [shapePath addLineToPoint:CGPointMake(300,200)];
    // continue top
    [shapePath addLineToPoint:CGPointMake(550,200)];
    [shapePath addLineToPoint:CGPointMake(550,400)];
    [shapePath addLineToPoint:CGPointMake(150,400)];
    [shapePath addLineToPoint:CGPointMake(150,200)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testStraightLineThroughReversedSingleNotchedRectangle{
    // a simple straight line scissor
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(600,300)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(150,200)];
    // first V through intersection
    [shapePath addLineToPoint:CGPointMake(200,200)];
    [shapePath addLineToPoint:CGPointMake(250,350)];
    [shapePath addLineToPoint:CGPointMake(300,200)];
    // continue top
    [shapePath addLineToPoint:CGPointMake(550,200)];
    [shapePath addLineToPoint:CGPointMake(550,400)];
    [shapePath addLineToPoint:CGPointMake(150,400)];
    [shapePath addLineToPoint:CGPointMake(150,200)];
    [shapePath closePath];
    shapePath = [shapePath bezierPathByReversingPath];
    
    XCTAssertTrue(![shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] < 0, @"angle is left turn");
    }
}

-(void) testCircleThroughRectangle{
    
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testCircleThroughReversedRectangle{
    
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    shapePath = [shapePath bezierPathByReversingPath];
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    XCTAssertTrue(![shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] < 0, @"angle is left turn");
    }
}

-(void) testComplexShapeWithInternalTangentLine{
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* shapePath = self.complexShape;
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(200,301.7455)];
    [scissorPath addLineToPoint:CGPointMake(700,301.7455)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] >= 0, @"angle is right turn");
    }
}

- (void)testCurveDifferenceWithBounds
{
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100, 50)];
    [scissorPath addCurveToPoint:CGPointMake(100, 250)
                   controlPoint1:CGPointMake(170, 80)
                   controlPoint2:CGPointMake(170, 220)];
    
    
    // simple 100x100 box
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(100, 100)];
    [shapePath addLineToPoint:CGPointMake(200, 100)];
    [shapePath addLineToPoint:CGPointMake(200, 200)];
    [shapePath addLineToPoint:CGPointMake(100, 200)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testStraightLineThroughComplexShapeAnomaly{
    // a simple straight line scissor
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(200, 1000)];
    [scissorPath addLineToPoint:CGPointMake(450, 710)];
    
    UIBezierPath* shapePath = self.complexShape;
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testLotsOfExternalTangents{
    //
    // in this case, the scissor tangents the outside of the shape before it slices through it
    //
    // this will create multiple blue lines that do not
    // connect to a red line at one of their end points.
    //
    // this will need to be cleaned up during the segment phase
    
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300,100)];
    [scissorPath addLineToPoint:CGPointMake(300,800)];
    [scissorPath addLineToPoint:CGPointMake(200,800)];
    [scissorPath addLineToPoint:CGPointMake(200,100)];
    [scissorPath closePath];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(100,300)];
    [shapePath addLineToPoint:CGPointMake(300, 300)];
    [shapePath addLineToPoint:CGPointMake(200, 500)];
    [shapePath addLineToPoint:CGPointMake(600, 500)];
    [shapePath addLineToPoint:CGPointMake(600, 800)];
    [shapePath addLineToPoint:CGPointMake(100, 800)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in [redSegments subarrayWithRange:NSMakeRange(0, 5)]){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] >= 0, @"angle is right turn");
    }
    for(DKUIBezierPathClippedSegment* redSegment in [redSegments subarrayWithRange:NSMakeRange(6, 2)]){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] >= 0, @"angle is right turn");
    }

    // left turn is all that's available for this one...
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:5];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] < 0, @"angle is left turn");
}

-(void) testSingleExternalTangents{
    //
    // in this case, the scissor tangents the outside of the shape before it slices through it
    //
    // this will create multiple blue lines that do not
    // connect to a red line at one of their end points.
    //
    // this will need to be cleaned up during the segment phase
    
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300,100)];
    [scissorPath addLineToPoint:CGPointMake(300,900)];
    
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(100,300)];
    [shapePath addLineToPoint:CGPointMake(300, 300)];
    [shapePath addLineToPoint:CGPointMake(200, 500)];
    [shapePath addLineToPoint:CGPointMake(600, 500)];
    [shapePath addLineToPoint:CGPointMake(600, 800)];
    [shapePath addLineToPoint:CGPointMake(100, 800)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] >= 0, @"angle is right turn");
    }
}

-(void) testRemoveRedSegmentsEndingInsideShape{
    
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(434, 139)];
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
    
    UIBezierPath* shapePath = path;
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(120, 276)];
    [path addCurveToPoint:CGPointMake(404, 261) controlPoint1:CGPointMake(213.64639, 261.60071) controlPoint2:CGPointMake(309.32291, 255.5038)];
    [path addCurveToPoint:CGPointMake(442, 284) controlPoint1:CGPointMake(418.50101, 265.02277) controlPoint2:CGPointMake(431.69467, 273.1311)];
    [path addCurveToPoint:CGPointMake(494, 354) controlPoint1:CGPointMake(464.80707, 302.7251) controlPoint2:CGPointMake(478.84366, 329.36636)];
    [path addCurveToPoint:CGPointMake(520, 442) controlPoint1:CGPointMake(511.24597, 379.80554) controlPoint2:CGPointMake(522.3692, 410.65625)];
    [path addLineToPoint:CGPointMake(520, 442)];
    [path addLineToPoint:CGPointMake(491, 484)];
    
    UIBezierPath* scissorPath = path;
    
    XCTAssertTrue(![shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] < 0, @"angle is left turn");
    }
}

-(void) testLineThroughNearTangent2{
    //
    // i think the issue here is that the tangent that i calculate
    // for the intersection point end up not being accurate to the tangent
    // at the point.
    //
    // perhaps i should average the tangent over the length of the point
    // to the lenght of the first control point?
    //
    // or average it over the first 20px or .1, whichever is shorter (?)
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(508.5, 163)];
    [path addCurveToPoint:CGPointMake(488, 157) controlPoint1:CGPointMake(503.33316, 156.99994) controlPoint2:CGPointMake(495.66705, 157.00012)];
    [path addCurveToPoint:CGPointMake(299, 239) controlPoint1:CGPointMake(416.37802, 147.16136) controlPoint2:CGPointMake(344.33414, 185.12921)];
    [path addCurveToPoint:CGPointMake(246, 325) controlPoint1:CGPointMake(273.89377, 262.08917) controlPoint2:CGPointMake(256.60571, 292.82858)];
    [path addCurveToPoint:CGPointMake(241, 468) controlPoint1:CGPointMake(231.50536, 370.25995) controlPoint2:CGPointMake(222.48784, 421.92267)];
    [path addCurveToPoint:CGPointMake(309, 517) controlPoint1:CGPointMake(256.88425, 490.98465) controlPoint2:CGPointMake(279.76193, 513.45514)];
    [path addCurveToPoint:CGPointMake(503, 505) controlPoint1:CGPointMake(373.33853, 530.75964) controlPoint2:CGPointMake(439.7457, 518.77924)];
    [path addCurveToPoint:CGPointMake(578, 472) controlPoint1:CGPointMake(525.80219, 498.12177) controlPoint2:CGPointMake(564.07373, 497.16443)];
    [path addCurveToPoint:CGPointMake(586, 437) controlPoint1:CGPointMake(581.66315, 460.92813) controlPoint2:CGPointMake(587.71844, 449.24524)];
    [path addCurveToPoint:CGPointMake(557, 403) controlPoint1:CGPointMake(581.36877, 422.12527) controlPoint2:CGPointMake(570.54401, 409.97241)];
    [path addCurveToPoint:CGPointMake(487, 352) controlPoint1:CGPointMake(531.47479, 391.36197) controlPoint2:CGPointMake(501.86853, 377.56622)];
    [path addCurveToPoint:CGPointMake(479, 307) controlPoint1:CGPointMake(474.60147, 339.24902) controlPoint2:CGPointMake(477.67685, 322.3252)];
    [path addCurveToPoint:CGPointMake(528, 246) controlPoint1:CGPointMake(494.35587, 285.9285) controlPoint2:CGPointMake(512.70593, 267.14542)];
    [path addLineToPoint:CGPointMake(528, 246)];
    [path addLineToPoint:CGPointMake(535, 201)];
    [path addLineToPoint:CGPointMake(535, 201)];
    [path addLineToPoint:CGPointMake(508.5, 163)];
    [path closePath];
    
    UIBezierPath* shapePath = path;
    
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(236, 174)];
    [path addCurveToPoint:CGPointMake(272, 201) controlPoint1:CGPointMake(252.44324, 170.66141) controlPoint2:CGPointMake(258.57706, 200.40956)];
    [path addCurveToPoint:CGPointMake(559, 419) controlPoint1:CGPointMake(361.56906, 280.7829) controlPoint2:CGPointMake(453.51816, 360.66116)];
    [path addCurveToPoint:CGPointMake(688, 505) controlPoint1:CGPointMake(606.76227, 440.35507) controlPoint2:CGPointMake(643.33301, 478.82477)];
    
    UIBezierPath* scissorPath = path;
    
    XCTAssertTrue(![shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] < 0, @"angle is left turn");
    }
}

-(void) testScissorBeginningInShape2{
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(600,300)];
    [scissorPath addLineToPoint:CGPointMake(600,310)];
    [scissorPath addLineToPoint:CGPointMake(300,310)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testReversedScissorBeginningInShape2{
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(600,300)];
    [scissorPath addLineToPoint:CGPointMake(600,310)];
    [scissorPath addLineToPoint:CGPointMake(300,310)];
    scissorPath = [scissorPath bezierPathByReversingPath];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testCircleThroughRectangleCompareTangents{
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redBlueSegs firstObject];
    NSArray* blueSegments = [redBlueSegs lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}

-(void) testZigZagThroughComplexShapeTangents{
    UIBezierPath* shapePath = self.complexShape;
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(200,300)];
    [scissorPath addLineToPoint:CGPointMake(600,300)];
    [scissorPath addLineToPoint:CGPointMake(450,450)];
    [scissorPath addLineToPoint:CGPointMake(800,450)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");

    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redBlueSegs firstObject];
    NSArray* blueSegments = [redBlueSegs lastObject];
    
    // the forward path takes right turns, like normal...
    for(DKUIBezierPathClippedSegment* redSegment in redSegments){
        DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                      forRed:redSegments
                                                                                                     andBlue:blueSegments
                                                                                                  lastWasRed:YES
                                                                                                        comp:[shapePath isClockwise]];
        XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    }
}



-(void) testTangentToHoleInRectangle{
    UIBezierPath* path;
    path = [UIBezierPath bezierPathWithRect:CGRectMake(100, 100, 600, 400)];
    [path appendPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(150, 150, 200, 200)] bezierPathByReversingPath]];
    UIBezierPath* shapePath = path;
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(150, 800)];
    [path addLineToPoint:CGPointMake(150, 50)];
    UIBezierPath* scissorPath = path;
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)3, @"correct number of segments");
    
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments firstObject];
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"element starts in right place");
    XCTAssertEqual(redSegment.startIntersection.tValue1, (CGFloat)0.4, @"element starts in right place");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"element starts in right place");
    
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue([redSegment.endVector angleBetween:currentSegmentCandidate.startVector] > 0, @"angle is right turn");
    XCTAssertTrue([blueSegments containsObject:currentSegmentCandidate], @"best match is blue");
}


-(void) testLineNearBoundary{
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(0.000000, 0.000000)];
    [shapePath addLineToPoint:CGPointMake(768.000000, 0.000000)];
    [shapePath addLineToPoint:CGPointMake(768.000000, 1024.000000)];
    [shapePath addLineToPoint:CGPointMake(0.000000, 1024.000000)];
    [shapePath closePath];
    
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(493.500000, 1024.000000)];
    [scissorPath addCurveToPoint:CGPointMake(495.500000, 1024.000000) controlPoint1:CGPointMake(494.250000, 1024.000000) controlPoint2:CGPointMake(494.750000, 1024.000000)];

    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    
    
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)3, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)0, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)2, @"correct number of segments");
}

-(void) testLineNearBoundary2{
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(0.000000, 0.000000)];
    [shapePath addLineToPoint:CGPointMake(768.000000, 0.000000)];
    [shapePath addLineToPoint:CGPointMake(768.000000, 1024.000000)];
    [shapePath addLineToPoint:CGPointMake(0.000000, 1024.000000)];
    [shapePath closePath];
    
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(478.500000, 1024.000000)];
    [scissorPath addCurveToPoint:CGPointMake(484.000000, 1024.000000) controlPoint1:CGPointMake(480.562500, 1024.000000) controlPoint2:CGPointMake(481.937500, 1024.000000)];

    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    
    
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)3, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)0, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)2, @"correct number of segments");
}

@end

//
//  MMClippingBezierSegmentTests.m
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

@interface MMClippingBezierSegmentTests : MMClippingBezierAbstractTest

@end

@implementation MMClippingBezierSegmentTests

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
    [scissorPath addLineToPoint:CGPointMake(200, 50)];
    
    // this square starts halfway through the left side,
    // where it intersections with the line
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(50, 50)];
    [shapePath addLineToPoint:CGPointMake(50, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 0)];
    [shapePath addLineToPoint:CGPointMake(150, 150)];
    [shapePath addLineToPoint:CGPointMake(50, 150)];
    [shapePath closePath];
    
    XCTAssertTrue([shapePath isClockwise], @"correct direction for shape");

    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];

    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments lastObject];
    DKUIBezierPathClippedSegment* correctBlueSegment = [blueSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctBlueSegment, @"found correct segment");
    
    redSegment = [redSegments firstObject];
    correctBlueSegment = [blueSegments objectAtIndex:1];
    currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctBlueSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], .25, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], .75, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat).333333, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 5, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 1.0, @"correct intersection");
    
}

-(void) testCircleThroughRectangleFirstSegmentTangent{
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    
    XCTAssertTrue([shapePath isClockwise], @"default rectangle path is clockwise");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger) 4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 3, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [redSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], 1.0, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], .999997, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.999997, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 0.999997, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");

    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], 1.0, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], 1.0, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.333333, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.666667, @"correct intersection");
}

-(void) testIntersectionAtT0{
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], 0.0, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], 1.0, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.333333, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.666667, @"correct intersection");
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
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.0, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.5, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.333333, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 5, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)1.0, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 8, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 8, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments lastObject];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)1.0, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.170317, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 103, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.299541, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 104, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)1.0, @"correct intersection");
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
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.333333, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)1.0, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.333333, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.666667, @"correct intersection");
}


-(void) testSquaredCircleIntersections{
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger) 8, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 4, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [redSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], 0.999997, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], 0.999999, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.999999, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 0.999997, @"correct intersection");
}

-(void) testReversedSquaredCircleIntersections{
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath* shapePath = [[UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)] bezierPathByReversingPath];
    
    XCTAssertTrue(![shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger) 8, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 4, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
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


-(void) testSquaredCircleDifference{
    // here, the scissor is a square that contains a circle shape
    // the square wraps around the outside of the circle
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* greenSegments = [allSegments objectAtIndex:1];
    NSArray* blueSegments = [allSegments lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger) 0, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger) 4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 4, @"correct number of segments");
}


-(void) testSquaredCircleDifferenceBeginningAtTangent{
    // here, the scissor is a square that contains a circle shape
    // the square wraps around the outside of the circle, and the
    // square scissor begins at a tangent to the circle
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(400, 300)];
    [scissorPath addLineToPoint:CGPointMake(400, 400)];
    [scissorPath addLineToPoint:CGPointMake(200, 400)];
    [scissorPath addLineToPoint:CGPointMake(200, 200)];
    [scissorPath addLineToPoint:CGPointMake(400, 200)];
    [scissorPath closePath];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* greenSegments = [allSegments objectAtIndex:1];
    NSArray* blueSegments = [allSegments lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger) 0, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger) 4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 4, @"correct number of segments");
}



-(void) testRectangleScissorsThroughCircleShape{
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(100, 250, 400, 100)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger) 4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 4, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.283445, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.716555, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.670200, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.329800, @"correct intersection");
}


-(void) testClippingVerticalOvalThroughHorizontalRectangle{
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 100, 200, 400)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(100, 200, 400, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger) 4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 4, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.670200, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.329800, @"correct intersection");

    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.283445, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.716555, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 5, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)1.0, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.45, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.5, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.5, @"correct intersection");
}

//
// https://github.com/adamwulf/loose-leaf/issues/296
// the scissor begins slicing at its begin/end point
-(void) testRectangleThatSlicesThroughReversedRectangleAtEndpoint{
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
    shapePath = [shapePath bezierPathByReversingPath];
    
    XCTAssertTrue(![shapePath isClockwise], @"shape is correct direction");
    
    NSArray* allSegments = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* blueSegments = [allSegments lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 5, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)1.0, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.45, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.5, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.5, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 6, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 6, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.1, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.266667, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.666667, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.333333, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 6, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 4, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [redSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.1, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.3, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.3, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.7, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 4, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.1, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.2, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.0, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 1.0, @"correct intersection");

    
    //
    // since the reversed red lines are tangent to the shape, there are no
    // segments that start at the reversed red segment's end point. This means
    // that we shouldn't get a matching segment at all
    redSegment = [redSegments objectAtIndex:2];
    currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == nil, @"found correct segment");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.4, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.9, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.0, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 1.0, @"correct intersection");
    
    
    //
    // since the reversed red lines are tangent to the shape, there are no
    // segments that start at the reversed red segment's end point. This means
    // that we shouldn't get a matching segment at all
    redSegment = [redSegments objectAtIndex:1];
    currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                    forRed:redSegments
                                                                   andBlue:blueSegments
                                                                lastWasRed:YES
                                                                      comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == nil, @"found correct segment");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.1, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.7, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.0, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 1.0, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.102096, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.697904, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.965475, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.034525, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 4, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.1, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.266667, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.666667, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.333333, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 3, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [redSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], 1.0, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], 0.999997, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.999997, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 0.999997, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 6, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 5, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:2];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], 0.058393, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], 0.238466, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 11, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.414279, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 12, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 0.772193, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.296669, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.703331, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.561821, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.438179, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 4, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:3];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], 0.452033, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], 0.787324, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 54, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.048579, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 69, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 0.206736, @"correct intersection");
}

-(void) testLotsOfExternalTangents{
    //
    // in this case, the scissor tangents the outside of the shape before it slices through it
    //
    // this will create multiple blue lines that do not
    // connect to a red line at one of their end points.
    //
    // this will need to be cleaned up during the segment phase
    
    //
    // given the choice between a valid blue and valid red segment.
    // if both could match, then choose the red.
    
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 8, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 5, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [redSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.571429, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], 1.0, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 1.0, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 0.0, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.5, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.875, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 5, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.6, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.25, @"correct intersection");
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

    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redBlueSegs firstObject];
    NSArray* blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)2, @"the curves do intersect");
    XCTAssertEqual([blueSegments count], (NSUInteger)2, @"the curves do intersect");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.489666, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.301769, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 13, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.890672, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.085727, @"correct intersection");
}

-(void) testLineThroughNearTangent{
    
    UIBezierPath* path = [UIBezierPath bezierPath];
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
    
    UIBezierPath* shapePath = path;
    
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(221, 167.833)];
    [path addLineToPoint:CGPointMake(662, 463.833)];
    
    UIBezierPath* scissorPath = path;
    
    XCTAssertTrue(![shapePath isClockwise], @"shape is correct direction");
    
    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redBlueSegs firstObject];
    NSArray* blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)2, @"the curves do intersect");
    XCTAssertEqual([blueSegments count], (NSUInteger)2, @"the curves do intersect");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.147685, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.425472, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 14, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], (CGFloat)0.561507, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], (CGFloat)0.667665, @"correct intersection");
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
    
    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redBlueSegs firstObject];
    NSArray* blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)2, @"the curves do intersect");
    XCTAssertEqual([blueSegments count], (NSUInteger)2, @"the curves do intersect");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], 0.125865, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], 0.183654, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 9, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.107146, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 0.950284, @"correct intersection");
}

-(void) testScissorBeginningInShape{
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300,300)];
    [scissorPath addLineToPoint:CGPointMake(600,600)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    
    XCTAssertTrue([shapePath isClockwise], @"shape is correct direction");
    
    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redBlueSegs firstObject];
    NSArray* blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)0, @"the curves do intersect");
    XCTAssertEqual([blueSegments count], (NSUInteger)1, @"the curves do intersect");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:1];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.2, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 1, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.6, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.5, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 0.5, @"correct intersection");
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
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 2, @"correct number of segments");
    
    DKUIBezierPathClippedSegment* redSegment = [redSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* correctSegment = [blueSegments objectAtIndex:0];
    DKUIBezierPathClippedSegment* currentSegmentCandidate = [UIBezierPath getBestMatchSegmentForSegments:[NSArray arrayWithObject:redSegment]
                                                                                                  forRed:redSegments
                                                                                                 andBlue:blueSegments
                                                                                              lastWasRed:YES
                                                                                                    comp:[shapePath isClockwise]];
    XCTAssertTrue(currentSegmentCandidate == correctSegment, @"found correct segment");
    
    XCTAssertEqual(redSegment.startIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:redSegment.startIntersection.tValue1 to:6], (CGFloat)0.4, @"correct intersection");
    XCTAssertEqual(redSegment.endIntersection.elementIndex1, 3, @"correct intersection");
    XCTAssertEqual([self round:redSegment.endIntersection.tValue1 to:6], (CGFloat)0.8, @"correct intersection");
    
    XCTAssertEqual(currentSegmentCandidate.startIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.startIntersection.tValue1 to:6], 0.5, @"correct intersection");
    XCTAssertEqual(currentSegmentCandidate.endIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:currentSegmentCandidate.endIntersection.tValue1 to:6], 0.5, @"correct intersection");
}

-(void) testCircleThroughSquareFindsRedGreenAndBlueSegments{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)4, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)0, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)4, @"correct number of segments");
}

-(void) testSquareAroundCircleFindsRedGreenAndBlueSegments{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)0, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)4, @"correct number of segments");
}

-(void) testCircleThroughRectangleFindsRedGreenAndBlueSegments{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)1, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)3, @"correct number of segments");
}

-(void) testRedAndGreenNotIntersectingShape{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300, 300)];
    [scissorPath addLineToPoint:CGPointMake(340, 300)];
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)1, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)0, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)1, @"correct number of segments");
}

-(void) testRedAndGreenNotIntersectingShape2{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(500, 300)];
    [scissorPath addLineToPoint:CGPointMake(540, 300)];
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)0, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)1, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)1, @"correct number of segments");
}

-(void) testRedAndGreenNotIntersectingShape3{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(400, 300)];
    [scissorPath addLineToPoint:CGPointMake(340, 300)];
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)1, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)0, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)1, @"correct number of segments");
}

-(void) testRedAndGreenNotIntersectingShape4{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(400, 300)];
    [scissorPath addLineToPoint:CGPointMake(440, 300)];
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)0, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)1, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)1, @"correct number of segments");
}

-(void) testClipPathMethodForUnclosedPaths{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300, 300)];
    [scissorPath addLineToPoint:CGPointMake(340, 300)];
    
    BOOL beginsInside = NO;
    NSArray* intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    
    DKUIBezierPathClippingResult* result = [scissorPath clipUnclosedPathToClosedPath:shapePath usingIntersectionPoints:intersections andBeginsInside:beginsInside];
    UIBezierPath* diff = [result entireDifferencePath];
    UIBezierPath* inter = [result entireIntersectionPath];
    
    XCTAssertTrue(![inter isEmpty], @"difference is correct");
    XCTAssertTrue([diff isEmpty], @"difference is correct");
}

-(void) testClipPathMethodForUnclosedPaths2{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(500, 300)];
    [scissorPath addLineToPoint:CGPointMake(540, 300)];
    
    BOOL beginsInside = NO;
    NSArray* intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    
    DKUIBezierPathClippingResult* result = [scissorPath clipUnclosedPathToClosedPath:shapePath usingIntersectionPoints:intersections andBeginsInside:beginsInside];
    UIBezierPath* diff = [result entireDifferencePath];
    UIBezierPath* inter = [result entireIntersectionPath];
    
    XCTAssertTrue([inter isEmpty], @"difference is correct");
    XCTAssertTrue(![diff isEmpty], @"difference is correct");
}

-(void) testClipPathMethodForUnclosedPaths3{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300, 300)];
    [scissorPath addLineToPoint:CGPointMake(400, 300)];
    
    BOOL beginsInside = NO;
    NSArray* intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    
    DKUIBezierPathClippingResult* result = [scissorPath clipUnclosedPathToClosedPath:shapePath usingIntersectionPoints:intersections andBeginsInside:beginsInside];
    UIBezierPath* diff = [result entireDifferencePath];
    UIBezierPath* inter = [result entireIntersectionPath];
    
    XCTAssertTrue(![inter isEmpty], @"difference is correct");
    XCTAssertTrue([diff isEmpty], @"difference is correct");
}

-(void) testClipPathMethodForUnclosedPaths4{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(400, 300)];
    [scissorPath addLineToPoint:CGPointMake(500, 300)];
    
    BOOL beginsInside = NO;
    NSArray* intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    
    DKUIBezierPathClippingResult* result = [scissorPath clipUnclosedPathToClosedPath:shapePath usingIntersectionPoints:intersections andBeginsInside:beginsInside];
    UIBezierPath* diff = [result entireDifferencePath];
    UIBezierPath* inter = [result entireIntersectionPath];
    
    XCTAssertTrue([inter isEmpty], @"difference is correct");
    XCTAssertTrue(![diff isEmpty], @"difference is correct");
}

-(void) testClipPathMethodForUnclosedPaths5{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300, 300)];
    [scissorPath addLineToPoint:CGPointMake(500, 300)];
    
    BOOL beginsInside = NO;
    NSArray* intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    
    DKUIBezierPathClippingResult* result = [scissorPath clipUnclosedPathToClosedPath:shapePath usingIntersectionPoints:intersections andBeginsInside:beginsInside];
    UIBezierPath* diff = [result entireDifferencePath];
    UIBezierPath* inter = [result entireIntersectionPath];
    
    XCTAssertTrue(![inter isEmpty], @"difference is correct");
    XCTAssertTrue(![diff isEmpty], @"difference is correct");
}

-(void) testWackyShapeWithNearTwoTangents{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(279.000000, 514.500000)];
    [path addCurveToPoint:CGPointMake(390.000000, 182.000000) controlPoint1:CGPointMake(320.174255, 410.331085) controlPoint2:CGPointMake(366.746857, 298.407776)];
    [path addCurveToPoint:CGPointMake(394.000000, 208.000000) controlPoint1:CGPointMake(400.307831, 174.510330) controlPoint2:CGPointMake(389.365021, 209.911377)];
    [path addCurveToPoint:CGPointMake(397.000000, 277.000000) controlPoint1:CGPointMake(393.750977, 230.980164) controlPoint2:CGPointMake(393.218201, 254.222412)];
    [path addCurveToPoint:CGPointMake(413.000000, 323.000000) controlPoint1:CGPointMake(402.217163, 291.694550) controlPoint2:CGPointMake(401.516693, 310.622223)];
    [path addLineToPoint:CGPointMake(413.000000, 323.000000)];
    [path addLineToPoint:CGPointMake(467.000000, 209.000000)];
    [path addLineToPoint:CGPointMake(467.000000, 209.000000)];
    [path addLineToPoint:CGPointMake(499.000000, 303.000000)];
    [path addCurveToPoint:CGPointMake(591.000000, 205.000000) controlPoint1:CGPointMake(553.431458, 319.847809) controlPoint2:CGPointMake(554.236206, 234.548782)];
    [path addCurveToPoint:CGPointMake(597.000000, 220.000000) controlPoint1:CGPointMake(595.587219, 208.344925) controlPoint2:CGPointMake(597.764038, 214.441345)];
    [path addCurveToPoint:CGPointMake(603.000000, 274.000000) controlPoint1:CGPointMake(599.510864, 237.941193) controlPoint2:CGPointMake(600.970337, 256.003418)];
    [path addCurveToPoint:CGPointMake(619.000000, 341.000000) controlPoint1:CGPointMake(604.699280, 297.007202) controlPoint2:CGPointMake(610.310852, 319.653687)];
    [path addCurveToPoint:CGPointMake(648.000000, 394.000000) controlPoint1:CGPointMake(625.890930, 360.095367) controlPoint2:CGPointMake(637.018616, 377.111298)];
    [path addCurveToPoint:CGPointMake(676.000000, 435.000000) controlPoint1:CGPointMake(659.657288, 405.248230) controlPoint2:CGPointMake(671.599243, 418.732483)];
    [path addCurveToPoint:CGPointMake(364.000000, 600.000000) controlPoint1:CGPointMake(600.641174, 529.773376) controlPoint2:CGPointMake(453.142731, 516.468628)];
    [path addCurveToPoint:CGPointMake(385.000000, 582.000000) controlPoint1:CGPointMake(370.006561, 592.937134) controlPoint2:CGPointMake(377.121796, 586.855957)];
    [path addCurveToPoint:CGPointMake(428.000000, 536.000000) controlPoint1:CGPointMake(401.738892, 568.985840) controlPoint2:CGPointMake(413.365784, 551.062622)];
    [path addCurveToPoint:CGPointMake(480.000000, 472.000000) controlPoint1:CGPointMake(445.641632, 514.912231) controlPoint2:CGPointMake(460.425049, 491.468048)];
    [path addCurveToPoint:CGPointMake(524.000000, 427.000000) controlPoint1:CGPointMake(493.963654, 456.317993) controlPoint2:CGPointMake(509.295837, 441.963623)];
    [path addCurveToPoint:CGPointMake(552.000000, 397.000000) controlPoint1:CGPointMake(535.248413, 419.040894) controlPoint2:CGPointMake(544.760986, 408.691315)];
    [path addCurveToPoint:CGPointMake(536.000000, 395.000000) controlPoint1:CGPointMake(553.866577, 389.133301) controlPoint2:CGPointMake(537.733398, 399.266693)];
    [path addCurveToPoint:CGPointMake(400.000000, 476.000000) controlPoint1:CGPointMake(481.019806, 398.074127) controlPoint2:CGPointMake(445.133209, 450.249054)];
    [path addCurveToPoint:CGPointMake(258.000000, 576.000000) controlPoint1:CGPointMake(356.769989, 514.459412) controlPoint2:CGPointMake(306.712006, 545.588013)];
    [path addLineToPoint:CGPointMake(258.000000, 576.000000)];
    [path addLineToPoint:CGPointMake(245.000000, 581.000000)];
    [path addLineToPoint:CGPointMake(245.000000, 581.000000)];
    [path addLineToPoint:CGPointMake(279.000000, 514.500000)];
    [path closePath];
    
    UIBezierPath* shapePath = path;
    
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(215.000000, 641.000000)];
    [path addCurveToPoint:CGPointMake(414.000000, 141.000000) controlPoint1:CGPointMake(306.906647, 485.259827) controlPoint2:CGPointMake(328.464569, 297.898132)];
    [path addCurveToPoint:CGPointMake(420.000000, 593.000000) controlPoint1:CGPointMake(417.193054, 285.531067) controlPoint2:CGPointMake(383.226410, 464.100708)];
    [path addCurveToPoint:CGPointMake(508.000000, 169.000000) controlPoint1:CGPointMake(448.704803, 476.501068) controlPoint2:CGPointMake(515.962585, 256.029938)];
    [path addCurveToPoint:CGPointMake(554.000000, 511.000000) controlPoint1:CGPointMake(499.445953, 278.306458) controlPoint2:CGPointMake(501.171417, 414.712006)];
    [path addLineToPoint:CGPointMake(554.000000, 511.000000)];
    [path addLineToPoint:CGPointMake(580.000000, 165.000000)];
    [path addCurveToPoint:CGPointMake(584.000000, 185.000000) controlPoint1:CGPointMake(583.567078, 170.929153) controlPoint2:CGPointMake(584.931946, 178.146225)];
    [path addCurveToPoint:CGPointMake(592.000000, 282.000000) controlPoint1:CGPointMake(589.344788, 217.091721) controlPoint2:CGPointMake(587.914185, 249.773163)];
    [path addCurveToPoint:CGPointMake(615.000000, 416.000000) controlPoint1:CGPointMake(595.852600, 327.222931) controlPoint2:CGPointMake(604.317139, 371.934601)];
    [path addCurveToPoint:CGPointMake(678.000000, 577.000000) controlPoint1:CGPointMake(633.368164, 470.080719) controlPoint2:CGPointMake(647.075195, 527.999512)];
    
    UIBezierPath* scissorPath = path;
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)9, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)10, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)18, @"correct number of segments");
}

-(void) testCurveThroughKnottedBlob{
    UIBezierPath* path = [UIBezierPath bezierPath];
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
    
    UIBezierPath* shapePath = path;
    
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(755.000000, 236.000000)];
    [path addCurveToPoint:CGPointMake(116.000000, 307.000000) controlPoint1:CGPointMake(543.220825, 192.273193) controlPoint2:CGPointMake(328.863098, 304.263763)];
    [path addCurveToPoint:CGPointMake(142.000000, 277.000000) controlPoint1:CGPointMake(103.893066, 293.674683) controlPoint2:CGPointMake(129.960800, 273.840576)];
    [path addCurveToPoint:CGPointMake(275.000000, 240.000000) controlPoint1:CGPointMake(184.754257, 259.168274) controlPoint2:CGPointMake(230.349365, 251.159592)];
    [path addCurveToPoint:CGPointMake(445.000000, 200.000000) controlPoint1:CGPointMake(330.876129, 223.224686) controlPoint2:CGPointMake(388.530731, 214.236267)];
    [path addCurveToPoint:CGPointMake(612.000000, 169.000000) controlPoint1:CGPointMake(499.946594, 185.988968) controlPoint2:CGPointMake(555.905518, 176.790924)];
    [path addCurveToPoint:CGPointMake(830.000000, 126.000000) controlPoint1:CGPointMake(683.244446, 153.338440) controlPoint2:CGPointMake(761.097961, 150.868408)];
    
    UIBezierPath* scissorPath = path;
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)4, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)3, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)6, @"correct number of segments");
}

-(void) testShapeWithLoop{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(100, 100)];
    [path addLineToPoint:CGPointMake(250, 200)];
    [path addLineToPoint:CGPointMake(150, 200)];
    [path addLineToPoint:CGPointMake(300, 100)];
    [path addLineToPoint:CGPointMake(300, 300)];
    [path addLineToPoint:CGPointMake(100, 300)];
    [path closePath];
    
    UIBezierPath* shapePath = path;
    
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(50, 180)];
    [path addLineToPoint:CGPointMake(400, 180)];
    
    UIBezierPath* scissorPath = path;
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)3, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)4, @"correct number of segments");
}

-(void) testScissorWithSubpaths{
    UIBezierPath* path = [UIBezierPath bezierPath];
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
    UIBezierPath* shapePath = path;
    
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
    UIBezierPath* scissorPath = path;
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)3, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)3, @"correct number of segments");

    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    redSegments = [redBlueSegs firstObject];
    blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)2, @"correct number of segments");
}


-(void) testScissorsThroughRectangleWithRectangleShapeWithHole{
    // this is a long unclosed scissor path that cuts first
    // through the exact start of the closed shape
    //
    // this is different than testScissorAtShapeBeginningWithComplexShape
    // in that the approach to the first intersection is not
    // near-tangent to the curve.
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(800,300)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    [shapePath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)] bezierPathByReversingPath]];
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)3, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)4, @"correct number of segments");
    
    for(DKUIBezierPathClippedSegment* segment in blueSegments){
        __block int countOfMoveTo = 0;
        [segment.pathSegment iteratePathWithBlock:^(CGPathElement ele, NSUInteger idx){
            if(ele.type == kCGPathElementMoveToPoint){
                countOfMoveTo++;
            }
        }];
        XCTAssertEqual(countOfMoveTo, 1, @"only 1 moveto per segment");
    }
    
    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    redSegments = [redBlueSegs firstObject];
    blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)4, @"correct number of segments");
    for(DKUIBezierPathClippedSegment* segment in blueSegments){
        __block int countOfMoveTo = 0;
        [segment.pathSegment iteratePathWithBlock:^(CGPathElement ele, NSUInteger idx){
            if(ele.type == kCGPathElementMoveToPoint){
                countOfMoveTo++;
            }
        }];
        XCTAssertEqual(countOfMoveTo, 1, @"only 1 moveto per segment");
    }

    // validate red segments
    DKUIBezierPathClippedSegment* segment = [redSegments objectAtIndex:0];
    XCTAssertEqual(segment.startIntersection.elementIndex2, 4, @"correct intersection");
    XCTAssertEqual([self round:segment.startIntersection.tValue2 to:6], 0.5, @"correct intersection");
    XCTAssertEqual(segment.endIntersection.elementIndex2, 9, @"correct intersection");
    XCTAssertEqual([self round:segment.endIntersection.tValue2 to:6], 0.5, @"correct intersection");

    segment = [redSegments objectAtIndex:1];
    XCTAssertEqual(segment.startIntersection.elementIndex2, 7, @"correct intersection");
    XCTAssertEqual([self round:segment.startIntersection.tValue2 to:6], 0.5, @"correct intersection");
    XCTAssertEqual(segment.endIntersection.elementIndex2, 2, @"correct intersection");
    XCTAssertEqual([self round:segment.endIntersection.tValue2 to:6], 0.5, @"correct intersection");

    segment = [redSegments objectAtIndex:2];
    XCTAssertEqual(segment.startIntersection.elementIndex2, 9, @"correct intersection");
    XCTAssertEqual([self round:segment.startIntersection.tValue2 to:6], 0.5, @"correct intersection");
    XCTAssertEqual(segment.endIntersection.elementIndex2, 4, @"correct intersection");
    XCTAssertEqual([self round:segment.endIntersection.tValue2 to:6], 0.5, @"correct intersection");

    segment = [redSegments objectAtIndex:3];
    XCTAssertEqual(segment.startIntersection.elementIndex2, 2, @"correct intersection");
    XCTAssertEqual([self round:segment.startIntersection.tValue2 to:6], 0.5, @"correct intersection");
    XCTAssertEqual(segment.endIntersection.elementIndex2, 7, @"correct intersection");
    XCTAssertEqual([self round:segment.endIntersection.tValue2 to:6], 0.5, @"correct intersection");

    // validate blue segments
    segment = [blueSegments objectAtIndex:0];
    XCTAssertEqual(segment.startIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:segment.startIntersection.tValue1 to:6], 0.5, @"correct intersection");
    XCTAssertEqual(segment.endIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:segment.endIntersection.tValue1 to:6], 0.5, @"correct intersection");
    
    segment = [blueSegments objectAtIndex:1];
    XCTAssertEqual(segment.startIntersection.elementIndex1, 2, @"correct intersection");
    XCTAssertEqual([self round:segment.startIntersection.tValue1 to:6], 0.5, @"correct intersection");
    XCTAssertEqual(segment.endIntersection.elementIndex1, 4, @"correct intersection");
    XCTAssertEqual([self round:segment.endIntersection.tValue1 to:6], 0.5, @"correct intersection");
    
    segment = [blueSegments objectAtIndex:2];
    XCTAssertEqual(segment.startIntersection.elementIndex1, 9, @"correct intersection");
    XCTAssertEqual([self round:segment.startIntersection.tValue1 to:6], 0.5, @"correct intersection");
    XCTAssertEqual(segment.endIntersection.elementIndex1, 7, @"correct intersection");
    XCTAssertEqual([self round:segment.endIntersection.tValue1 to:6], 0.5, @"correct intersection");
    
    segment = [blueSegments objectAtIndex:3];
    XCTAssertEqual(segment.startIntersection.elementIndex1, 7, @"correct intersection");
    XCTAssertEqual([self round:segment.startIntersection.tValue1 to:6], 0.5, @"correct intersection");
    XCTAssertEqual(segment.endIntersection.elementIndex1, 9, @"correct intersection");
    XCTAssertEqual([self round:segment.endIntersection.tValue1 to:6], 0.5, @"correct intersection");
}

-(void) testSimpleHoleInRectangle{
    UIBezierPath* path;
    path = [UIBezierPath bezierPathWithRect:CGRectMake(100, 100, 600, 400)];
    [path appendPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(150, 150, 200, 200)] bezierPathByReversingPath]];
    UIBezierPath* shapePath = path;
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(175, 800)];
    [path addLineToPoint:CGPointMake(175, 50)];
    UIBezierPath* scissorPath = path;
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)3, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)4, @"correct number of segments");
    
    for(DKUIBezierPathClippedSegment* segment in blueSegments){
        __block int countOfMoveTo = 0;
        [segment.pathSegment iteratePathWithBlock:^(CGPathElement ele, NSUInteger idx){
            if(ele.type == kCGPathElementMoveToPoint){
                countOfMoveTo++;
            }
        }];
        XCTAssertEqual(countOfMoveTo, 1, @"only 1 moveto per segment");
    }
    
    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    redSegments = [redBlueSegs firstObject];
    blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)4, @"correct number of segments");
    for(DKUIBezierPathClippedSegment* segment in blueSegments){
        __block int countOfMoveTo = 0;
        [segment.pathSegment iteratePathWithBlock:^(CGPathElement ele, NSUInteger idx){
            if(ele.type == kCGPathElementMoveToPoint){
                countOfMoveTo++;
            }
        }];
        XCTAssertEqual(countOfMoveTo, 1, @"only 1 moveto per segment");
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
    
    for(DKUIBezierPathClippedSegment* segment in blueSegments){
        __block int countOfMoveTo = 0;
        [segment.pathSegment iteratePathWithBlock:^(CGPathElement ele, NSUInteger idx){
            if(ele.type == kCGPathElementMoveToPoint){
                countOfMoveTo++;
            }
        }];
        XCTAssertEqual(countOfMoveTo, 1, @"only 1 moveto per segment");
    }

    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    redSegments = [redBlueSegs firstObject];
    blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)3, @"correct number of segments");
    
    for(DKUIBezierPathClippedSegment* segment in blueSegments){
        __block int countOfMoveTo = 0;
        [segment.pathSegment iteratePathWithBlock:^(CGPathElement ele, NSUInteger idx){
            if(ele.type == kCGPathElementMoveToPoint){
                countOfMoveTo++;
            }
        }];
        XCTAssertEqual(countOfMoveTo, 1, @"only 1 moveto per segment");
    }
    
    
    DKUIBezierPathClippedSegment* blueSegment = [blueSegments objectAtIndex:0];
    XCTAssertEqual(blueSegment.startIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.startIntersection.tValue2 to:6], (CGFloat).4, @"correct intersection");
    XCTAssertEqual(blueSegment.endIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.endIntersection.tValue2 to:6], (CGFloat).933333, @"correct intersection");
    
    blueSegment = [blueSegments objectAtIndex:1];
    XCTAssertEqual(blueSegment.startIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.startIntersection.tValue2 to:6], (CGFloat).933333, @"correct intersection");
    XCTAssertEqual(blueSegment.endIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.endIntersection.tValue2 to:6], (CGFloat).4, @"correct intersection");
    
    blueSegment = [blueSegments objectAtIndex:2];
    XCTAssertEqual(blueSegment.startIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.startIntersection.tValue2 to:6], (CGFloat)0.733333, @"correct intersection");
    XCTAssertEqual(blueSegment.endIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.endIntersection.tValue2 to:6], (CGFloat)0.733333, @"correct intersection");
}

-(void) testTangentToSquareHoleInRectangle{
    UIBezierPath* path;
    path = [UIBezierPath bezierPathWithRect:CGRectMake(100, 100, 600, 400)];
    [path appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(150, 150, 200, 200)] bezierPathByReversingPath]];
    UIBezierPath* shapePath = path;
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(150, 800)];
    [path addLineToPoint:CGPointMake(150, 50)];
    UIBezierPath* scissorPath = path;
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)3, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)4, @"correct number of segments");
    
    for(DKUIBezierPathClippedSegment* segment in blueSegments){
        __block int countOfMoveTo = 0;
        [segment.pathSegment iteratePathWithBlock:^(CGPathElement ele, NSUInteger idx){
            if(ele.type == kCGPathElementMoveToPoint){
                countOfMoveTo++;
            }
        }];
        XCTAssertEqual(countOfMoveTo, 1, @"only 1 moveto per segment");
    }
    
    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    redSegments = [redBlueSegs firstObject];
    blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)6, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)4, @"correct number of segments");
    
    for(DKUIBezierPathClippedSegment* segment in blueSegments){
        __block int countOfMoveTo = 0;
        [segment.pathSegment iteratePathWithBlock:^(CGPathElement ele, NSUInteger idx){
            if(ele.type == kCGPathElementMoveToPoint){
                countOfMoveTo++;
            }
        }];
        XCTAssertEqual(countOfMoveTo, 1, @"only 1 moveto per segment");
    }
    
    
    DKUIBezierPathClippedSegment* blueSegment = [blueSegments objectAtIndex:0];
    XCTAssertEqual(blueSegment.startIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.startIntersection.tValue2 to:6], (CGFloat).4, @"correct intersection");
    XCTAssertEqual(blueSegment.endIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.endIntersection.tValue2 to:6], (CGFloat).933333, @"correct intersection");
    
    blueSegment = [blueSegments objectAtIndex:1];
    XCTAssertEqual(blueSegment.startIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.startIntersection.tValue2 to:6], (CGFloat).933333, @"correct intersection");
    XCTAssertEqual(blueSegment.endIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.endIntersection.tValue2 to:6], (CGFloat).4, @"correct intersection");
    
    blueSegment = [blueSegments objectAtIndex:2];
    XCTAssertEqual(blueSegment.startIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.startIntersection.tValue2 to:6], (CGFloat)0.866667, @"correct intersection");
    XCTAssertEqual(blueSegment.endIntersection.elementIndex2, 1, @"correct intersection");
    XCTAssertEqual([self round:blueSegment.endIntersection.tValue2 to:6], (CGFloat)0.6, @"correct intersection");
}

-(void) testScissorsCreatingHole{
    // this is a long unclosed scissor path that cuts first
    // through the exact start of the closed shape
    //
    // this is different than testScissorAtShapeBeginningWithComplexShape
    // in that the approach to the first intersection is not
    // near-tangent to the curve.
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)1, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)0, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)1, @"correct number of segments");

    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    redSegments = [redBlueSegs firstObject];
    blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)1, @"correct number of segments");
}


-(void) testDrawnScissorsCreatingHole{
    UIBezierPath* path = [UIBezierPath bezierPath];
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
    UIBezierPath* shapePath = path;
    
    
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
    UIBezierPath* scissorPath = path;
    
    NSArray* redGreenBlueSegs = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [redGreenBlueSegs firstObject];
    NSArray* greenSegments = [redGreenBlueSegs objectAtIndex:1];
    NSArray* blueSegments = [redGreenBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)1, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger)0, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)1, @"correct number of segments");
    
    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    redSegments = [redBlueSegs firstObject];
    blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)1, @"correct number of segments");
}

-(void) testCurveThroughCurveWithDuplicateAndReversedSubpaths{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(213.500443, 825.800354)];
    [path addLineToPoint:CGPointMake(646.153992, 801.208496)];
    [path addLineToPoint:CGPointMake(613.364990, 224.336761)];
    [path addLineToPoint:CGPointMake(180.711182, 248.928589)];
    [path closePath];
    [path moveToPoint:CGPointMake(375.719360, 754.913452)];
    [path addLineToPoint:CGPointMake(473.427460, 749.623779)];
    [path addLineToPoint:CGPointMake(473.427460, 749.623779)];
    [path addLineToPoint:CGPointMake(470.339111, 604.666077)];
    [path addLineToPoint:CGPointMake(470.339111, 604.666077)];
    [path addLineToPoint:CGPointMake(365.687286, 616.933716)];
    [path addLineToPoint:CGPointMake(365.687286, 616.933716)];
    [path addLineToPoint:CGPointMake(375.719360, 754.913452)];
    [path addLineToPoint:CGPointMake(375.719360, 754.913452)];
    [path closePath];
    [path moveToPoint:CGPointMake(375.719360, 754.913452)];
    [path addLineToPoint:CGPointMake(375.719360, 754.913452)];
    [path addLineToPoint:CGPointMake(365.687286, 616.933716)];
    [path addLineToPoint:CGPointMake(365.687286, 616.933716)];
    [path addLineToPoint:CGPointMake(470.339111, 604.666077)];
    [path addLineToPoint:CGPointMake(470.339111, 604.666077)];
    [path addLineToPoint:CGPointMake(473.427460, 749.623779)];
    [path addLineToPoint:CGPointMake(473.427460, 749.623779)];
    [path addLineToPoint:CGPointMake(375.719360, 754.913452)];
    [path closePath];
    UIBezierPath* shapePath = path;
    
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(453.500000, 735.000000)];
    [path addCurveToPoint:CGPointMake(330.500000, 586.000000) controlPoint1:CGPointMake(432.323883, 706.718689) controlPoint2:CGPointMake(342.284515, 590.499573)];
    UIBezierPath* scissorPath = path;
    
    XCTAssertTrue([shapePath containsDuplicateAndReversedSubpaths], @"shape contains duplicate subpaths");
    
    return;
    
    // TODO: define correct behavior
    
    NSArray* allSegments = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* greenSegments = [allSegments objectAtIndex:1];
    NSArray* blueSegments = [allSegments lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 10, @"correct number of segments");
}

-(void) testRedBlueSegmentsFromLooseLeafCrash{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0.000000, 0.000000)];
    [path addLineToPoint:CGPointMake(768.000000, 0.000000)];
    [path addLineToPoint:CGPointMake(768.000000, 1024.000000)];
    [path addLineToPoint:CGPointMake(0.000000, 1024.000000)];
    [path closePath];
    UIBezierPath* shapePath = path;


    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(492.000000, 1024.000000)];
    [path addCurveToPoint:CGPointMake(496.000000, 1024.000000) controlPoint1:CGPointMake(493.500000, 1024.000000) controlPoint2:CGPointMake(494.500000, 1024.000000)];
    UIBezierPath* scissorPath = path;

    // TODO: define correct behavior
    
    XCTAssertTrue(NO, @"define correct behavior for segments along a tangent");
    return;

    NSArray* allSegments = [UIBezierPath redAndGreenAndBlueSegmentsCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray* redSegments = [allSegments firstObject];
    NSArray* greenSegments = [allSegments objectAtIndex:1];
    NSArray* blueSegments = [allSegments lastObject];

    XCTAssertEqual([redSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([greenSegments count], (NSUInteger) 2, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger) 10, @"correct number of segments");
}

@end

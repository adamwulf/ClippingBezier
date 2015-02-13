//
//  DrawKitiOSFastFlatTests.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 9/8/13.
//  Copyright (c) 2013 Milestone Made LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ClippingBezier/ClippingBezier.h>
#import <DrawKit-iOS/DrawKit-iOS.h>
#import <PerformanceBezier/PerformanceBezier.h>


@interface DrawKitiOSFastFlatTests : XCTestCase

@end

@implementation DrawKitiOSFastFlatTests


- (void)testCurveIntersectionThroughRect{
    
    //
    // testPath is a curved line that starts
    // out above bounds, and curves through the
    // bounds box until it ends outside on the
    // other side
    
    UIBezierPath* testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(100, 50)];
    [testPath addCurveToPoint:CGPointMake(100, 250)
                controlPoint1:CGPointMake(170, 80)
                controlPoint2:CGPointMake(170, 220)];
    
    
    // simple 100x100 box
    UIBezierPath* bounds = [UIBezierPath bezierPath];
    [bounds moveToPoint:CGPointMake(100, 100)];
    [bounds addLineToPoint:CGPointMake(200, 100)];
    [bounds addLineToPoint:CGPointMake(200, 200)];
    [bounds addLineToPoint:CGPointMake(100, 200)];
    [bounds addLineToPoint:CGPointMake(100, 100)];
    [bounds closePath];
    
    
    
    DKIntersectionOfPaths* firstIntersection = [UIBezierPath firstIntersectionBetween:[testPath bezierPathByFlatteningPath] andPath:bounds];
    
    
    NSLog(@"cropped path: %@", [firstIntersection.start bezierPathByUnflatteningPath]);
    
    
    XCTAssertEqual(firstIntersection.doesIntersect, YES, @"the curves do intersect");
    XCTAssertEqual(firstIntersection.elementNumberOfIntersection, 337, @"the curves do intersect");
    XCTAssertEqual(floorf(100*firstIntersection.tValueOfIntersection), 57.0f, @"the curves do intersect");
    
    
    XCTAssertEqual(firstIntersection.start.firstPoint.x, 100.0f, @"starts at the right place");
    XCTAssertEqual(firstIntersection.start.firstPoint.y, 50.0f, @"starts at the right place");
    XCTAssertEqual(floorf(firstIntersection.start.lastPoint.x), 143.0f, @"ends at the right place");
    XCTAssertEqual(firstIntersection.start.lastPoint.y, 100.0f, @"ends at the right place");
    
    XCTAssertEqual(floorf(firstIntersection.end.firstPoint.x), 143.0f, @"starts at the right place");
    XCTAssertEqual(firstIntersection.end.firstPoint.y, 100.0f, @"starts at the right place");
    XCTAssertEqual(firstIntersection.end.lastPoint.x, 100.0f, @"starts at the right place");
    XCTAssertEqual(firstIntersection.end.lastPoint.y, 250.0f, @"starts at the right place");
    
}


- (void)testCurveIntersectionInsideToOutsideRect{
    
    // testPath is a curved line that starts
    // inside bounds box, and ends outside
    // below the box
    
    UIBezierPath* testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(150, 150)];
    [testPath addCurveToPoint:CGPointMake(150, 250)
                controlPoint1:CGPointMake(170, 80)
                controlPoint2:CGPointMake(170, 220)];
    
    
    // simple 100x100 box
    UIBezierPath* bounds = [UIBezierPath bezierPath];
    [bounds moveToPoint:CGPointMake(100, 100)];
    [bounds addLineToPoint:CGPointMake(200, 100)];
    [bounds addLineToPoint:CGPointMake(200, 200)];
    [bounds addLineToPoint:CGPointMake(100, 200)];
    [bounds addLineToPoint:CGPointMake(100, 100)];
    [bounds closePath];
    
    DKIntersectionOfPaths* firstIntersection = [UIBezierPath firstIntersectionBetween:[testPath bezierPathByFlatteningPathAndImmutable:YES] andPath:bounds];
    
    
    NSLog(@"cropped path: %@", [firstIntersection.start bezierPathByUnflatteningPath]);
    
    
    XCTAssertEqual(firstIntersection.doesIntersect, YES, @"the curves do intersect");
    XCTAssertEqual(firstIntersection.elementNumberOfIntersection, 1345, @"the curves do intersect");
    XCTAssertEqual(floorf(100*firstIntersection.tValueOfIntersection), 92.0f, @"the curves do intersect");
    
    
    XCTAssertEqual(firstIntersection.start.firstPoint.x, 150.0f, @"starts at the right place");
    XCTAssertEqual(firstIntersection.start.firstPoint.y, 150.0f, @"starts at the right place");
    XCTAssertEqual(floorf(firstIntersection.start.lastPoint.x), 162.0f, @"ends at the right place");
    XCTAssertEqual(firstIntersection.start.lastPoint.y, 200.0f, @"ends at the right place");
    
    XCTAssertEqual(floorf(firstIntersection.end.firstPoint.x), 162.0f, @"starts at the right place");
    XCTAssertEqual(firstIntersection.end.firstPoint.y, 200.0f, @"starts at the right place");
    XCTAssertEqual(floorf(firstIntersection.end.lastPoint.x), 150.0f, @"starts at the right place");
    XCTAssertEqual(firstIntersection.end.lastPoint.y, 250.0f, @"starts at the right place");
}



- (void)testCurveIntersectionInsideRect{
    
    // testPath is a curved line entirely contained
    // inside of bounds
    
    UIBezierPath* testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(150, 150)];
    [testPath addCurveToPoint:CGPointMake(170, 180)
                controlPoint1:CGPointMake(160, 150)
                controlPoint2:CGPointMake(160, 180)];
    
    
    // simple 100x100 box
    UIBezierPath* bounds = [UIBezierPath bezierPath];
    [bounds moveToPoint:CGPointMake(100, 100)];
    [bounds addLineToPoint:CGPointMake(200, 100)];
    [bounds addLineToPoint:CGPointMake(200, 200)];
    [bounds addLineToPoint:CGPointMake(100, 200)];
    [bounds addLineToPoint:CGPointMake(100, 100)];
    [bounds closePath];
    
    DKIntersectionOfPaths* firstIntersection = [UIBezierPath firstIntersectionBetween:[testPath bezierPathByFlatteningPath] andPath:bounds];
    
    
    NSLog(@"cropped path: %@", [firstIntersection.start bezierPathByUnflatteningPath]);
    
    
    XCTAssertEqual(firstIntersection.doesIntersect, NO, @"the curves do intersect");
    XCTAssertEqual(firstIntersection.elementNumberOfIntersection, -1, @"the curves do intersect");
    XCTAssertEqual(floorf(100*firstIntersection.tValueOfIntersection), 0.0f, @"the curves do intersect");
    
    
    XCTAssertEqual(firstIntersection.start.firstPoint.x, 150.0f, @"starts at the right place");
    XCTAssertEqual(firstIntersection.start.firstPoint.y, 150.0f, @"starts at the right place");
    XCTAssertEqual(floorf(firstIntersection.start.lastPoint.x), 170.0f, @"ends at the right place");
    XCTAssertEqual(firstIntersection.start.lastPoint.y, 180.0f, @"ends at the right place");
    
    XCTAssertEqual([firstIntersection.end elementCount], 0, @"end path is empty");
}


- (void)testCurveIntersectionOutsideRect{
    
    // testPath is a curved line entirely contained
    // inside of bounds
    
    UIBezierPath* testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(250, 250)];
    [testPath addCurveToPoint:CGPointMake(270, 280)
                controlPoint1:CGPointMake(260, 250)
                controlPoint2:CGPointMake(260, 280)];
    
    
    // simple 100x100 box
    UIBezierPath* bounds = [UIBezierPath bezierPath];
    [bounds moveToPoint:CGPointMake(100, 100)];
    [bounds addLineToPoint:CGPointMake(200, 100)];
    [bounds addLineToPoint:CGPointMake(200, 200)];
    [bounds addLineToPoint:CGPointMake(100, 200)];
    [bounds addLineToPoint:CGPointMake(100, 100)];
    [bounds closePath];
    
    DKIntersectionOfPaths* firstIntersection = [UIBezierPath firstIntersectionBetween:[testPath bezierPathByFlatteningPath] andPath:bounds];
    
    
    NSLog(@"cropped path: %@", [firstIntersection.start bezierPathByUnflatteningPath]);
    
    
    XCTAssertEqual(firstIntersection.doesIntersect, NO, @"the curves do intersect");
    XCTAssertEqual(firstIntersection.elementNumberOfIntersection, -1, @"the curves do intersect");
    XCTAssertEqual(floorf(100*firstIntersection.tValueOfIntersection), 0.0f, @"the curves do intersect");
    
    
    XCTAssertEqual(firstIntersection.start.firstPoint.x, 250.0f, @"starts at the right place");
    XCTAssertEqual(firstIntersection.start.firstPoint.y, 250.0f, @"starts at the right place");
    XCTAssertEqual(floorf(firstIntersection.start.lastPoint.x), 270.0f, @"ends at the right place");
    XCTAssertEqual(firstIntersection.start.lastPoint.y, 280.0f, @"ends at the right place");
    
    XCTAssertEqual([firstIntersection.end elementCount], 0, @"end path is empty");
}








- (void)testCalculateUnclosedPathThroughClosedBoundsFast{
    
    //
    // testPath is a curved line that starts
    // out above bounds, and curves through the
    // bounds box until it ends outside on the
    // other side
    
    UIBezierPath* testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(100, 50)];
    [testPath addCurveToPoint:CGPointMake(100, 250)
                controlPoint1:CGPointMake(170, 80)
                controlPoint2:CGPointMake(170, 220)];
    
    
    // simple 100x100 box
    UIBezierPath* bounds = [UIBezierPath bezierPath];
    [bounds moveToPoint:CGPointMake(100, 100)];
    [bounds addLineToPoint:CGPointMake(200, 100)];
    [bounds addLineToPoint:CGPointMake(200, 200)];
    [bounds addLineToPoint:CGPointMake(100, 200)];
    [bounds addLineToPoint:CGPointMake(100, 100)];
    [bounds closePath];
    
    NSArray* output = [UIBezierPath calculateIntersectionAndDifferenceBetween:testPath andPath:bounds];
    
    
//    NSLog(@"cropped path: %@", [[output firstObject] bezierPathByUnflatteningPath]);
//    NSLog(@"cropped path: %@", [[output lastObject] bezierPathByUnflatteningPath]);
    
    UIBezierPath* inter = [output firstObject];
    UIBezierPath* diff = [output lastObject];
    
    
    XCTAssertEqual([inter elementCount], 1556, @"the curves do intersect");
    XCTAssertEqual([diff elementCount], 1184, @"the curves do intersect");
    
    XCTAssertEqual([[inter subPaths] count], (NSUInteger)2, @"the curves do intersect");
    XCTAssertEqual([[diff subPaths] count], (NSUInteger)1, @"the curves do intersect");
    
    XCTAssertEqual(inter.firstPoint.x, 100.0f, @"starts at the right place");
    XCTAssertEqual(inter.firstPoint.y, 50.0f, @"starts at the right place");
    XCTAssertEqual(floorf(inter.lastPoint.x), 100.0f, @"ends at the right place");
    XCTAssertEqual(inter.lastPoint.y, 250.0f, @"ends at the right place");
    
    XCTAssertEqual(floorf(diff.firstPoint.x), 143.0f, @"starts at the right place");
    XCTAssertEqual(diff.firstPoint.y, 100.0f, @"starts at the right place");
    XCTAssertEqual(floorf(diff.lastPoint.x), 143.0f, @"starts at the right place");
    XCTAssertEqual(diff.lastPoint.y, 200.0f, @"starts at the right place");
    
}


-(void) testPerformanceTestOfIntersectionAndDifference{
    
    [NSThread sleepForTimeInterval:2];
    NSLog(@"beginning test testCalculateUnclosedPathThroughClosedBoundsFast");
    
    for(int i=0;i<1000;i++){
        @autoreleasepool {
            [self testCalculateUnclosedPathThroughClosedBoundsFast];
        }
    }
    
    NSLog(@"done test testCalculateUnclosedPathThroughClosedBoundsFast");
    
}


@end

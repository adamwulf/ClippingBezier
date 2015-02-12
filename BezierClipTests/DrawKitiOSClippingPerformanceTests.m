//
//  DrawKitiOSClippingPerformanceTests.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 11/20/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <DrawKit-iOS/DrawKit-iOS.h>
#import "DrawKitiOSAbstractTest.h"
#import <ClippingBezier/BezierClip.h>


@interface DrawKitiOSClippingPerformanceTests : DrawKitiOSAbstractTest

@end

@implementation DrawKitiOSClippingPerformanceTests

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

-(void) testPerformanceTestOfIntersectionAndDifference{
    
    //    [NSThread sleepForTimeInterval:2];
    NSLog(@"beginning test testCalculateUnclosedPathThroughClosedBoundsFast");
    
    for(int i=0;i<1000;i++){
        @autoreleasepool {
            [self performanceHelperIntersectionWithComplexShape];
        }
    }
    
    NSLog(@"done test testCalculateUnclosedPathThroughClosedBoundsFast");
    
}



#pragma mark - Helpers

-(void) performanceHelperIntersectionWithComplexShape{
    CGPoint bez1_[4], bez2_[4];
    
    bez1_[0] = CGPointMake(100.0, 50.0);
    bez1_[1] = CGPointMake(370.0,80.0);
    bez1_[2] = CGPointMake(570.0,520.0);
    bez1_[3] = CGPointMake(600.0,850.0);
    
    
    UIBezierPath* line = [UIBezierPath bezierPath];
    [line moveToPoint:bez1_[0]];
    [line addCurveToPoint:bez1_[3] controlPoint1:bez1_[1] controlPoint2:bez1_[2]];
    
    CGPoint* bez1 = bez1_;
    CGPoint* bez2 = bez2_;
    
    __block int found = 0;
    __block CGPoint lastPoint;
    
    NSMutableArray* output = [NSMutableArray array];
    
    [self.complexShape iteratePathWithBlock:^(CGPathElement element, NSUInteger idx){
        if(element.type == kCGPathElementCloseSubpath){
            // noop
        }else{
            if(element.type == kCGPathElementAddCurveToPoint){
                bez2[0] = lastPoint;
                bez2[1] = element.points[0];
                bez2[2] = element.points[1];
                bez2[3] = element.points[2];
            }else if(element.type == kCGPathElementAddLineToPoint){
                bez2[0] = lastPoint;
                bez2[1] = lastPoint;
                bez2[2] = element.points[0];
                bez2[3] = element.points[0];
            }
            lastPoint = element.points[[UIBezierPath numberOfPointsForElement:element]-1];
            
            if(element.type != kCGPathElementMoveToPoint){
                NSArray* intersections = [UIBezierPath findIntersectionsBetweenBezier:bez1 andBezier:bez2];
                found += [intersections count];
                [output addObjectsFromArray:intersections];
            }
        }
    }];
    
    
    
    NSArray* intersections = [line findIntersectionsWithClosedPath:self.complexShape andBeginsInside:nil];
    
    
    XCTAssertEqual(found, 8, @"the curves do intersect");
    XCTAssertEqual([intersections count], (NSUInteger) 8, @"the curves do intersect");
}



-(void) testPerformanceTestOfIntersectionAndDifference2{
    
    [NSThread sleepForTimeInterval:2];
    NSLog(@"beginning test testPerformanceTestOfIntersectionAndDifference");
    
    for(int i=0;i<1000;i++){
        @autoreleasepool {
//            [self testClipUnclosedCurveToClosedBounds];
        }
    }
    XCTAssertTrue(NO, @"fix performance test");
    
    NSLog(@"done test testPerformanceTestOfIntersectionAndDifference");
    
}






-(void) testScissorsThroughMultipleShapeHoles{
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(800,300)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 400, 200)];
    [shapePath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)] bezierPathByReversingPath]];
    [shapePath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(450, 250, 100, 100)] bezierPathByReversingPath]];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)6, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    //
    // the issue with this test is that each subshape is being split separately
    // when instead all of the intersections and blue segments from cut subshapes should be
    // in the same bucket.
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)6, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testPerformanceTestOfFindingSubshapesWithScissors{
    
    NSLog(@"beginning test testPerformanceTestOfIntersectionAndDifference");
    
    for(int i=0;i<1000;i++){
        @autoreleasepool {
            [self testScissorsThroughMultipleShapeHoles];
        }
    }
    
    NSLog(@"done test testPerformanceTestOfIntersectionAndDifference");
    
}

@end

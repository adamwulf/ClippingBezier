//
//  DrawKitiOSFlatTests.m
//  DrawKit-iOS Tests
//
//  Created by Adam Wulf on 8/7/13.
//  Copyright (c) 2013 Milestone Made LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <DrawKit-iOS/DrawKit-iOS.h>
#import <ClippingBezier/BezierClip.h>

@interface DrawKitiOSFlatTests : XCTestCase

@end

@implementation DrawKitiOSFlatTests

- (void)testReverseSimplePath
{
    UIBezierPath* testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(1, 1)];
    [testPath addCurveToPoint:CGPointMake(2, 2) controlPoint1:CGPointMake(3, 3) controlPoint2:CGPointMake(4, 4)];
    
    UIBezierPath* ios7Reversed = [testPath bezierPathByReversingPath];
    UIBezierPath* ios5Reversed = [testPath nsosx_backwardcompatible_bezierPathByReversingPath];
    
    XCTAssertTrue(CGPathEqualToPath(ios5Reversed.CGPath, ios7Reversed.CGPath), @"paths are the same");
}

- (void)testReversePathWithClose
{
    UIBezierPath* testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(1, 1)];
    [testPath addLineToPoint:CGPointMake(2, 2)];
    [testPath addLineToPoint:CGPointMake(1, 2)];
//    [testPath closePath];
    
    UIBezierPath* ios7Reversed = [testPath bezierPathByReversingPath];
    UIBezierPath* ios5Reversed = [testPath nsosx_backwardcompatible_bezierPathByReversingPath];
    
    XCTAssertEqual([testPath elementCount], [ios7Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed elementCount], [ios5Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed countSubPaths], [ios5Reversed countSubPaths], @"subpath counts are the same");

    NSString* ios7Description = [ios7Reversed description];
    NSString* ios5Description = [ios5Reversed description];
    
    BOOL isEqual = CGPathEqualToPath(ios5Reversed.CGPath, ios7Reversed.CGPath);
    
    if(!isEqual){
        NSLog(@"ios7: %@", ios7Description);
        NSLog(@"ios5: %@", ios5Description);
    }
    
    XCTAssertTrue(isEqual, @"paths are the same");
}

- (void)testReversePathWithMultipleMoveTo
{
    UIBezierPath* testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(1, 1)];
    [testPath addCurveToPoint:CGPointMake(2, 2) controlPoint1:CGPointMake(3, 3) controlPoint2:CGPointMake(4, 4)];
    [testPath moveToPoint:CGPointMake(5, 5)];
    [testPath addCurveToPoint:CGPointMake(6, 6) controlPoint1:CGPointMake(7, 7) controlPoint2:CGPointMake(8, 8)];
    
    UIBezierPath* ios7Reversed = [testPath bezierPathByReversingPath];
    UIBezierPath* ios5Reversed = [testPath nsosx_backwardcompatible_bezierPathByReversingPath];
    
    XCTAssertEqual([testPath elementCount], [ios7Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed elementCount], [ios5Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed countSubPaths], [ios5Reversed countSubPaths], @"subpath counts are the same");
    
    NSString* ios7Description = [ios7Reversed description];
    NSString* ios5Description = [ios5Reversed description];
    
    BOOL isEqual = CGPathEqualToPath(ios5Reversed.CGPath, ios7Reversed.CGPath);
    
    if(!isEqual){
        NSLog(@"=================");
        NSLog(@"ios7: %@", ios7Description);
        NSLog(@"ios5: %@", ios5Description);
    }
    
    XCTAssertTrue(isEqual, @"paths are the same");
}

- (void)testReversePathWithMixedElementTypes
{
    UIBezierPath* testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(1, 1)];
    [testPath addCurveToPoint:CGPointMake(2, 2) controlPoint1:CGPointMake(3, 3) controlPoint2:CGPointMake(4, 4)];
    [testPath addQuadCurveToPoint:CGPointMake(5, 5) controlPoint:CGPointMake(6, 6)];
    [testPath addLineToPoint:CGPointMake(7, 7)];
    
    UIBezierPath* ios7Reversed = [testPath bezierPathByReversingPath];
    UIBezierPath* ios5Reversed = [testPath nsosx_backwardcompatible_bezierPathByReversingPath];
    
    XCTAssertEqual([testPath elementCount], [ios7Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed elementCount], [ios5Reversed elementCount], @"element counts are the same");
    XCTAssertEqual([ios7Reversed countSubPaths], [ios5Reversed countSubPaths], @"subpath counts are the same");
    
    NSString* ios7Description = [ios7Reversed description];
    NSString* ios5Description = [ios5Reversed description];
    
    BOOL isEqual = CGPathEqualToPath(ios5Reversed.CGPath, ios7Reversed.CGPath);
    
    if(!isEqual){
        NSLog(@"=================");
        NSLog(@"ios7: %@", ios7Description);
        NSLog(@"ios5: %@", ios5Description);
    }
    
    XCTAssertTrue(isEqual, @"paths are the same");
}



- (void)testCopyPathWithFreedElementCache
{
    NSInteger count1;
    UIBezierPath* copiedPath;
    @autoreleasepool {
        UIBezierPath* testPath = [UIBezierPath bezierPath];
        [testPath moveToPoint:CGPointMake(1, 1)];
        [testPath addCurveToPoint:CGPointMake(2, 2) controlPoint1:CGPointMake(3, 3) controlPoint2:CGPointMake(4, 4)];
        [testPath addQuadCurveToPoint:CGPointMake(5, 5) controlPoint:CGPointMake(6, 6)];
        [testPath addLineToPoint:CGPointMake(7, 7)];
        
        count1 = [testPath elementCount];
        for(int i=0;i<[testPath elementCount];i++){
            [testPath elementAtIndex:i];
            // prime the element cache
        }
        
        copiedPath = [testPath copy];
        
        [testPath applyTransform:CGAffineTransformIdentity];
    }
    
    [copiedPath elementAtIndex:0];

    XCTAssertEqual([copiedPath elementCount], count1, @"counts are the same");
}


@end

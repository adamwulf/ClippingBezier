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

- (void)testSimpleUnion
{
    UIBezierPath *path1 = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 100, 100)];
    UIBezierPath *path2 = [UIBezierPath bezierPathWithRect:CGRectMake(50, 20, 100, 60)];
    NSArray<DKUIBezierPathShape *> *clippingResult1 = [path1 uniqueShapesCreatedFromSlicingWithUnclosedPath:path2];
    NSArray<DKUIBezierPathShape *> *clippingResult2 = [path2 uniqueShapesCreatedFromSlicingWithUnclosedPath:path1];

    NSMutableArray *flippedResult2 = [NSMutableArray array];
    [clippingResult2 enumerateObjectsUsingBlock:^(DKUIBezierPathShape *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [flippedResult2 addObject:[obj flippedShape]];
    }];

    NSMutableArray<DKUIBezierPathShape *> *finalShapes = [flippedResult2 mutableCopy];

    for (DKUIBezierPathShape *firstShape in clippingResult1) {
        BOOL didFind = NO;
        for (DKUIBezierPathShape *secondShape in finalShapes) {
            if ([firstShape isSameShapeAs:secondShape]) {
                didFind = YES;
                break;
            }
        }
        if (!didFind) {
            [finalShapes addObject:firstShape];
        }
    }

    XCTAssertEqual([finalShapes count], 3);

    XCTAssert([finalShapes[0] sharesSegmentWith:finalShapes[1]]);
    XCTAssert([finalShapes[1] sharesSegmentWith:finalShapes[2]]);
}

@end

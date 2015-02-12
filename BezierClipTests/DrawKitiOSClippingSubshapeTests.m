//
//  DrawKitiOSClippingSubshapes.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 11/20/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DrawKitiOSAbstractTest.h"
#import <DrawKit-iOS/DrawKit-iOS.h>
#import <ClippingBezier/BezierClip.h>


@interface DrawKitiOSClippingSubshapeTests : DrawKitiOSAbstractTest

@end

@implementation DrawKitiOSClippingSubshapeTests

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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }

    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testCircleThroughRectangleFirstSegmentTangent{
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 100)];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }

    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)3, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testSquaredCircleIntersections{
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)8, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:6] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:7] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)5, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testRectangleScissorsThroughCircleShape{
    // here, the scissor is a square that contains a circle shape
    // the square wraps around the outside of the circle
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(100, 250, 400, 100)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 200, 200, 200)];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)3, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testClippingVerticalOvalThroughHorizontalRectangle{
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 100, 200, 400)];
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(100, 200, 400, 200)];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)3, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testClippingVerticalOvalThroughReversedHorizontalRectangle{
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 100, 200, 400)];
    UIBezierPath* shapePath = [[UIBezierPath bezierPathWithRect:CGRectMake(100, 200, 400, 200)] bezierPathByReversingPath];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)4, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)3, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)6, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)4, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)4, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)6, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)3, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)4, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testTangentAcrossNotchedRectangle{
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    // two red segments * 2 for 4 shapes.
    // two blue segments tangent to the red, for 2 more shapes
    // so 6 total.
    // but because they're tangents, 2 of the 3 segments per tangent
    // are removed, leaving just 1 segment per tangent.
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    XCTAssertTrue([[foundShapes objectAtIndex:0] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:1] isClosed], @"shape is closed");
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)1, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    // three shapes because 2 from the 1 red segment (forward and reversed),
    // and 1 from the blue segment that's tangent to the red segment and was unused
    // then, since all segments are tangent, 2 of the 3 are filtered out
    // so only 1 of them creates a shape
    XCTAssertEqual([foundShapes count], (NSUInteger)1, @"found shapes");
    
    XCTAssertTrue([[foundShapes objectAtIndex:0] isClosed], @"shape is closed");
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)1, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    XCTAssertTrue([[foundShapes objectAtIndex:0] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:1] isClosed], @"shape is closed");
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    XCTAssertTrue([[foundShapes objectAtIndex:0] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:1] isClosed], @"shape is closed");
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found shapes");
    
    XCTAssertTrue([[foundShapes objectAtIndex:0] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:1] isClosed], @"shape is closed");
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)3, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testComplexShapeWithInternalTangentLine{
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* shapePath = self.complexShape;
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(200,301.7455)];
    [scissorPath addLineToPoint:CGPointMake(700,301.7455)];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)6, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)3, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)4, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testStraightLineThroughComplexShapeAnomaly{
    // a simple straight line scissor
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(200, 1000)];
    [scissorPath addLineToPoint:CGPointMake(450, 710)];
    
    UIBezierPath* shapePath = self.complexShape;
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)4, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)3, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    // this has an odd number of shapes, because a red + blue segment overlap
    // so a that blue segment is left over. one additional shape is added for that
    // blue segment, but because it overlaps the red, the shape-builder finds that
    // believes the blue and red segments are equal, and adds another duplicate
    XCTAssertEqual([foundShapes count], (NSUInteger)7, @"found shapes");
    
    XCTAssertTrue([[foundShapes objectAtIndex:0] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:1] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:2] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:3] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:4] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:5] isClosed], @"shape is closed");
    XCTAssertTrue([[foundShapes objectAtIndex:6] isClosed], @"shape is closed");
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:6] segments] count], (NSUInteger)3, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)4, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testScissorBeginningInShape{
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(300,300)];
    [scissorPath addLineToPoint:CGPointMake(600,600)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    // 1 shape from the blue segment leftover
    XCTAssertEqual([foundShapes count], (NSUInteger)1, @"found shapes");
    XCTAssertTrue([[foundShapes objectAtIndex:0] isClosed], @"shape is closed");
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)1, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)1, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testScissorBeginningInShape2{
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(600,300)];
    [scissorPath addLineToPoint:CGPointMake(600,310)];
    [scissorPath addLineToPoint:CGPointMake(300,310)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testComplexShapeWithZigZagLine{
    // here, the scissor is a circle that is contained with in a square shape
    // the square wraps around the outside of the circle
    UIBezierPath* shapePath = self.complexShape;
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(200,300)];
    [scissorPath addLineToPoint:CGPointMake(600,300)];
    [scissorPath addLineToPoint:CGPointMake(450,450)];
    [scissorPath addLineToPoint:CGPointMake(800,450)];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)6, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)4, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)4, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testScissorAtShapeBeginningWithComplexShape2{
    UIBezierPath* shapePath = self.complexShape;
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)8, @"found shapes");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:6] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:7] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)5, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testFindingMultipleSubPathWithoutIntersection2{
    // if there is no intersection,
    // then return zero found shapes
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    [shapePath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)] bezierPathByReversingPath]];
    
    BOOL beginsInside = NO;
    NSArray* intersections = [scissorPath findIntersectionsWithClosedPath:shapePath andBeginsInside:&beginsInside];
    
    XCTAssertEqual([intersections count], (NSUInteger)0, @"found 0 intersections");
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    // found the two shapes that don't even have holes
    XCTAssertEqual([foundShapes count], (NSUInteger)1, @"found shapes");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)1, @"found shapes");
    DKUIBezierPathShape* shape = [uniqueShapes firstObject];
    XCTAssertEqual([shape.segments count], (NSUInteger)1, @"found shapes");
    XCTAssertEqual([shape.holes count], (NSUInteger)1, @"found shapes");
}

-(void) testOvalClippingInRectangleSubShapes{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(100, 200, 400, 200)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(300, 300) radius:120 startAngle:0 endAngle:2*M_PI clockwise:NO];
    [scissorPath closePath];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)4, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)3, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testOvalClippingInRectangleSubShapes2{
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(100, 200, 400, 200)];
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(200, 100, 200, 400)];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)3, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testLineThroughNotchedRectangle{
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)6, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)4, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)4, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testTrickyLineNearCorner{
    // this is a long unclosed scissor path that cuts first
    // through the exact start of the closed shape
    //
    // this is different than testScissorAtShapeBeginningWithComplexShape
    // in that the approach to the first intersection is not
    // near-tangent to the curve.
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(419.000000, 391.000000)];
    [scissorPath addLineToPoint:CGPointMake(419.000000, 391.000000)];
    [scissorPath addLineToPoint:CGPointMake(393.000000, 134.000000)];
    [scissorPath addLineToPoint:CGPointMake(393.000000, 134.000000)];
    [scissorPath addLineToPoint:CGPointMake(295.000000, 428.000000)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(324.500000, 214.500000)];
    [shapePath addLineToPoint:CGPointMake(324.500000, 214.500000)];
    [shapePath addLineToPoint:CGPointMake(308.000000, 330.000000)];
    [shapePath addLineToPoint:CGPointMake(308.000000, 330.000000)];
    [shapePath addLineToPoint:CGPointMake(417.000000, 330.000000)];
    [shapePath addCurveToPoint:CGPointMake(440.000000, 241.000000) controlPoint1:CGPointMake(412.503845, 297.977478) controlPoint2:CGPointMake(427.308289, 269.161133)];
    [shapePath addLineToPoint:CGPointMake(440.000000, 241.000000)];
    [shapePath addLineToPoint:CGPointMake(324.500000, 214.500000)];
    [shapePath closePath];
    
    XCTAssertTrue(![shapePath isClockwise], @"correct direction for shape");
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)3, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testTangentLineVeryCloseToBottomLeftCorner{
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(583.000000, 507.000000)];
    [scissorPath addCurveToPoint:CGPointMake(345.000000, 416.000000) controlPoint1:CGPointMake(498.772095, 526.729858) controlPoint2:CGPointMake(381.666901, 504.214264)];
    [scissorPath addCurveToPoint:CGPointMake(339.000000, 391.000000) controlPoint1:CGPointMake(341.283173, 408.190948) controlPoint2:CGPointMake(339.255585, 399.625031)];
    [scissorPath addCurveToPoint:CGPointMake(344.000000, 347.000000) controlPoint1:CGPointMake(337.957397, 376.253235) controlPoint2:CGPointMake(334.880249, 360.331146)];
    [scissorPath addCurveToPoint:CGPointMake(392.000000, 288.000000) controlPoint1:CGPointMake(353.160583, 322.184723) controlPoint2:CGPointMake(376.012543, 307.667786)];
    [scissorPath addCurveToPoint:CGPointMake(446.000000, 245.000000) controlPoint1:CGPointMake(411.416962, 275.365845) controlPoint2:CGPointMake(425.716034, 256.450195)];
    [scissorPath addCurveToPoint:CGPointMake(512.000000, 208.000000) controlPoint1:CGPointMake(468.236786, 233.073502) controlPoint2:CGPointMake(487.736115, 216.092346)];
    [scissorPath addCurveToPoint:CGPointMake(583.000000, 182.000000) controlPoint1:CGPointMake(534.509277, 196.477371) controlPoint2:CGPointMake(558.653931, 188.569092)];
    [scissorPath addCurveToPoint:CGPointMake(866.000000, 157.000000) controlPoint1:CGPointMake(674.142639, 148.723312) controlPoint2:CGPointMake(771.588013, 163.587265)];
    
    
    UIBezierPath* shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(391.500000, 100.000000)];
    [shapePath addCurveToPoint:CGPointMake(385.000000, 126.000000) controlPoint1:CGPointMake(384.673950, 113.890152) controlPoint2:CGPointMake(384.343201, 119.999458)];
    [shapePath addCurveToPoint:CGPointMake(378.000000, 188.000000) controlPoint1:CGPointMake(384.629333, 146.855789) controlPoint2:CGPointMake(380.078888, 167.308807)];
    [shapePath addCurveToPoint:CGPointMake(366.000000, 257.000000) controlPoint1:CGPointMake(372.313721, 210.747162) controlPoint2:CGPointMake(373.362122, 234.591141)];
    [shapePath addCurveToPoint:CGPointMake(347.000000, 320.000000) controlPoint1:CGPointMake(359.059937, 277.820679) controlPoint2:CGPointMake(354.156677, 299.247772)];
    [shapePath addCurveToPoint:CGPointMake(337.000000, 355.000000) controlPoint1:CGPointMake(345.080994, 332.087891) controlPoint2:CGPointMake(339.269348, 343.025055)];
    [shapePath addCurveToPoint:CGPointMake(339.000000, 368.000000) controlPoint1:CGPointMake(340.090637, 355.983337) controlPoint2:CGPointMake(331.870361, 369.795532)];
    [shapePath addCurveToPoint:CGPointMake(638.000000, 373.000000) controlPoint1:CGPointMake(437.713409, 366.002777) controlPoint2:CGPointMake(546.082642, 401.471680)];
    [shapePath addCurveToPoint:CGPointMake(689.000000, 148.000000) controlPoint1:CGPointMake(646.626648, 306.623993) controlPoint2:CGPointMake(696.822205, 227.174286)];
    [shapePath addCurveToPoint:CGPointMake(391.500000, 100.000000) controlPoint1:CGPointMake(594.519104, 121.932289) controlPoint2:CGPointMake(496.490753, 86.968353)];
    [shapePath closePath];
    
    XCTAssertTrue(![shapePath isClockwise], @"correct direction for shape");
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
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
    
    XCTAssertTrue([shapePath isClockwise], @"correct direction for shape");
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)18, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:6] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:7] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:8] segments] count], (NSUInteger)6, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:9] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:10] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:11] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:12] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:13] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:14] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:15] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:16] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:17] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)10, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testNearTangentLineToSloppyBox{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(324.500000, 214.500000)];
    [path addLineToPoint:CGPointMake(324.500000, 214.500000)];
    [path addLineToPoint:CGPointMake(308.000000, 330.000000)];
    [path addLineToPoint:CGPointMake(308.000000, 330.000000)];
    [path addLineToPoint:CGPointMake(417.000000, 330.000000)];
    [path addCurveToPoint:CGPointMake(440.000000, 241.000000) controlPoint1:CGPointMake(412.503845, 297.977478) controlPoint2:CGPointMake(427.308289, 269.161133)];
    [path addLineToPoint:CGPointMake(440.000000, 241.000000)];
    [path addLineToPoint:CGPointMake(324.500000, 214.500000)];
    [path closePath];
    
    UIBezierPath* shapePath = path;
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(131.000000, 331.000000)];
    [path addLineToPoint:CGPointMake(131.000000, 331.000000)];
    [path addLineToPoint:CGPointMake(559.000000, 326.000000)];
    
    UIBezierPath* scissorPath = path;
    
    XCTAssertTrue(![shapePath isClockwise], @"correct direction for shape");
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testZigZagLineThroughSloppyBox{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(324.500000, 214.500000)];
    [path addLineToPoint:CGPointMake(324.500000, 214.500000)];
    [path addLineToPoint:CGPointMake(308.000000, 330.000000)];
    [path addLineToPoint:CGPointMake(308.000000, 330.000000)];
    [path addLineToPoint:CGPointMake(417.000000, 330.000000)];
    [path addCurveToPoint:CGPointMake(440.000000, 241.000000) controlPoint1:CGPointMake(412.503845, 297.977478) controlPoint2:CGPointMake(427.308289, 269.161133)];
    [path addLineToPoint:CGPointMake(440.000000, 241.000000)];
    [path addLineToPoint:CGPointMake(324.500000, 214.500000)];
    [path closePath];
    
    UIBezierPath* shapePath = path;
    
    
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
    
    UIBezierPath* scissorPath = path;
    
    XCTAssertTrue(![shapePath isClockwise], @"correct direction for shape");
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)6, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)4, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)4, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}

-(void) testSquiggleThroughLongRectangle{
    UIBezierPath* path = [UIBezierPath bezierPath];
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
    
    UIBezierPath* shapePath = path;
    
    
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
    
    UIBezierPath* scissorPath = path;
    
    XCTAssertTrue(![shapePath isClockwise], @"correct direction for shape");
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)18, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:4] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:5] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:6] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:7] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:8] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:9] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:10] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:11] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:12] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:13] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:14] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:15] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:16] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:17] segments] count], (NSUInteger)4, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)10, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
}


#pragma mark - Shapes With SubShapes



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
    
    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    redSegments = [redBlueSegs firstObject];
    blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)4, @"correct number of segments");
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)4, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
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
    
    NSArray* redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    redSegments = [redBlueSegs firstObject];
    blueSegments = [redBlueSegs lastObject];
    
    XCTAssertEqual([redSegments count], (NSUInteger)4, @"correct number of segments");
    XCTAssertEqual([blueSegments count], (NSUInteger)3, @"correct number of segments");
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)3, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)3, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
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
    
    NSArray* shapesAndSubshapes = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    // three red segments * 2 + 1 blue (minus 1 red and 1 blue b/c it's tangent to the blue)
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 5, @"found shapes");
    // two red shapes
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 0, @"found holes");
    
    shapesAndSubshapes = [shapePath uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 2, @"found shapes");
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 0, @"found holes");
    
    NSArray* foundShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found intersection");
    
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        NSArray* subpaths = [shape.fullPath subPaths];
        UIBezierPath* outerPath = [subpaths firstObject];
        XCTAssertTrue([outerPath isClosed], @"subpath is closed");
        for(int i=1;i<[subpaths count];i++){
            UIBezierPath* subpath = [subpaths objectAtIndex:i];
            XCTAssertTrue([outerPath isClockwise] == ![subpath isClockwise], @"subpath is reverse direction");
            XCTAssertTrue([subpath isClosed], @"subpath is closed");
        }
    }
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
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)4, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    //
    // the issue with this test is that each subshape is being split separately
    // when instead all of the intersections and blue segments from cut subshapes should be
    // in the same bucket.
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:2] segments] count], (NSUInteger)4, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:3] segments] count], (NSUInteger)4, @"found closed shape");
    
    NSArray* uniqueShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([uniqueShapes count], (NSUInteger)2, @"found shapes");
    for(DKUIBezierPathShape* shape in uniqueShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
        XCTAssertEqual([shape.holes count], (NSUInteger) 0, @"shape is closed");
    }
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

-(void) testScissorsThroughHoleNotCreatingNewShape{
    // this creates shapes that we'll need to de-dup later
    //
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,300)];
    [scissorPath addLineToPoint:CGPointMake(300,300)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    [shapePath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)] bezierPathByReversingPath]];
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)1, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    //
    // the issue with this test is that each subshape is being split separately
    // when instead all of the intersections and blue segments from cut subshapes should be
    // in the same bucket.
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)1, @"found closed shape");
    
    // de-duplicate
    foundShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    XCTAssertEqual([foundShapes count], (NSUInteger)1, @"found intersection");
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)1, @"found closed shape");
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
    
    NSArray* shapesAndSubshapes = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    // two red and 1 blue shape
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 3, @"found shapes");
    // two red shapes,
    // one is a shape and one is a hole
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 1, @"found holes");
    
    shapesAndSubshapes = [shapePath uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 2, @"found shapes");
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 1, @"found holes");
    
    NSArray* foundShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    //
    // the issue with this test is that each subshape is being split separately
    // when instead all of the intersections and blue segments from cut subshapes should be
    // in the same bucket.
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:0] holes] count], (NSUInteger)0, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] holes] count], (NSUInteger)1, @"found closed shape");
    
    XCTAssertEqual([[[[foundShapes objectAtIndex:0] fullPath] subPaths] count], (NSUInteger)1, @"correct subpaths");
    XCTAssertEqual([[[[foundShapes objectAtIndex:1] fullPath] subPaths] count], (NSUInteger)2, @"correct subpaths");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        NSArray* subpaths = [shape.fullPath subPaths];
        UIBezierPath* outerPath = [subpaths firstObject];
        XCTAssertTrue([outerPath isClosed], @"subpath is closed");
        for(int i=1;i<[subpaths count];i++){
            UIBezierPath* subpath = [subpaths objectAtIndex:i];
            XCTAssertTrue([outerPath isClockwise] == ![subpath isClockwise], @"subpath is reverse direction");
            XCTAssertTrue([subpath isClosed], @"subpath is closed");
        }
    }
}

-(void) testUniqueScissorsCreatingHole{
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    
    NSArray* shapesAndSubshapes = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    // two red and 1 blue shape
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 3, @"found shapes");
    // two red shapes, but only 1 is reversed winding
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 1, @"found holes");

    shapesAndSubshapes = [shapePath uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 2, @"found shapes");
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 1, @"found holes");
    
    NSArray* foundShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found intersection");
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:0] holes] count], (NSUInteger)0, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] holes] count], (NSUInteger)1, @"found closed shape");
    
    XCTAssertEqual([[[[foundShapes objectAtIndex:0] fullPath] subPaths] count], (NSUInteger)1, @"correct subpaths");
    XCTAssertEqual([[[[foundShapes objectAtIndex:1] fullPath] subPaths] count], (NSUInteger)2, @"correct subpaths");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        NSArray* subpaths = [shape.fullPath subPaths];
        UIBezierPath* outerPath = [subpaths firstObject];
        XCTAssertTrue([outerPath isClosed], @"subpath is closed");
        for(int i=1;i<[subpaths count];i++){
            UIBezierPath* subpath = [subpaths objectAtIndex:i];
            XCTAssertTrue([outerPath isClockwise] == ![subpath isClockwise], @"subpath is reverse direction");
            XCTAssertTrue([subpath isClosed], @"subpath is closed");
        }
    }
}

-(void) testScissorsThroughShapeWithHoleMissingHole{
    
    // this is a long unclosed scissor path that cuts first
    // through the exact start of the closed shape
    //
    // this is different than testScissorAtShapeBeginningWithComplexShape
    // in that the approach to the first intersection is not
    // near-tangent to the curve.
    UIBezierPath* scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(100,225)];
    [scissorPath addLineToPoint:CGPointMake(800,225)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    [shapePath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)] bezierPathByReversingPath]];
    
    NSArray* shapesAndSubshapes = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    // two red and 1 blue shape
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 2, @"found shapes");
    // two red shapes
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 1, @"found holes");
    
    shapesAndSubshapes = [shapePath uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 2, @"found shapes");
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 1, @"found holes");
    
    NSArray* foundShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:0] holes] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] holes] count], (NSUInteger)0, @"found closed shape");
    
    
    for(DKUIBezierPathShape* shape in foundShapes){
        NSArray* subpaths = [shape.fullPath subPaths];
        UIBezierPath* outerPath = [subpaths firstObject];
        XCTAssertTrue([outerPath isClosed], @"subpath is closed");
        for(int i=1;i<[subpaths count];i++){
            UIBezierPath* subpath = [subpaths objectAtIndex:i];
            XCTAssertTrue([outerPath isClockwise] == ![subpath isClockwise], @"subpath is reverse direction");
            XCTAssertTrue([subpath isClosed], @"subpath is closed");
        }
    }
}




-(void) testScissorsMakingHoleLarger{
    
    // this is a long unclosed scissor path that cuts first
    // through the exact start of the closed shape
    //
    // this is different than testScissorAtShapeBeginningWithComplexShape
    // in that the approach to the first intersection is not
    // near-tangent to the curve.
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(220, 220, 60, 60)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    [shapePath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)] bezierPathByReversingPath]];
    
    NSArray* shapesAndSubshapes = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    // two red and 1 blue shape
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 2, @"found shapes");
    // two red shapes
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 1, @"found holes");
    
    shapesAndSubshapes = [shapePath uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 2, @"found shapes");
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 1, @"found holes");
    
    NSArray* foundShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:0] holes] count], (NSUInteger)0, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] holes] count], (NSUInteger)1, @"found closed shape");
    
    
    for(DKUIBezierPathShape* shape in foundShapes){
        NSArray* subpaths = [shape.fullPath subPaths];
        UIBezierPath* outerPath = [subpaths firstObject];
        XCTAssertTrue([outerPath isClosed], @"subpath is closed");
        for(int i=1;i<[subpaths count];i++){
            UIBezierPath* subpath = [subpaths objectAtIndex:i];
            XCTAssertTrue([outerPath isClockwise] == ![subpath isClockwise], @"subpath is reverse direction");
            XCTAssertTrue([subpath isClosed], @"subpath is closed");
        }
    }
}


-(void) testScissorsMakingHoleLarger2{
    
    // this is a long unclosed scissor path that cuts first
    // through the exact start of the closed shape
    //
    // this is different than testScissorAtShapeBeginningWithComplexShape
    // in that the approach to the first intersection is not
    // near-tangent to the curve.
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(220, 270, 60, 60)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 200, 200)];
    [shapePath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)] bezierPathByReversingPath]];
    
    NSArray* shapesAndSubshapes = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    // two red and 1 blue shape
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 2, @"found shapes");
    // two red shapes
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 1, @"found holes");
    
    shapesAndSubshapes = [shapePath uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 2, @"found shapes");
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 1, @"found holes");
    
    NSArray* foundShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)2, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:0] holes] count], (NSUInteger)0, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] holes] count], (NSUInteger)1, @"found closed shape");
    
    
    for(DKUIBezierPathShape* shape in foundShapes){
        NSArray* subpaths = [shape.fullPath subPaths];
        UIBezierPath* outerPath = [subpaths firstObject];
        XCTAssertTrue([outerPath isClosed], @"subpath is closed");
        for(int i=1;i<[subpaths count];i++){
            UIBezierPath* subpath = [subpaths objectAtIndex:i];
            XCTAssertTrue([outerPath isClockwise] == ![subpath isClockwise], @"subpath is reverse direction");
            XCTAssertTrue([subpath isClosed], @"subpath is closed");
        }
    }
}



-(void) testScissorsMakingSecondHole{
    UIBezierPath* scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(450, 250, 100, 100)];
    
    UIBezierPath* shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(200, 200, 400, 200)];
    [shapePath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(250, 250, 100, 100)] bezierPathByReversingPath]];
    
    NSArray* shapesAndSubshapes = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    // two red and 1 blue shape
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 3, @"found shapes");
    // one red hole, and one existing blue
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 2, @"found holes");
    
    shapesAndSubshapes = [shapePath uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 2, @"found shapes");
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 2, @"found holes");
    
    NSArray* foundShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:0] holes] count], (NSUInteger)0, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] holes] count], (NSUInteger)2, @"found closed shape");
    
    
    for(DKUIBezierPathShape* shape in foundShapes){
        NSArray* subpaths = [shape.fullPath subPaths];
        UIBezierPath* outerPath = [subpaths firstObject];
        XCTAssertTrue([outerPath isClosed], @"subpath is closed");
        for(int i=1;i<[subpaths count];i++){
            UIBezierPath* subpath = [subpaths objectAtIndex:i];
            XCTAssertTrue([outerPath isClockwise] == ![subpath isClockwise], @"subpath is reverse direction");
            XCTAssertTrue([subpath isClosed], @"subpath is closed");
        }
    }
}



-(void) testDisappearingHole{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(175.500732, 230.421143)];
    [path addCurveToPoint:CGPointMake(702.527161, 166.170593) controlPoint1:CGPointMake(351.411133, 211.060486) controlPoint2:CGPointMake(529.177734, 201.082153)];
    [path addCurveToPoint:CGPointMake(697.320923, 187.583679) controlPoint1:CGPointMake(692.660156, 163.630676) controlPoint2:CGPointMake(689.748657, 184.496399)];
    [path addCurveToPoint:CGPointMake(682.145386, 275.373230) controlPoint1:CGPointMake(691.426636, 216.691772) controlPoint2:CGPointMake(685.812622, 245.884277)];
    [path addCurveToPoint:CGPointMake(658.421326, 385.761047) controlPoint1:CGPointMake(676.461792, 312.604126) controlPoint2:CGPointMake(668.197571, 349.404541)];
    [path addCurveToPoint:CGPointMake(641.594421, 504.993286) controlPoint1:CGPointMake(646.190613, 424.501343) controlPoint2:CGPointMake(648.688904, 465.410156)];
    [path addCurveToPoint:CGPointMake(619.160339, 624.331177) controlPoint1:CGPointMake(637.388672, 545.362671) controlPoint2:CGPointMake(626.235291, 584.470032)];
    [path addCurveToPoint:CGPointMake(613.210144, 725.409180) controlPoint1:CGPointMake(613.410645, 657.668945) controlPoint2:CGPointMake(611.552551, 691.638306)];
    [path addCurveToPoint:CGPointMake(603.642151, 813.093140) controlPoint1:CGPointMake(611.811462, 752.655273) controlPoint2:CGPointMake(620.267029, 787.958313)];
    [path addCurveToPoint:CGPointMake(586.862793, 815.652832) controlPoint1:CGPointMake(598.415649, 815.514771) controlPoint2:CGPointMake(592.545349, 816.365723)];
    [path addCurveToPoint:CGPointMake(506.118439, 817.172729) controlPoint1:CGPointMake(559.947937, 816.159302) controlPoint2:CGPointMake(533.033264, 816.666016)];
    [path addCurveToPoint:CGPointMake(377.278503, 826.329041) controlPoint1:CGPointMake(463.110229, 818.449768) controlPoint2:CGPointMake(419.596863, 816.746765)];
    [path addCurveToPoint:CGPointMake(264.434540, 850.890015) controlPoint1:CGPointMake(339.543610, 833.953247) controlPoint2:CGPointMake(301.959229, 842.298401)];
    [path addCurveToPoint:CGPointMake(201.823563, 862.165222) controlPoint1:CGPointMake(243.742676, 855.553223) controlPoint2:CGPointMake(222.868271, 859.475403)];
    [path addCurveToPoint:CGPointMake(153.770020, 872.044495) controlPoint1:CGPointMake(186.179840, 866.041504) controlPoint2:CGPointMake(170.222488, 872.305725)];
    [path addCurveToPoint:CGPointMake(150.110229, 856.407593) controlPoint1:CGPointMake(149.131927, 868.425720) controlPoint2:CGPointMake(147.999054, 861.682495)];
    [path addCurveToPoint:CGPointMake(149.838364, 782.370972) controlPoint1:CGPointMake(149.844986, 831.729004) controlPoint2:CGPointMake(148.476501, 807.049072)];
    [path addCurveToPoint:CGPointMake(153.714630, 690.306641) controlPoint1:CGPointMake(151.150620, 751.683777) controlPoint2:CGPointMake(154.193451, 721.058716)];
    [path addCurveToPoint:CGPointMake(153.825363, 576.998474) controlPoint1:CGPointMake(154.130066, 652.540649) controlPoint2:CGPointMake(155.338486, 614.759949)];
    [path addCurveToPoint:CGPointMake(159.416580, 456.855774) controlPoint1:CGPointMake(154.166336, 536.916687) controlPoint2:CGPointMake(153.996414, 496.671387)];
    [path addCurveToPoint:CGPointMake(175.500732, 230.421143) controlPoint1:CGPointMake(168.141022, 382.216064) controlPoint2:CGPointMake(166.668716, 306.805969)];
    [path closePath];
    [path moveToPoint:CGPointMake(251.966461, 573.083618)];
    [path addCurveToPoint:CGPointMake(213.528351, 661.108154) controlPoint1:CGPointMake(214.886520, 595.633606) controlPoint2:CGPointMake(197.677231, 635.043518)];
    [path addCurveToPoint:CGPointMake(309.368408, 667.471924) controlPoint1:CGPointMake(229.379471, 687.172852) controlPoint2:CGPointMake(272.288483, 690.021973)];
    [path addCurveToPoint:CGPointMake(347.806519, 579.447388) controlPoint1:CGPointMake(346.448273, 644.921936) controlPoint2:CGPointMake(363.657715, 605.512024)];
    [path addCurveToPoint:CGPointMake(251.966461, 573.083618) controlPoint1:CGPointMake(331.955475, 553.382751) controlPoint2:CGPointMake(289.046387, 550.533569)];
    [path closePath];
    [path moveToPoint:CGPointMake(429.482330, 488.810425)];
    [path addLineToPoint:CGPointMake(410.999786, 531.081909)];
    [path addLineToPoint:CGPointMake(410.999786, 531.081909)];
    [path addLineToPoint:CGPointMake(421.822449, 570.060974)];
    [path addLineToPoint:CGPointMake(421.822449, 570.060974)];
    [path addCurveToPoint:CGPointMake(476.077759, 566.069641) controlPoint1:CGPointMake(438.102509, 582.961914) controlPoint2:CGPointMake(459.959961, 566.950073)];
    [path addCurveToPoint:CGPointMake(520.009521, 529.881042) controlPoint1:CGPointMake(493.298462, 558.425903) controlPoint2:CGPointMake(512.600281, 548.673645)];
    [path addLineToPoint:CGPointMake(501.789062, 467.580994)];
    [path addLineToPoint:CGPointMake(501.789062, 467.580994)];
    [path addLineToPoint:CGPointMake(429.482330, 488.810425)];
    [path addLineToPoint:CGPointMake(429.482330, 488.810425)];
    [path closePath];
    [path moveToPoint:CGPointMake(217.243820, 745.747925)];
    [path addCurveToPoint:CGPointMake(225.461121, 806.749756) controlPoint1:CGPointMake(203.739746, 768.926636) controlPoint2:CGPointMake(207.418671, 796.237915)];
    [path addCurveToPoint:CGPointMake(282.581207, 783.814514) controlPoint1:CGPointMake(243.503433, 817.261475) controlPoint2:CGPointMake(269.076996, 806.992981)];
    [path addCurveToPoint:CGPointMake(274.364044, 722.812744) controlPoint1:CGPointMake(296.085388, 760.635925) controlPoint2:CGPointMake(292.406403, 733.324463)];
    [path addCurveToPoint:CGPointMake(217.243820, 745.747925) controlPoint1:CGPointMake(256.321594, 712.300903) controlPoint2:CGPointMake(230.748016, 722.569336)];
    [path closePath];
    [path moveToPoint:CGPointMake(389.821625, 688.105957)];
    [path addLineToPoint:CGPointMake(340.740417, 732.781738)];
    [path addLineToPoint:CGPointMake(340.740417, 732.781738)];
    [path addCurveToPoint:CGPointMake(379.545288, 767.950378) controlPoint1:CGPointMake(331.526642, 755.608887) controlPoint2:CGPointMake(366.942749, 765.839661)];
    [path addCurveToPoint:CGPointMake(478.910706, 742.521179) controlPoint1:CGPointMake(414.166107, 769.133423) controlPoint2:CGPointMake(448.458984, 758.708557)];
    [path addCurveToPoint:CGPointMake(539.872620, 703.230835) controlPoint1:CGPointMake(497.699493, 730.924072) controlPoint2:CGPointMake(532.912109, 729.843750)];
    [path addCurveToPoint:CGPointMake(512.366882, 672.337036) controlPoint1:CGPointMake(545.610413, 686.542358) controlPoint2:CGPointMake(520.817932, 677.128906)];
    [path addCurveToPoint:CGPointMake(421.402893, 667.318176) controlPoint1:CGPointMake(482.927673, 663.996826) controlPoint2:CGPointMake(451.614166, 663.212891)];
    [path addCurveToPoint:CGPointMake(389.821625, 688.105957) controlPoint1:CGPointMake(408.649506, 666.907227) controlPoint2:CGPointMake(395.763123, 671.779724)];
    [path closePath];
    [path moveToPoint:CGPointMake(468.012482, 282.769714)];
    [path addCurveToPoint:CGPointMake(412.486359, 372.441101) controlPoint1:CGPointMake(446.518768, 316.726379) controlPoint2:CGPointMake(415.132874, 335.250427)];
    [path addCurveToPoint:CGPointMake(434.279480, 397.833191) controlPoint1:CGPointMake(409.152252, 386.056702) controlPoint2:CGPointMake(423.555725, 395.005371)];
    [path addCurveToPoint:CGPointMake(577.996277, 344.644836) controlPoint1:CGPointMake(486.710266, 408.427124) controlPoint2:CGPointMake(552.345581, 398.468201)];
    [path addCurveToPoint:CGPointMake(568.858582, 276.384033) controlPoint1:CGPointMake(580.491211, 321.606323) controlPoint2:CGPointMake(577.202332, 298.010193)];
    [path addCurveToPoint:CGPointMake(509.083893, 259.560120) controlPoint1:CGPointMake(560.083740, 254.081116) controlPoint2:CGPointMake(527.261597, 253.633240)];
    [path addCurveToPoint:CGPointMake(468.012482, 282.769714) controlPoint1:CGPointMake(495.173828, 264.837097) controlPoint2:CGPointMake(477.637054, 261.404541)];
    [path closePath];
    UIBezierPath* shapePath = path;
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(243.253784, 374.253754)];
    [path addCurveToPoint:CGPointMake(341.000000, 358.999969) controlPoint1:CGPointMake(274.457886, 343.049652) controlPoint2:CGPointMake(318.220337, 336.220306)];
    [path addCurveToPoint:CGPointMake(325.746216, 456.746185) controlPoint1:CGPointMake(363.779663, 381.779633) controlPoint2:CGPointMake(356.950317, 425.542084)];
    [path addCurveToPoint:CGPointMake(228.000000, 472.000000) controlPoint1:CGPointMake(294.542114, 487.950317) controlPoint2:CGPointMake(250.779648, 494.779633)];
    [path addCurveToPoint:CGPointMake(243.253784, 374.253754) controlPoint1:CGPointMake(205.220337, 449.220337) controlPoint2:CGPointMake(212.049683, 405.457855)];
    [path closePath];
    UIBezierPath* scissorPath = path;
    
    
    
    NSArray* shapesAndSubshapes = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    // two red and 1 blue shape
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 3, @"found shapes");
    // 5 existing from blue segments, 1 from red
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 6, @"found holes");
    
    shapesAndSubshapes = [shapePath uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 2, @"found shapes");
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 6, @"found holes");
    
    NSArray* foundShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)2, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:0] holes] count], (NSUInteger)0, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] segments] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:1] holes] count], (NSUInteger)6, @"found closed shape");
    
    
    for(DKUIBezierPathShape* shape in foundShapes){
        NSArray* subpaths = [shape.fullPath subPaths];
        UIBezierPath* outerPath = [subpaths firstObject];
        XCTAssertTrue([outerPath isClosed], @"subpath is closed");
        for(int i=1;i<[subpaths count];i++){
            UIBezierPath* subpath = [subpaths objectAtIndex:i];
            XCTAssertTrue([outerPath isClockwise] == ![subpath isClockwise], @"subpath is reverse direction");
            XCTAssertTrue([subpath isClosed], @"subpath is closed");
        }
    }
}




-(void) testSingleScissorLineBetweenTwoHoles{
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectMake(100, 100, 400, 200)];
    [path appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(150, 150, 100, 100)] bezierPathByReversingPath]];
    [path appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(350, 150, 100, 100)] bezierPathByReversingPath]];
    UIBezierPath* shapePath = path;
    
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(200,200)];
    [path addLineToPoint:CGPointMake(400, 200)];
    UIBezierPath* scissorPath = path;
    
    
    NSArray* shapesAndSubshapes = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    // two red and 1 blue shape
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 1, @"found shapes");
    // one red hole, and one existing blue
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 2, @"found holes");
    
    shapesAndSubshapes = [shapePath uniqueShapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([[shapesAndSubshapes firstObject] count], (NSUInteger) 1, @"found shapes");
    XCTAssertEqual([[shapesAndSubshapes lastObject] count], (NSUInteger) 2, @"found holes");
    
    NSArray* foundShapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    
    XCTAssertEqual([foundShapes count], (NSUInteger)1, @"found intersection");
    
    for(DKUIBezierPathShape* shape in foundShapes){
        XCTAssertTrue([shape isClosed], @"shape is closed");
    }
    
    XCTAssertEqual([[[foundShapes objectAtIndex:0] segments] count], (NSUInteger)1, @"found closed shape");
    XCTAssertEqual([[[foundShapes objectAtIndex:0] holes] count], (NSUInteger)2, @"found closed shape");
    
    
    for(DKUIBezierPathShape* shape in foundShapes){
        NSArray* subpaths = [shape.fullPath subPaths];
        UIBezierPath* outerPath = [subpaths firstObject];
        XCTAssertTrue([outerPath isClosed], @"subpath is closed");
        for(int i=1;i<[subpaths count];i++){
            UIBezierPath* subpath = [subpaths objectAtIndex:i];
            XCTAssertTrue([outerPath isClockwise] == ![subpath isClockwise], @"subpath is reverse direction");
            XCTAssertTrue([subpath isClosed], @"subpath is closed");
        }
    }
}



#pragma mark - Shapes with Loops



-(void) testShapeWithLoop{
    
    XCTAssertTrue(NO, @"functionality needs defining");
    return;
    
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
    
    XCTAssertTrue([shapePath isClockwise], @"correct direction for shape");
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
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



-(void) testCurveThroughKnottedBlob{
    XCTAssertTrue(NO, @"functionality needs defining (same as loop)");
    return;
    
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
    
    XCTAssertTrue([shapePath isClockwise], @"correct direction for shape");
    
    NSArray* subShapePaths = [shapePath shapeShellsAndSubshapesCreatedFromSlicingWithUnclosedPath:scissorPath];
    NSArray* foundShapes = [subShapePaths firstObject];
    
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



@end

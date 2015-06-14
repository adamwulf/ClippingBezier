//
//  DrawKitiOSGeometryTest.m
//  ClippingBezier
//
//  Created by Adam Wulf on 6/14/15.
//
//

#import <UIKit/UIKit.h>
#import "DrawKitiOSAbstractTest.h"

@interface DrawKitiOSGeometryTest : DrawKitiOSAbstractTest

@end

@implementation DrawKitiOSGeometryTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    
    
    CGPoint p = [self.complexShape closestPointOnPathTo:CGPointZero];
    
    XCTAssertEqual([self round:p.x to:6], 0, @"point is correct");
    XCTAssertEqual([self round:p.y to:6], 0, @"point is correct");
}


-(void) testClosestPointOnSimpleCurve{
    UIBezierPath* bez = [UIBezierPath bezierPathWithArcCenter:CGPointMake(500, 500) radius:300 startAngle:-M_PI/24 endAngle:-M_PI*12/45 clockwise:YES];
    
    CGPoint p = [bez closestPointOnPathTo:CGPointZero];

    XCTAssertEqual([self round:p.x to:6], 287.945679f, @"point is correct");
    XCTAssertEqual([self round:p.y to:6], 287.768799f, @"point is correct");
}

@end

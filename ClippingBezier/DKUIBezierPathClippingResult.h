//
//  DKUIBezierPathClippingResult.h
//  LooseLeaf
//
//  Created by Adam Wulf on 10/7/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * when clipping an unclosed path to a closed path,
 * this object will hold the output of the intersection
 * and difference path, as well as the segment information
 * for the original path.
 *
 * the segment information will say exactly where and when
 * each original segment was chopped
 */
@interface DKUIBezierPathClippingResult : NSObject

@property (nonatomic, readonly) UIBezierPath* entireIntersectionPath;
@property (nonatomic, readonly) UIBezierPath* entireDifferencePath;
@property (nonatomic, readonly) NSArray* intersectionSegments;
@property (nonatomic, readonly) NSArray* differenceSegments;
@property (nonatomic, readonly) NSUInteger numberOfShellIntersectionSegments;
@property (nonatomic, readonly) NSUInteger numberOfShellDifferenceSegments;

-(id) initWithIntersection:(UIBezierPath*)_intersection
                andSegments:(NSArray*)_intersectionSegments
             andDifference:(UIBezierPath*)_difference
                andSegments:(NSArray*)_differenceSegments
       andShellIntSegments:(NSUInteger)_numberOfShellIntersectionSegments
      andShellDiffSegments:(NSUInteger)_numberOfShellDifferenceSegments;

@end

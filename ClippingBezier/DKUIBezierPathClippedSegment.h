//
//  DKUIBezierPathClippedSegment.h
//  LooseLeaf
//
//  Created by Adam Wulf on 10/7/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKUIBezierPathIntersectionPoint.h"
#import "DKVector.h"

/**
 * when chopping an unclosed path to a closed path, this
 * represents the segment of the original unclosed path
 * that is included in the output path
 *
 * one of these segments represents a segment from one
 * moveTo to the next
 */
@interface DKUIBezierPathClippedSegment : NSObject

@property (nonatomic, readonly) DKUIBezierPathIntersectionPoint* startIntersection;
@property (nonatomic, readonly) DKUIBezierPathIntersectionPoint* endIntersection;
@property (nonatomic, readonly) UIBezierPath* pathSegment;
@property (nonatomic, readonly) UIBezierPath* fullPath;
@property (nonatomic, readonly) BOOL isReversed;
@property (nonatomic, readonly) DKUIBezierPathClippedSegment* reversedSegment;

+(DKUIBezierPathClippedSegment*) clippedPairWithStart:(DKUIBezierPathIntersectionPoint *)_tStart
                                               andEnd:(DKUIBezierPathIntersectionPoint *)_tEnd
                                       andPathSegment:(UIBezierPath *)segment
                                         fromFullPath:(UIBezierPath*)_fullPath;

//
// returns YES if the input segment could connect to the
// end of this segment
-(BOOL) canBePrependedTo:(DKUIBezierPathClippedSegment*)otherPath;

-(DKUIBezierPathClippedSegment*) prependTo:(DKUIBezierPathClippedSegment*)otherSegment;

-(DKUIBezierPathClippedSegment*) reversedSegment;

-(DKUIBezierPathClippedSegment*) flippedRedBlueSegment;

-(CGFloat) angleBetween:(DKUIBezierPathClippedSegment*)otherInter;

-(DKVector*) endVector;

-(DKVector*) startVector;

-(BOOL) isEqualToSegment:(DKUIBezierPathClippedSegment*)otherSegment;

@end

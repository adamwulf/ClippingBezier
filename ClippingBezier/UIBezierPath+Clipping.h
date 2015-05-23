//
//  UIBezierPath+Clipping.h
//  DrawKit-iOS
//
//  Created by Adam Wulf on 9/10/13.
//  Copyright (c) 2013 Milestone Made LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DKUIBezierPathClippingResult.h"
#import "DKUIBezierPathIntersectionPoint.h"
#import "DKTangentAtPoint.h"
#import "DKUIBezierPathClippedSegment.h"

@interface UIBezierPath (MMClipping)

-(NSArray*) findIntersectionsWithClosedPath:(UIBezierPath*)closedPath andBeginsInside:(BOOL*)beginsInside;

-(NSArray*) uniqueShapesCreatedFromSlicingWithUnclosedPath:(UIBezierPath*)scissorPath;

+(NSArray*) redAndGreenAndBlueSegmentsCreatedFrom:(UIBezierPath*)shapePath bySlicingWithPath:(UIBezierPath*)scissorPath andNumberOfBlueShellSegments:(NSUInteger*)numberOfBlueShellSegments;

+(DKUIBezierPathClippedSegment*) getBestMatchSegmentForSegments:(NSArray*)shapeSegments
                                                         forRed:(NSArray*)redSegments
                                                        andBlue:(NSArray*)blueSegments
                                                     lastWasRed:(BOOL)lastWasRed
                                                           comp:(BOOL)gt;

-(DKTangentAtPoint*) tangentNearEnd;

-(DKTangentAtPoint*) tangentNearStart;

-(UIBezierPath*) differenceOfPathTo:(UIBezierPath*)shapePath;

#pragma mark - Segment Comparison

+(void) resetSegmentTestCount;

+(NSInteger) segmentTestCount;

+(void) resetSegmentCompareCount;

+(NSInteger) segmentCompareCount;


@end

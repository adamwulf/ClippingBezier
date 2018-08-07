//
//  DKUIBezierPathShape.h
//  ClippingBezier
//
//  Created by Adam Wulf on 11/18/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKUIBezierPathIntersectionPoint.h"

@class DKUIBezierPathClippedSegment, DKUIBezierPathShape;

@interface DKUIBezierPathShape : NSObject{
    NSMutableArray* segments;
    NSMutableArray* holes;
}

@property (nonatomic, readonly) NSMutableArray<DKUIBezierPathClippedSegment*>* segments;
@property (nonatomic, readonly) NSMutableArray<DKUIBezierPathShape*>* holes;

-(DKUIBezierPathIntersectionPoint*) startingPoint;
-(DKUIBezierPathIntersectionPoint*) endingPoint;
-(BOOL) isClosed;
-(UIBezierPath*) fullPath;

-(BOOL) isSameShapeAs:(DKUIBezierPathShape*)otherShape;

-(BOOL) sharesSegmentWith:(DKUIBezierPathShape*)otherShape;

@end

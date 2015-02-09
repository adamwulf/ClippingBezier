//
//  DKUIBezierPathClippedSegment.m
//  LooseLeaf
//
//  Created by Adam Wulf on 10/7/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import "DKUIBezierPathClippedSegment.h"
#import "DrawKit-iOS.h"
#import "DKVector.h"

@implementation DKUIBezierPathClippedSegment{
    DKUIBezierPathIntersectionPoint* startIntersection;
    DKUIBezierPathIntersectionPoint* endIntersection;
    UIBezierPath* pathSegment1;
    UIBezierPath* fullPath;
    
    __weak DKUIBezierPathClippedSegment* reversedFrom;
    BOOL isReversed;
}

@synthesize startIntersection;
@synthesize endIntersection;
@synthesize pathSegment1;
@synthesize fullPath;
@synthesize isReversed;

-(void) setIsReversed:(BOOL)r{
    isReversed = r;
}
-(void) setReversedFrom:(DKUIBezierPathClippedSegment*)r{
    reversedFrom = r;
}

+(DKUIBezierPathClippedSegment*) clippedPairWithStart:(DKUIBezierPathIntersectionPoint *)_tStart andEnd:(DKUIBezierPathIntersectionPoint *)_tEnd andPathSegment:(UIBezierPath *)segment fromFullPath:(UIBezierPath*)_fullPath{
    return [[DKUIBezierPathClippedSegment alloc] initWithStart:_tStart andEnd:_tEnd andPathSegment:segment fromFullPath:_fullPath];
}

-(id) initWithStart:(DKUIBezierPathIntersectionPoint *)_tStart andEnd:(DKUIBezierPathIntersectionPoint *)_tEnd andPathSegment:(UIBezierPath *)segment fromFullPath:(UIBezierPath*)_fullPath{
    if(self = [super init]){
        startIntersection = _tStart;
        endIntersection = _tEnd;
        pathSegment1 = segment;
        fullPath = _fullPath;
    }
    return self;
}

-(DKUIBezierPathClippedSegment*) flippedRedBlueSegment{
    DKUIBezierPathClippedSegment* flippedSeg = [DKUIBezierPathClippedSegment clippedPairWithStart:[startIntersection flipped] andEnd:[endIntersection flipped] andPathSegment:pathSegment1 fromFullPath:fullPath];
    [flippedSeg setIsReversed:self.isReversed];
    return flippedSeg;
}

-(NSString*) description{
    return [NSString stringWithFormat:@"[Segment: p1(%d:%f => %d:%f) p2(%d:%f => %d:%f)]",
            (int)startIntersection.elementIndex1, startIntersection.tValue1, (int)endIntersection.elementIndex1, endIntersection.tValue1,
            (int)startIntersection.elementIndex2, startIntersection.tValue2, (int)endIntersection.elementIndex2, endIntersection.tValue2];
}

-(BOOL) canBePrependedTo:(DKUIBezierPathClippedSegment*)otherPath{
    if(otherPath.startIntersection == self.endIntersection){
        return YES;
    }
    if(otherPath.startIntersection.elementIndex1 == 0 &&
       otherPath.startIntersection.tValue1 == 0 &&
       self.endIntersection.elementIndex1 == fullPath.elementCount - 1 &&
       self.endIntersection.tValue1 == 1){
        return YES;
    }
    return NO;
}

-(DKUIBezierPathClippedSegment*) prependTo:(DKUIBezierPathClippedSegment*)otherSegment{
    UIBezierPath* combinedPathSegment = [self.pathSegment1 copy];
    [combinedPathSegment appendPathRemovingInitialMoveToPoint:otherSegment.pathSegment1];
    return [DKUIBezierPathClippedSegment clippedPairWithStart:self.startIntersection
                                                                       andEnd:otherSegment.endIntersection
                                                               andPathSegment:combinedPathSegment
                                                                 fromFullPath:self.fullPath];
}

-(DKUIBezierPathClippedSegment*) reversedSegment{
    if(reversedFrom){
        return reversedFrom;
    }
    DKUIBezierPathClippedSegment* ret = [DKUIBezierPathClippedSegment clippedPairWithStart:self.endIntersection andEnd:self.startIntersection andPathSegment:[self.pathSegment1 bezierPathByReversingPath] fromFullPath:self.fullPath];
    [ret setIsReversed:!isReversed];
    [ret setReversedFrom:self];
    [self setReversedFrom:ret];
    return ret;
}

-(BOOL) isEqual:(id)object{
    return object == self || ([object isKindOfClass:[DKUIBezierPathClippedSegment class]] && [object reversedSegment] == self);
}

-(BOOL) isEqualToSegment:(DKUIBezierPathClippedSegment*)otherSegment{
    return [otherSegment isKindOfClass:[DKUIBezierPathClippedSegment class]] &&
    [self.startIntersection isEqualToIntersection:otherSegment.startIntersection] &&
    [self.endIntersection isEqualToIntersection:otherSegment.endIntersection] &&
    self.isReversed == otherSegment.isReversed;
}

-(NSUInteger) hash{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + [startIntersection hash];
    result = prime * result + [endIntersection hash];
    result = prime * result + ((isReversed)?1231:1237);
    return result;
}


/**
 * calculates the angle between this segment's endpoint and the
 * otherInter's startpoint
 */
-(CGFloat) angleBetween:(DKUIBezierPathClippedSegment*)otherInter{
    return [[self endVector] angleBetween:[otherInter startVector]];
}

-(DKVector*) endVector{
    return [self.pathSegment1 tangentNearEnd].tangent;
}

-(DKVector*) startVector{
    return [self.pathSegment1 tangentNearStart].tangent;
}


@end

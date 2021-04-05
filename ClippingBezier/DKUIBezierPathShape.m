//
//  DKUIBezierPathShape.m
//  ClippingBezier
//
//  Created by Adam Wulf on 11/18/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import "DKUIBezierPathShape.h"
#import "DKUIBezierPathClippedSegment.h"
#import "PerformanceBezier.h"
#import "UIBezierPath+Trimming.h"

@implementation DKUIBezierPathShape

@synthesize segments;
@synthesize holes;

- (id)init
{
    if (self = [super init]) {
        segments = [NSMutableArray array];
        holes = [NSMutableArray array];
    }
    return self;
}


- (DKUIBezierPathIntersectionPoint *)startingPoint
{
    return [[segments firstObject] startIntersection];
}

- (DKUIBezierPathIntersectionPoint *)endingPoint
{
    return [[segments lastObject] endIntersection];
}

- (BOOL)isClosed
{
    return [[self startingPoint] matchesElementEndpointWithIntersection:[self endingPoint]];
}

- (UIBezierPath *)fullPath
{
    UIBezierPath *outputPath = [[[segments firstObject] pathSegment] copy];
    for (int i = 1; i < [segments count]; i++) {
        DKUIBezierPathClippedSegment *seg = [segments objectAtIndex:i];
        [outputPath appendPathRemovingInitialMoveToPoint:[seg pathSegment]];
    }
    if ([self isClosed]) {
        [outputPath closePath];
    } else {
        NSLog(@"unclosed shape??");
    }
    BOOL selfIsClockwise = [outputPath isClockwise];
    for (DKUIBezierPathShape *hole in holes) {
        UIBezierPath *holePath = hole.fullPath;
        if ([holePath isClockwise] == selfIsClockwise) {
            holePath = [holePath bezierPathByReversingPath];
        }
        [outputPath appendPath:holePath];
    }
    return outputPath;
}

- (BOOL)isSameShapeAs:(DKUIBezierPathShape *)otherShape
{
    if ([self.holes count] != [otherShape.holes count]) {
        // shortcut. if we don't have the same number of segments,
        // then we're not the same shape
        return NO;
    }
    if ([self.segments count] != [otherShape.segments count]) {
        // shortcut. if we don't have the same number of segments,
        // then we're not the same shape
        return NO;
    }
    __block BOOL foundAllSegments = YES;
    [self.segments enumerateObjectsUsingBlock:^(id obj1, NSUInteger idx, BOOL *stop) {
        if ([self.segments count] == 1 && [otherShape.segments count] == 1) {
            // special case if the shape is a single red segment
            // and we're comparing to our reversed single red segment
            if ([[self.segments firstObject] isEqualToSegment:[otherShape.segments firstObject]] ||
                [[[self.segments firstObject] reversedSegment] isEqualToSegment:[otherShape.segments firstObject]]) {
                foundAllSegments = YES;
                stop[0] = YES;
                return;
            }
        }
        __block BOOL foundSegment = NO;
        [otherShape.segments enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx, BOOL *stop) {
            if ([obj1 isEqualToSegment:obj2]) {
                foundSegment = YES;
                stop[0] = YES;
            }
        }];
        if (!foundSegment) {
            foundAllSegments = NO;
            stop[0] = YES;
        }
    }];
    __block BOOL foundAllShapes = YES;
    [self.holes enumerateObjectsUsingBlock:^(id obj1, NSUInteger idx, BOOL *stop) {
        __block BOOL foundHole = NO;
        [otherShape.holes enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx, BOOL *stop) {
            if ([obj1 isSameShapeAs:obj2]) {
                foundHole = YES;
                stop[0] = YES;
            }
        }];
        if (!foundHole) {
            foundAllShapes = NO;
            stop[0] = YES;
        }
    }];

    return foundAllSegments && foundAllShapes;
}

- (BOOL)sharesSegmentWith:(DKUIBezierPathShape *)otherShape
{
    for (DKUIBezierPathClippedSegment *otherSegment in otherShape.segments) {
        if ([self.segments containsObject:otherSegment]) {
            return YES;
        }
    }
    return NO;
}

- (DKUIBezierPathShape *)flippedShape
{
    DKUIBezierPathShape *flipped = [[DKUIBezierPathShape alloc] init];

    [[self segments] enumerateObjectsUsingBlock:^(DKUIBezierPathClippedSegment *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [[flipped segments] addObject:[obj flippedSegment]];
    }];

    [[self holes] enumerateObjectsUsingBlock:^(DKUIBezierPathShape *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [[flipped holes] addObject:[obj flippedShape]];
    }];

    return flipped;
}

- (DKUIBezierPathShape *)reversedShape
{
    DKUIBezierPathShape *flipped = [[DKUIBezierPathShape alloc] init];

    [[self segments] enumerateObjectsUsingBlock:^(DKUIBezierPathClippedSegment *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [[flipped segments] insertObject:[obj reversedSegment] atIndex:0];
    }];

    [[self holes] enumerateObjectsUsingBlock:^(DKUIBezierPathShape *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [[flipped holes] addObject:[obj reversedShape]];
    }];

    return flipped;
}

#pragma mark - Merge Shapes

- (BOOL)canGlueToShape:(DKUIBezierPathShape *)otherShape
{
    return [self sharesSegmentWith:[otherShape reversedShape]];
}


- (DKUIBezierPathShape *)glueToShape:(DKUIBezierPathShape *)otherShape
{
    if (![self canGlueToShape:otherShape]) {
        return nil;
    }

    NSMutableArray<DKUIBezierPathClippedSegment *> *mySegments = [[self segments] mutableCopy];
    NSMutableArray<DKUIBezierPathClippedSegment *> *otherSegments = [[otherShape segments] mutableCopy];

    NSInteger anyMatchedIndex = NSNotFound;

    for (NSInteger i = 0; i < [mySegments count]; i++) {
        DKUIBezierPathClippedSegment *mySegment = mySegments[i];
        if ([otherSegments containsObject:[mySegment reversedSegment]]) {
            anyMatchedIndex = i;
            break;
        }
    }

    if (anyMatchedIndex == NSNotFound) {
        return nil;
    }

    NSInteger firstMatchedIndex = anyMatchedIndex;

    for (NSInteger i = anyMatchedIndex + [mySegments count] - 1; i >= anyMatchedIndex; i--) {
        NSInteger trueIndex = i % [mySegments count];
        DKUIBezierPathClippedSegment *mySegment = mySegments[trueIndex];
        if ([otherSegments containsObject:[mySegment reversedSegment]]) {
            firstMatchedIndex = trueIndex;
        } else {
            break;
        }
    }

    DKUIBezierPathClippedSegment *myFirstMatchedSeg = mySegments[firstMatchedIndex];
    NSInteger otherIndex = [otherSegments indexOfObject:[myFirstMatchedSeg reversedSegment]];

    NSMutableArray<DKUIBezierPathClippedSegment *> *nonMatchingOtherSegments = [NSMutableArray array];

    for (NSInteger i = otherIndex; i < otherIndex + [otherSegments count]; i++) {
        NSInteger trueIndex = i % [otherSegments count];
        DKUIBezierPathClippedSegment *otherSegment = otherSegments[trueIndex];

        if (![mySegments containsObject:[otherSegment reversedSegment]]) {
            [nonMatchingOtherSegments addObject:otherSegment];
        }
    }

    NSMutableArray *unionShapeSegments = [mySegments mutableCopy];

    while (firstMatchedIndex < [unionShapeSegments count] && [otherSegments containsObject:[[unionShapeSegments objectAtIndex:firstMatchedIndex] reversedSegment]]) {
        [unionShapeSegments removeObjectAtIndex:firstMatchedIndex];
    }

    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(firstMatchedIndex, [nonMatchingOtherSegments count])];

    [unionShapeSegments insertObjects:nonMatchingOtherSegments atIndexes:indexes];

    // now find the first unmatched segment

    DKUIBezierPathShape *unionShape = [[DKUIBezierPathShape alloc] init];

    [[unionShape segments] addObjectsFromArray:unionShapeSegments];
    [[unionShape holes] addObjectsFromArray:[self holes]];
    [[unionShape holes] addObjectsFromArray:[otherShape holes]];

    return unionShape;
}


@end

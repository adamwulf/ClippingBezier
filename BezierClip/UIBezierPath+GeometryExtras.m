//
//  UIBezierPath+GeometryExtras.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 2/1/15.
//  Copyright (c) 2015 Adam Wulf. All rights reserved.
//

#import "UIBezierPath+GeometryExtras.h"
#import <DrawKit-iOS/DrawKit-iOS.h>

@implementation UIBezierPath (GeometryExtras)


// this will return YES if self contains
// a subpath and that subpath's reverse
-(BOOL) containsDuplicateAndReversedSubpaths{
    NSArray* allSubpaths = [self subPaths];
    
    for (UIBezierPath* subpath in allSubpaths) {
        for (UIBezierPath* subpath2 in allSubpaths) {
            UIBezierPath* reversedSubpath = [subpath bezierPathByReversingPath];
            UIBezierPath* reversedSubpath2 = [subpath2 bezierPathByReversingPath];
            if([reversedSubpath isEqualToBezierPath:subpath2]){
                return YES;
            }else if([reversedSubpath2 isEqualToBezierPath:subpath]){
                return YES;
            }
        }
    }
    return NO;
}

-(CGPoint) closestPointOnPathTo:(CGPoint)pointNearTheCurve{
    NSInteger index;
    double tValue;
    return [self closestPointOnPathTo:pointNearTheCurve atIndex:&index andElementTValue:&tValue hopefulEndPoint:CGPointZero startIndexBeforeEndIndex:nil];
}

/**
 * This is an awkward method definition, but the last two arguments
 * are to help optimize bezierPathByTrimmingFromClosestPointOnPathFrom:
 *
 * sending back a BOOL for if the start element occurs before the end index
 * helps save a call to this method, so that bezierPathByTrimmingFromClosestPointOnPathFrom:
 * only ever calls this method twice, instead of sometimes 3 times in the case where
 * start is before end
 */
-(CGPoint) closestPointOnPathTo:(CGPoint)pointNearTheCurve atIndex:(NSInteger*)elementIndex andElementTValue:(double*)tValue hopefulEndPoint:(CGPoint)endPoint startIndexBeforeEndIndex:(BOOL*)happensBefore{
    __block double winningTValue = 0;
    __block NSInteger winningIndex = -1;
    __block CGPoint winningPoint = CGPointZero;
    __block CGPoint previousEndpoint;
    
    
    __block CGPoint winningEndPoint = CGPointZero;
    __block NSInteger winningEndIndex = -1;
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex){
        CGPoint np1 = CGPointZero;
        CGPoint np2 = CGPointZero;
        double currTValue = 0.0;
        if(element.type == kCGPathElementAddCurveToPoint )
        {
            // curve
            CGPoint bez[4];
            bez[0] = previousEndpoint;
            bez[1] = element.points[0];
            bez[2] = element.points[1];
            bez[3] = element.points[2];
            
            np1 = NearestPointOnCurve(pointNearTheCurve, bez, &currTValue );
            np2 = NearestPointOnCurve(endPoint, bez, nil );
            previousEndpoint = element.points[2];
        }else if(element.type == kCGPathElementMoveToPoint){
            np1 = element.points[0];
            np2 = element.points[0];
            previousEndpoint = element.points[0];
            currTValue = 1;
        }else if(element.type == kCGPathElementAddLineToPoint){
            np1 = NearestPointOnLine( pointNearTheCurve, previousEndpoint, element.points[0] );
            np2 = NearestPointOnLine( endPoint, previousEndpoint, element.points[0] );
            currTValue = RelPoint( np1, previousEndpoint, element.points[0] );
            previousEndpoint = element.points[0];
        }
        
        if(!CGPointEqualToPoint(np1, CGPointZero)){
            // check start
            if(CGPointEqualToPoint(winningPoint, CGPointZero)){
                winningPoint = np1;
                winningIndex = currentIndex;
                winningTValue = currTValue;
            }else if(LineLength(pointNearTheCurve, np1) < LineLength(pointNearTheCurve, winningPoint)){
                winningPoint = np1;
                winningIndex = currentIndex;
                winningTValue = currTValue;
            }
        }
        if(!CGPointEqualToPoint(np2, CGPointZero)){
            // check end
            if(CGPointEqualToPoint(winningEndPoint, CGPointZero)){
                winningEndPoint = np2;
                winningEndIndex = currentIndex;
            }else if(LineLength(endPoint, np2) < LineLength(endPoint, winningEndPoint)){
                winningEndPoint = np2;
                winningEndIndex = currentIndex;
            }
        }
    }];
    tValue[0] = winningTValue;
    elementIndex[0] = winningIndex;
    if(happensBefore) happensBefore[0] = (winningIndex < winningEndIndex);
    return winningPoint;
}

/**
 * This will return a new curve that loops from the start point to the end point,
 * even if the start point is later in the curve than the end point, it will
 * loop back to the beginning.
 *
 * if the points are the same, it will return a moveto + lineto the same point
 */
-(UIBezierPath*) bezierPathByTrimmingFromClosestPointOnPathFrom:(CGPoint)pointNearTheCurve to:(CGPoint)toPoint{
    
    UIBezierPath* outputPath = [UIBezierPath bezierPath];
    NSInteger startIndex, endIndex;
    double startTValue, endTValue;
    
    BOOL startHappensBeforeTheEnd;
    
    // calculate our starting and ending
    // element indexes and their tvalues
    CGPoint startPoint = [self closestPointOnPathTo:pointNearTheCurve
                                            atIndex:&startIndex
                                   andElementTValue:&startTValue
                                    hopefulEndPoint:toPoint
                           startIndexBeforeEndIndex:&startHappensBeforeTheEnd];
    
    
    
    // now we know the start/end element and tvalues
    // so we need to chop the curve into a smaller
    // segment
    if(CGPointEqualToPoint(pointNearTheCurve, toPoint)){
        // simple base case where the input
        // is a single point
        [outputPath moveToPoint:startPoint];
        [outputPath addLineToPoint:startPoint];
        return outputPath;
    }
    
    if(startHappensBeforeTheEnd){
        // the start happens before the end
        UIBezierPath* fromStartPath = [self bezierPathByTrimmingFromElement:startIndex andTValue:startTValue];
        // the fromStartPath path will have different indexes than we do
        // so we need to recalculate the end index and t values
        [fromStartPath closestPointOnPathTo:toPoint atIndex:&endIndex andElementTValue:&endTValue hopefulEndPoint:CGPointZero startIndexBeforeEndIndex:nil];
        // with the new end values, chop the path to our end point
        outputPath = [fromStartPath bezierPathByTrimmingToElement:endIndex andTValue:endTValue];
    }else{
        [self closestPointOnPathTo:toPoint atIndex:&endIndex andElementTValue:&endTValue hopefulEndPoint:CGPointZero startIndexBeforeEndIndex:nil];
        if(startIndex == endIndex){
            // the element starts and ends on the same element
            // so split it
            return [self bezierPathByTrimmingElement:startIndex fromTValue:MIN(startTValue, endTValue) toTValue:MAX(startTValue, endTValue)];
        }else if(startIndex > endIndex){
            // start happens after the end, so that means we'll need to loop from the end
            // back through the beginning of the path. this is the case if the start element is after the end element,
            // or if the start and end are the same element, but the start t value is later
            
            UIBezierPath* fromStartPath = [self bezierPathByTrimmingFromElement:startIndex andTValue:startTValue];
            UIBezierPath* toEndPath = [self bezierPathByTrimmingToElement:endIndex andTValue:endTValue];
            
            [fromStartPath appendPathRemovingInitialMoveToPoint:toEndPath];
            outputPath = fromStartPath;
        }
    }
    
    if([outputPath length] > [self length] / 2){
        // too long! swap the points
        return [self bezierPathByTrimmingFromClosestPointOnPathFrom:toPoint to:pointNearTheCurve];
    }
    
    return outputPath;
}

- (CGPoint) pointOnPathAtElement:(NSInteger)elementIndex andTValue:(CGFloat)tVal{
    if(elementIndex >= [self elementCount] || elementIndex < 0){
        @throw [NSException exceptionWithName:@"BezierElementException" reason:@"Element index is out of range" userInfo:nil];
    }
    if(elementIndex == 0){
        return self.firstPoint;
    }
    
    CGPoint bezier[4], left[4], right[4];
    
    [self fillBezier:bezier forElement:elementIndex];
    
    [UIBezierPath subdivideBezier:bezier intoLeft:left andRight:right atT:tVal];
    
    return left[3];
}



@end

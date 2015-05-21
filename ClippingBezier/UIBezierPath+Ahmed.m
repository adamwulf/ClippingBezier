//
//  UIBezierPath+Ahmed.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 10/6/12.
//  Copyright (c) 2012 Graceful Construction, LLC. All rights reserved.
//

#import "UIBezierPath+Ahmed.h"
#import <objc/runtime.h>
#import <PerformanceBezier/PerformanceBezier.h>


static CGFloat idealFlatness = .01;

@implementation UIBezierPath (Ahmed)


#pragma mark - Properties


/**
 * this is a property on the category, as described in:
 * https://github.com/techpaa/iProperties
 */
-(void)setIsFlat:(BOOL)isFlat{
    [self pathProperties].isFlat = isFlat;
}

/**
 * return YES if this bezier path is made up of only
 * moveTo, closePath, and lineTo elements
 *
 * TODO
 * this method helps caching flattened paths internally
 * to this category, but is not yet fit for public use.
 *
 * detecting when this path is flat would mean we'd have
 * to also swizzle the constructors to bezier paths
 */
-(BOOL) isFlat{
    return [self pathProperties].isFlat;
}

#pragma mark - UIBezierPath


/**
 * call this method on a UIBezierPath to generate
 * a new flattened path
 *
 * This category is named after Athar Luqman Ahmad, who
 * wrote a masters thesis about minimizing the number of
 * lines required to flatten a bezier curve
 *
 * The thesis is available here:
 * http://www.cis.usouthal.edu/~hain/general/Theses/Ahmad_thesis.pdf
 *
 * The algorithm that I use as of 10/09/2012 is a simple
 * recursive algorithm that doesn't use any of ahmed's
 * optimizations yet
 *
 * TODO: add in Ahmed's optimizations
 */
-(UIBezierPath*) bezierPathByFlatteningPath{
    return [self bezierPathByFlatteningPathAndImmutable:NO];
}
/**
 * @param shouldBeImmutable: YES if this function should return a distinct UIBezier, NO otherwise
 *
 * if the caller plans to modify the returned path, then shouldBeImmutable should
 * be called with NO.
 *
 * if the caller only plans to iterate over and look at the returned value,
 * then shouldBeImmutable should be YES - this is considerably faster to not
 * return a copy if the value will be treated as immutable
 */
-(UIBezierPath*) bezierPathByFlatteningPathAndImmutable:(BOOL)willBeImmutable{
    UIBezierPathProperties* props = [self pathProperties];
    UIBezierPath* ret = props.bezierPathByFlatteningPath;
    if(ret){
        if(willBeImmutable) return ret;
        return [[ret copy] autorelease];
    }
    if(self.isFlat){
        if(willBeImmutable) return self;
        return [[self copy] autorelease];
    }
    
    __block NSInteger flattenedElementCount = 0;
	UIBezierPath *newPath = [UIBezierPath bezierPath];
	NSInteger	       elements = [self elementCount];
	NSInteger	       n;
	CGPoint    pointForClose = CGPointMake (0.0, 0.0);
	CGPoint    lastPoint = CGPointMake (0.0, 0.0);
    
	for (n = 0; n < elements; ++n)
	{
		CGPoint		points[3];
		CGPathElement element = [self elementAtIndex:n associatedPoints:points];
        
		switch (element.type)
		{
			case kCGPathElementMoveToPoint:
				[newPath moveToPoint:points[0]];
				pointForClose = lastPoint = points[0];
                flattenedElementCount++;
				continue;
                
			case kCGPathElementAddLineToPoint:
                [newPath addLineToPoint:points[0]];
				lastPoint = points[0];
                flattenedElementCount++;
				break;
                
            case kCGPathElementAddQuadCurveToPoint:
			case kCGPathElementAddCurveToPoint:
			{

                //
                // handle both curve types gracefully
                CGPoint curveTo;
                CGPoint ctrl1;
                CGPoint ctrl2;
                if(element.type == kCGPathElementAddQuadCurveToPoint){
                    curveTo = element.points[1];
                    ctrl1 = element.points[0];
                    ctrl2 = ctrl1;
                }else if(element.type == kCGPathElementAddCurveToPoint){
                    curveTo = element.points[2];
                    ctrl1 = element.points[0];
                    ctrl2 = element.points[1];
                }
                
                //
                // ok, this is the bezier for our current element
				CGPoint bezier[4] = { lastPoint, ctrl1, ctrl2, curveTo };
                

                //
                // define our recursive function that will
                // help us split the curve up as needed
                void (^__block flattenCurve)(UIBezierPath* newPath, CGPoint startPoint, CGPoint bez[4]) = ^(UIBezierPath* newPath, CGPoint startPoint, CGPoint bez[4]){
                    //
                    // first, calculate the error rate for
                    // a line segement between the start/end points
                    // vs the curve
                    
                    CGPoint onCurve = bezierPointAtT(bez, .5);
                    
                    CGFloat error = distanceOfPointToLine(onCurve, startPoint, bez[2]);
                    
                    
                    //
                    // if that error is less than our accepted
                    // level of error, then just add a line,
                    //
                    // otherwise, split the curve in half and recur
                    if (error <= idealFlatness)
                    {
                        [newPath addLineToPoint:bez[3]];
                        flattenedElementCount++;
                    }
                    else
                    {
                        CGPoint bez1[4], bez2[4];
                        subdivideBezierAtT(bez, bez1, bez2, .5);
                        // now we've split the curve in half, and have
                        // two bezier curves bez1 and bez2. recur
                        // on these two halves
                        flattenCurve(newPath, startPoint, bez1);
                        flattenCurve(newPath, startPoint, bez2);
                    }
                };
                
                flattenCurve(newPath, lastPoint, bezier);
                
				lastPoint = points[2];
				break;
			}
                
			case kCGPathElementCloseSubpath:
                [newPath closePath];
				lastPoint = pointForClose;
                flattenedElementCount++;
				break;
				
			default:
				break;
		}
	}

    // since we just built the flattened path
    // we know how many elements there are, so cache that
    UIBezierPathProperties* newPathProps = [newPath pathProperties];
    newPathProps.cachedElementCount = flattenedElementCount;
    
    props.bezierPathByFlatteningPath = newPath;

    return [self bezierPathByFlatteningPathAndImmutable:willBeImmutable];
}




/**
 * this will trim a specific element from a tvalue to a tvalue
 */
-(UIBezierPath*) bezierPathByTrimmingElement:(NSInteger)elementIndex fromTValue:(double)fromTValue toTValue:(double)toTValue{
    __block CGPoint previousEndpoint;
    __block UIBezierPath* outputPath = [UIBezierPath bezierPath];
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex){
        if(currentIndex < elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                previousEndpoint = element.points[2];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                previousEndpoint = element.points[0];
            }
        }else if(currentIndex == elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:element.points[0]];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                CGPoint bez[4];
                bez[0] = previousEndpoint;
                bez[1] = element.points[0];
                bez[2] = element.points[1];
                bez[3] = element.points[2];
                
                previousEndpoint = element.points[2];
                
                CGPoint left[4], right[4];
                subdivideBezierAtT(bez, left, right, toTValue);
                bez[0] = left[0];
                bez[1] = left[1];
                bez[2] = left[2];
                bez[3] = left[3];
                subdivideBezierAtT(bez, left, right, fromTValue / toTValue);
                [outputPath moveToPoint:right[0]];
                [outputPath addCurveToPoint:right[3] controlPoint1:right[1] controlPoint2:right[2]];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                CGPoint startPoint = CGPointMake(previousEndpoint.x + fromTValue * (element.points[0].x - previousEndpoint.x),
                                                 previousEndpoint.y + fromTValue * (element.points[0].y - previousEndpoint.y));
                CGPoint endPoint = CGPointMake(previousEndpoint.x + toTValue * (element.points[0].x - previousEndpoint.x),
                                               previousEndpoint.y + toTValue * (element.points[0].y - previousEndpoint.y));
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:startPoint];
                [outputPath addLineToPoint:endPoint];
            }
        }
    }];
    
    return outputPath;
}




/**
 * this will trim a uibezier path from the input element index
 * and that element's tvalue. it will return all elements after
 * that input
 */
-(UIBezierPath*) bezierPathByTrimmingFromElement:(NSInteger)elementIndex andTValue:(double)tValue{
    __block CGPoint previousEndpoint;
    __block UIBezierPath* outputPath = [UIBezierPath bezierPath];
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex){
        if(currentIndex < elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                previousEndpoint = element.points[2];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                previousEndpoint = element.points[0];
            }
        }else if(currentIndex == elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:element.points[0]];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                CGPoint bez[4];
                bez[0] = previousEndpoint;
                bez[1] = element.points[0];
                bez[2] = element.points[1];
                bez[3] = element.points[2];
                
                previousEndpoint = element.points[2];
                
                CGPoint left[4], right[4];
                subdivideBezierAtT(bez, left, right, tValue);
                [outputPath moveToPoint:right[0]];
                [outputPath addCurveToPoint:right[3] controlPoint1:right[1] controlPoint2:right[2]];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                CGPoint startPoint = CGPointMake(previousEndpoint.x + tValue * (element.points[0].x - previousEndpoint.x),
                                                 previousEndpoint.y + tValue * (element.points[0].y - previousEndpoint.y));
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:startPoint];
                [outputPath addLineToPoint:element.points[0]];
            }
        }else if(currentIndex > elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:element.points[0]];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                previousEndpoint = element.points[2];
                [outputPath addCurveToPoint:element.points[2] controlPoint1:element.points[0] controlPoint2:element.points[1]];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                previousEndpoint = element.points[0];
                [outputPath addLineToPoint:element.points[0]];
            }
        }
    }];
    
    return outputPath;
}

/**
 * this will trim a uibezier path to the input element index
 * and that element's tvalue. it will return all elements before
 * that input
 */
-(UIBezierPath*) bezierPathByTrimmingToElement:(NSInteger)elementIndex andTValue:(double)tValue{
    __block CGPoint previousEndpoint;
    __block UIBezierPath* outputPath = [UIBezierPath bezierPath];
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex){
        if(currentIndex == elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:element.points[0]];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                CGPoint bez[4];
                bez[0] = previousEndpoint;
                bez[1] = element.points[0];
                bez[2] = element.points[1];
                bez[3] = element.points[2];
                
                previousEndpoint = element.points[2];
                
                CGPoint left[4], right[4];
                subdivideBezierAtT(bez, left, right, tValue);
                [outputPath addCurveToPoint:left[3] controlPoint1:left[1] controlPoint2:left[2]];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                CGPoint endPoint = CGPointMake(previousEndpoint.x + tValue * (element.points[0].x - previousEndpoint.x),
                                               previousEndpoint.y + tValue * (element.points[0].y - previousEndpoint.y));
                previousEndpoint = element.points[0];
                [outputPath addLineToPoint:endPoint];
            }
        }else if(currentIndex < elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:element.points[0]];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                previousEndpoint = element.points[2];
                [outputPath addCurveToPoint:element.points[2] controlPoint1:element.points[0] controlPoint2:element.points[1]];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                previousEndpoint = element.points[0];
                [outputPath addLineToPoint:element.points[0]];
            }
        }
    }];
    
    return outputPath;
}

@end

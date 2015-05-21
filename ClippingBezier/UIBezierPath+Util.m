//
//  UIBezierPath+Util.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/20/15.
//
//

#import "UIBezierPath+Util.h"
#import <PerformanceBezier/PerformanceBezier.h>

@implementation UIBezierPath (Util)

+(void) subdivideBezier:(const CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2 atT:(CGFloat)t{
    subdivideBezierAtT(bez, bez1, bez2, t);
}


+(void) subdivideBezier:(const CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2{
    subdivideBezierAtT(bez, bez1, bez2, .5);
}

+(void) subdivideBezier:(const CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2 atLength:(CGFloat)length withAcceptableError:(CGFloat)acceptableError withCache:(CGFloat*) subBezierlengthCache{
    subdivideBezierAtLength(bez, bez1, bez2, length, acceptableError,subBezierlengthCache);
}

+(CGFloat) lengthOfBezier:(const CGPoint[4])bez withAccuracy:(CGFloat)accuracy{
    return lengthOfBezier(bez, accuracy);
}

/**
 * will divide a bezier curve into two curves at time t
 * 0 <= t <= 1.0
 *
 * these two curves will exactly match the former single curve
 */
static inline void subdivideBezierAtT(const CGPoint bez[4], CGPoint bez1[4], CGPoint bez2[4], CGFloat t){
    CGPoint q;
    CGFloat mt = 1 - t;
    
    bez1[0].x = bez[0].x;
    bez1[0].y = bez[0].y;
    bez2[3].x = bez[3].x;
    bez2[3].y = bez[3].y;
    
    q.x = mt * bez[1].x + t * bez[2].x;
    q.y = mt * bez[1].y + t * bez[2].y;
    bez1[1].x = mt * bez[0].x + t * bez[1].x;
    bez1[1].y = mt * bez[0].y + t * bez[1].y;
    bez2[2].x = mt * bez[2].x + t * bez[3].x;
    bez2[2].y = mt * bez[2].y + t * bez[3].y;
    
    bez1[2].x = mt * bez1[1].x + t * q.x;
    bez1[2].y = mt * bez1[1].y + t * q.y;
    bez2[1].x = mt * q.x + t * bez2[2].x;
    bez2[1].y = mt * q.y + t * bez2[2].y;
    
    bez1[3].x = bez2[0].x = mt * bez1[2].x + t * bez2[1].x;
    bez1[3].y = bez2[0].y = mt * bez1[2].y + t * bez2[1].y;
}

/**
 * estimates the length along the curve of the
 * input bezier within the input acceptableError
 */
CGFloat lengthOfBezier(const CGPoint bez[4], CGFloat acceptableError){
    CGFloat   polyLen = 0.0;
    CGFloat   chordLen = distance (bez[0], bez[3]);
    CGFloat   retLen, errLen;
    NSUInteger n;
    
    for (n = 0; n < 3; ++n)
        polyLen += distance (bez[n], bez[n + 1]);
    
    errLen = polyLen - chordLen;
    
    if (errLen > acceptableError) {
        CGPoint left[4], right[4];
        [UIBezierPath subdivideBezier:bez intoLeft:left andRight:right];
        retLen = (lengthOfBezier (left, acceptableError)
                  + lengthOfBezier (right, acceptableError));
    } else {
        retLen = 0.5 * (polyLen + chordLen);
    }
    
    return retLen;
}

/**
 * will split the input bezier curve at the input length
 * within a given margin of error
 *
 * the two curves will exactly match the original curve
 */
static CGFloat subdivideBezierAtLength (const CGPoint bez[4],
                                        CGPoint bez1[4],
                                        CGPoint bez2[4],
                                        CGFloat length,
                                        CGFloat acceptableError,
                                        CGFloat* subBezierlengthCache){
    CGFloat top = 1.0, bottom = 0.0;
    CGFloat t, prevT;
    
    prevT = t = 0.5;
    for (;;) {
        CGFloat len1;
        
        subdivideBezierAtT (bez, bez1, bez2, t);
        
        int lengthCacheIndex = (int)floorf(t*1000);
        len1 = subBezierlengthCache[lengthCacheIndex];
        if(!len1){
            len1 = [UIBezierPath lengthOfBezier:bez1 withAccuracy:0.5 * acceptableError];
            subBezierlengthCache[lengthCacheIndex] = len1;
        }
        
        if (fabs (length - len1) < acceptableError){
            return len1;
        }
        
        if (length > len1) {
            bottom = t;
            t = 0.5 * (t + top);
        } else if (length < len1) {
            top = t;
            t = 0.5 * (bottom + t);
        }
        
        if (t == prevT){
            subBezierlengthCache[lengthCacheIndex] = len1;
            return len1;
        }
        
        prevT = t;
    }
}



@end

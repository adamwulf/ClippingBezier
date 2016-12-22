//
//  UIBezierPath+Ahmed.h
//  ClippingBezier
//
//  Created by Adam Wulf on 10/6/12.
//  Copyright (c) 2012 Graceful Construction, LLC. All rights reserved.
//
//
//
//
// This category is based on the masters thesis
// APPROXIMATION OF A BÉZIER CURVE WITH A MINIMAL NUMBER OF LINE SEGMENTS
// by Athar Luqman Ahmad
// available at http://www.cis.usouthal.edu/~hain/general/Theses/Ahmad_thesis.pdf
//
// More information available at
// http://www.cis.usouthal.edu/~hain/general/Thesis.htm

#import <UIKit/UIKit.h>
#include <math.h>



@interface UIBezierPath (Ahmed)

@property(nonatomic,readonly) UIBezierPath* bezierPathByFlatteningPath;

@property(nonatomic,assign) BOOL isFlat;

-(UIBezierPath*) bezierPathByFlatteningPath;
-(UIBezierPath*) bezierPathByFlatteningPathAndImmutable:(BOOL)returnCopy;

-(UIBezierPath*) bezierPathByTrimmingElement:(NSInteger)elementIndex fromTValue:(double)fromTValue toTValue:(double)toTValue;
-(UIBezierPath*) bezierPathByTrimmingToElement:(NSInteger)elementIndex andTValue:(double)tValue;
-(UIBezierPath*) bezierPathByTrimmingFromElement:(NSInteger)elementIndex andTValue:(double)tValue;

@end

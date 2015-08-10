//
//  MMVector.h
//  ClippingBezier
//
//  Created by Adam Wulf on 7/11/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DKVector : NSObject

@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;

+(id) vectorWithPoint:(CGPoint)p1 andPoint:(CGPoint)p2;

+(id) vectorWithX:(CGFloat)x andY:(CGFloat)y;

+(id) vectorWithAngle:(CGFloat)angle;

-(id) initWithPoint:(CGPoint)p1 andPoint:(CGPoint)p2;

-(id) initWithX:(CGFloat)x andY:(CGFloat)y;

-(DKVector*) normal;

-(DKVector*) perpendicular;

-(DKVector*) flip;

-(CGFloat) magnitude;

-(CGFloat) angle;

-(CGPoint) pointFromPoint:(CGPoint)point distance:(CGFloat)distance;

-(DKVector*) averageWith:(DKVector*)vector;

-(DKVector*) rotateBy:(CGFloat)angle;

-(DKVector*) mirrorAround:(DKVector*)normal;

-(CGPoint) mirrorPoint:(CGPoint)point aroundPoint:(CGPoint)startPoint;

-(CGFloat) angleBetween:(DKVector*)otherVector;

-(CGPoint) asCGPoint;
@end

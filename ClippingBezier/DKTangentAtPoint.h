//
//  DKTangentAtPoint.h
//  ClippingBezier
//
//  Created by Adam Wulf on 11/25/13.
//  Copyright (c) 2013 Adam Wulf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKVector.h"

@interface DKTangentAtPoint : NSObject

@property (nonatomic, readonly) DKVector* tangent;
@property (nonatomic, readonly) CGPoint point;

+(DKTangentAtPoint*) tangent:(DKVector*)tangent atPoint:(CGPoint)point;

@end

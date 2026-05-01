//
//  DKIntersectionOfPaths.h
//  BezierClip
//
//  Created by Adam Wulf on 2/9/15.
//
//

#import <UIKit/UIKit.h>

@interface DKIntersectionOfPaths : NSObject

@property(assign) BOOL doesIntersect;
@property(assign) int elementNumberOfIntersection;
@property(assign) float tValueOfIntersection;
@property(strong) UIBezierPath *start;
@property(strong) UIBezierPath *end;

@end

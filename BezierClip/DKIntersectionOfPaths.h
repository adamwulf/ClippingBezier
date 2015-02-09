//
//  DKIntersectionOfPaths.h
//  BezierClip
//
//  Created by Adam Wulf on 2/9/15.
//
//

#import <UIKit/UIKit.h>

@interface DKIntersectionOfPaths : NSObject

@property (assign) BOOL doesIntersect;
@property (assign) int elementNumberOfIntersection;
@property (assign) float tValueOfIntersection;
@property (assign) __unsafe_unretained UIBezierPath* start;
@property (assign) __unsafe_unretained UIBezierPath* end;

@end

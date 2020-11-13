//
//  UIBezierPath+SamplePaths.h
//  ClippingExampleApp
//
//  Created by Adam Wulf on 5/8/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBezierPath (SamplePaths)

+ (UIBezierPath *)complexShape1;
+ (UIBezierPath *)complexShape2;

+ (UIBezierPath *)splitterPath;
+ (UIBezierPath *)splittingPath;

+ (UIBezierPath *)simpleBox1;
+ (UIBezierPath *)simpleBox2;

+ (UIBezierPath *)debug1;
+ (UIBezierPath *)debug2;

+ (UIBezierPath *)union1;
+ (UIBezierPath *)union2;

@end

NS_ASSUME_NONNULL_END

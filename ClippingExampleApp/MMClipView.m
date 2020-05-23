//
//  MMClipView.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/23/15.
//
//

#import "MMClipView.h"
#import "UIBezierPath+SamplePaths.h"
#import <ClippingBezier/ClippingBezier.h>
#import <ClippingBezier/UIBezierPath+Clipping_Private.h>

@interface UIBezierPath (Private)

- (DKUIBezierPathClippingResult *)clipUnclosedPathToClosedPath:(UIBezierPath *)closedPath usingIntersectionPoints:(NSArray *)intersectionPoints andBeginsInside:(BOOL)beginsInside;

@end

@interface MMClipView ()

@property(nonatomic, readwrite) IBOutlet UISegmentedControl *displayTypeControl;

@end

@implementation MMClipView {
    UIBezierPath *shapePath1;
    UIBezierPath *shapePath2;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    shapePath1 = [UIBezierPath samplePath1];
    shapePath2 = [UIBezierPath samplePath2];
}

- (IBAction)changedPreviewType:(id)sender
{
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointMake(100, 20)];
    [path1 addLineToPoint:CGPointMake(50, 20)];
    [path1 addLineToPoint:CGPointMake(50, 80)];
    [path1 addLineToPoint:CGPointMake(100, 80)];
    [path1 addLineToPoint:CGPointMake(100, 100)];
    [path1 addLineToPoint:CGPointMake(0, 100)];
    [path1 addLineToPoint:CGPointMake(0, 0)];
    [path1 addLineToPoint:CGPointMake(100, 0)];
    [path1 addLineToPoint:CGPointMake(100, 20)];
    [path1 closePath];

    UIBezierPath *path2 = [UIBezierPath bezierPath];
    [path2 moveToPoint:CGPointMake(70, 10)];
    [path2 addLineToPoint:CGPointMake(80, 10)];
    [path2 addLineToPoint:CGPointMake(80, 90)];
    [path2 addLineToPoint:CGPointMake(70, 90)];
    [path2 addLineToPoint:CGPointMake(70, 10)];
    [path2 closePath];

    NSArray<UIBezierPath *> *finalShapes = [path1 unionWithPath:path2];

    [[UIColor blueColor] setStroke];
    [[finalShapes firstObject] setLineWidth:1];
    [[finalShapes firstObject] applyTransform:CGAffineTransformMakeTranslation(100, 100)];
    [[finalShapes firstObject] stroke];
}

+ (UIColor *)randomColor
{
    static BOOL generated = NO;

    // ff the randomColor hasn't been generated yet,
    // reset the time to generate another sequence
    if (!generated) {
        generated = YES;
        srandom((int)time(NULL));
    }

    // generate a random number and divide it using the
    // maximum possible number random() can be generated
    CGFloat red = (CGFloat)random() / (CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random() / (CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random() / (CGFloat)RAND_MAX;

    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
    return color;
}


@end

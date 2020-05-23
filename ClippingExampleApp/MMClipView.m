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
    UIBezierPath *shapePath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 100, 100)];
    UIBezierPath *scissorPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 200, 100)];

    shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint:CGPointMake(0, 0)];
    [shapePath addLineToPoint:CGPointMake(100, 0)];
    [shapePath addLineToPoint:CGPointMake(100, 100)];
    [shapePath addLineToPoint:CGPointMake(0, 100)];
    [shapePath addLineToPoint:CGPointMake(0, 0)];
    [shapePath closePath];

    scissorPath = [UIBezierPath bezierPath];
    [scissorPath moveToPoint:CGPointMake(0, 0)];
    [scissorPath addLineToPoint:CGPointMake(200, 0)];
    [scissorPath addLineToPoint:CGPointMake(200, 100)];
    [scissorPath addLineToPoint:CGPointMake(0, 100)];
    [scissorPath addLineToPoint:CGPointMake(0, 0)];
    [scissorPath closePath];

    NSArray *redBlueSegs = [UIBezierPath redAndBlueSegmentsForShapeBuildingCreatedFrom:shapePath bySlicingWithPath:scissorPath andNumberOfBlueShellSegments:nil];
    NSArray<DKUIBezierPathClippedSegment *> *redSegments = [redBlueSegs firstObject];
    NSArray<DKUIBezierPathClippedSegment *> *blueSegments = [redBlueSegs lastObject];

    for (DKUIBezierPathClippedSegment *segment in redSegments) {
        UIBezierPath *path = [[segment pathSegment] copy];
        [path applyTransform:CGAffineTransformMakeTranslation(100, 100)];
        [path setLineWidth:10];
        [[UIColor redColor] setStroke];
        [path stroke];
    }

    for (DKUIBezierPathClippedSegment *segment in blueSegments) {
        UIBezierPath *path = [[segment pathSegment] copy];
        [path applyTransform:CGAffineTransformMakeTranslation(100, 100)];
        [path setLineWidth:5];
        [[UIColor blueColor] setStroke];
        [path stroke];
    }


    NSArray *colors = @[[UIColor redColor], [UIColor blueColor], [UIColor purpleColor], [UIColor orangeColor]];
    NSArray *shapes = [shapePath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];

    for (NSInteger i = 0; i < [shapes count]; i++) {
        UIBezierPath *path = [[shapes[i] fullPath] copy];
        [path applyTransform:CGAffineTransformMakeTranslation(100, 300)];
        [path setLineWidth:(i + 1) * 10 / [shapes count]];
        [colors[i] setStroke];
        [path stroke];
    }
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

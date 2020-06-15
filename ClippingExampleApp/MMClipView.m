//
//  MMClipView.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/23/15.
//
//

#import "MMClipView.h"
#import "UIBezierPath+SamplePaths.h"
#import <PerformanceBezier/PerformanceBezier.h>
#import <ClippingBezier/ClippingBezier.h>
#import <ClippingBezier/UIBezierPath+Clipping_Private.h>

@interface UIBezierPath (Private)

- (DKUIBezierPathClippingResult *)clipUnclosedPathToClosedPath:(UIBezierPath *)closedPath usingIntersectionPoints:(NSArray *)intersectionPoints andBeginsInside:(BOOL)beginsInside;

@end

@interface MMClipView ()

@property(nonatomic, readwrite) IBOutlet UISegmentedControl *displayTypeControl;

@end

@implementation MMClipView {
    UIBezierPath *splitterPath;
    UIBezierPath *splittingPath;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    splitterPath = [UIBezierPath splitterPath];
    splittingPath = [UIBezierPath splittingPath];
}

- (IBAction)changedPreviewType:(id)sender
{
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if (_displayTypeControl.selectedSegmentIndex == 0) {
        [[UIColor purpleColor] setStroke];
        [splitterPath setLineWidth:3];
        [splitterPath stroke];

        [[UIColor greenColor] setStroke];
        [splittingPath setLineWidth:3];
        [splittingPath stroke];

        NSArray *intersections = [splittingPath findIntersectionsWithClosedPath:splitterPath andBeginsInside:nil];

        for (DKUIBezierPathIntersectionPoint *intersection in intersections) {
            [[UIColor redColor] setFill];
            CGPoint p = intersection.location1;

            [[UIBezierPath bezierPathWithArcCenter:p radius:7 startAngle:0 endAngle:2 * M_PI clockwise:YES] fill];
        }
    } else if (_displayTypeControl.selectedSegmentIndex == 1) {
        NSArray<DKUIBezierPathShape *> *shapes = [splittingPath uniqueShapesCreatedFromSlicingWithUnclosedPath:splitterPath];

        for (DKUIBezierPathShape *shape in shapes) {
            [[MMClipView randomColor] setFill];

            [[shape fullPath] fill];
        }
    } else if (_displayTypeControl.selectedSegmentIndex == 2) {
        [[UIColor purpleColor] setStroke];
        [splitterPath setLineWidth:3];
        [splitterPath stroke];

        [[UIColor greenColor] setStroke];
        [splittingPath setLineWidth:3];
        [splittingPath stroke];

        NSArray<UIBezierPath *> *intersection = [splittingPath intersectionWithPath:splitterPath];

        for (UIBezierPath *path in intersection) {
            [[MMClipView randomColor] setFill];
            [path fill];
        }
    } else if (_displayTypeControl.selectedSegmentIndex == 3) {
        [[UIColor purpleColor] setStroke];
        [splitterPath setLineWidth:3];
        [splitterPath stroke];

        [[UIColor greenColor] setStroke];
        [splittingPath setLineWidth:3];
        [splittingPath stroke];

        NSArray<UIBezierPath *> *difference = [splittingPath differenceWithPath:splitterPath];

        for (UIBezierPath *path in difference) {
            [[MMClipView randomColor] setFill];
            [path fill];
        }
    } else if (_displayTypeControl.selectedSegmentIndex == 4) {
        [[UIColor purpleColor] setStroke];
        [splitterPath setLineWidth:3];
        [splitterPath stroke];
    } else if (_displayTypeControl.selectedSegmentIndex == 5) {
        [[UIColor greenColor] setStroke];
        [splittingPath setLineWidth:3];
        [splittingPath stroke];
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

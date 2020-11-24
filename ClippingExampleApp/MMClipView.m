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
    UIBezierPath *path1;
    UIBezierPath *path2;
    CGPoint tapPoint;
    NSArray<UIColor *> *randomColors;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    tapPoint = CGPointNotFound;
    path1 = [UIBezierPath complexShape1];
    path2 = [UIBezierPath debug2];

    [self refreshColors];
}

- (void)refreshColors
{
    randomColors = @[];

    for (int i = 0; i < 100; i++) {
        randomColors = [randomColors arrayByAddingObject:[MMClipView randomColor]];
    }
}

- (IBAction)changedPreviewType:(id)sender
{
    [self refreshColors];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGFloat radius = 3;
    CGFloat margin = 100;
    CGRect fittingBounds = CGRectInset(self.bounds, margin, margin);
    CGRect entireBounds = CGRectUnion([path1 bounds], [path2 bounds]);
    CGPoint targetPoint = entireBounds.origin;
    CGFloat scale = MIN(fittingBounds.size.width / entireBounds.size.width, fittingBounds.size.height / entireBounds.size.height);
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, -targetPoint.x * scale, -targetPoint.y * scale);
    transform = CGAffineTransformTranslate(transform, margin, margin);
    transform = CGAffineTransformScale(transform, scale, scale);
    if (!CGPointEqualToPoint(tapPoint, CGPointNotFound)) {
        CGAffineTransform tapTransform = CGAffineTransformIdentity;
        CGFloat zoom = 5.0;
        scale *= zoom;
        tapTransform = CGAffineTransformTranslate(tapTransform, self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
        tapTransform = CGAffineTransformTranslate(tapTransform, -tapPoint.x * zoom, -tapPoint.y * zoom);
        tapTransform = CGAffineTransformScale(tapTransform, zoom, zoom);

        transform = CGAffineTransformConcat(transform, tapTransform);
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextConcatCTM(context, transform);

    if (_displayTypeControl.selectedSegmentIndex == 0) {
        [[UIColor purpleColor] setStroke];
        [path2 setLineWidth:3 / scale];
        [path2 stroke];

        [[UIColor greenColor] setStroke];
        [path1 setLineWidth:3 / scale];
        [path1 stroke];

        NSArray *intersections = [path1 findIntersectionsWithClosedPath:path2 andBeginsInside:nil];

        for (DKUIBezierPathIntersectionPoint *intersection in intersections) {
            if ([intersection mayCrossBoundary]) {
                [[UIColor redColor] setFill];
            } else {
                [[UIColor blueColor] setFill];
            }
            CGPoint p = intersection.location1;

            [[UIBezierPath bezierPathWithArcCenter:p radius:radius / scale startAngle:0 endAngle:2 * M_PI clockwise:YES] fill];
        }
    } else if (_displayTypeControl.selectedSegmentIndex == 1) {
        NSArray<DKUIBezierPathShape *> *shapes = [path1 uniqueShapesCreatedFromSlicingWithUnclosedPath:path2];

        for (DKUIBezierPathShape *shape in shapes) {
            [[randomColors objectAtIndex:[shapes indexOfObject:shape] % [randomColors count]] setFill];

            [[shape fullPath] fill];
        }
    } else if (_displayTypeControl.selectedSegmentIndex == 2) {
        [[UIColor purpleColor] setStroke];
        [path2 setLineWidth:3 / scale];
        [path2 stroke];

        [[UIColor greenColor] setStroke];
        [path1 setLineWidth:3 / scale];
        [path1 stroke];

        NSArray<UIBezierPath *> *intersection = [path1 intersectionWithPath:path2];

        for (UIBezierPath *path in intersection) {
            [[randomColors objectAtIndex:[intersection indexOfObject:path] % [randomColors count]] setFill];
            [path fill];
        }
    } else if (_displayTypeControl.selectedSegmentIndex == 3) {
        [[UIColor purpleColor] setStroke];
        [path2 setLineWidth:3 / scale];
        [path2 stroke];

        [[UIColor greenColor] setStroke];
        [path1 setLineWidth:3 / scale];
        [path1 stroke];

        NSArray<UIBezierPath *> *difference = [path1 differenceWithPath:path2];

        for (UIBezierPath *path in difference) {
            [[randomColors objectAtIndex:[difference indexOfObject:path] % [randomColors count]] setFill];
            [path fill];
        }
    } else if (_displayTypeControl.selectedSegmentIndex == 4) {
        NSArray<UIBezierPath *> *paths = [path1 unionWithPath:path2];

        for (UIBezierPath *path in paths) {
            [[[randomColors objectAtIndex:[paths indexOfObject:path] % [randomColors count]] colorWithAlphaComponent:.25] setFill];

            [path fill];
        }
    } else if (_displayTypeControl.selectedSegmentIndex == 5) {
        [[UIColor purpleColor] setStroke];
        [path2 setLineWidth:3 / scale];
        [path2 stroke];
    } else if (_displayTypeControl.selectedSegmentIndex == 6) {
        [[UIColor greenColor] setStroke];
        [path1 setLineWidth:3 / scale];
        [path1 stroke];
    }
    CGContextRestoreGState(context);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];

    tapPoint = [[touches anyObject] locationInView:self];

    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];

    if (CGPointEqualToPoint(tapPoint, CGPointNotFound)) {
        tapPoint = [[touches anyObject] locationInView:self];
    } else {
        tapPoint = CGPointNotFound;
    }

    [self setNeedsDisplay];
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

ClippingBezier
===========

This library adds categories to UIBezierPath to simplify clipping a single closed UIBezierPath with another
closed or unclosed UIBezierPath.


## Building the framework

This library will generate a proper static framework bundle that can be used in any iOS7+ project.

## Including in your project

1. Link against the built framework and the included PerformanceBezier framework
2. Add "-ObjC++ -lstdc++" to the Other Linker Flags in the project's Settings
3. #import <PerformanceBezier/PerformanceBezier.h>
4. #import <ClippingBezier/ClippingBezier.h>

## Dependencies

This library depends on the UIBezierPath performance improvements in the [PerformanceBezier](https://github.com/adamwulf/PerformanceBezier) library.

## Example

```
UIBezierPath* aClosedPath = /* some path */;
UIBezierPath* scissorPath = /* some other path */;

NSArray* subshapes = [aClosedPath uniqueShapesCreatedFromSlicingWithUnclosedPath:scissorPath];
for(DKUIBezierPathShape* shape in subshapes){
    UIBezierPath* aClosedPathSlice = shape.fullPath;
}
```

## Screenshots

Find intersections between two UIBezierPaths:

![intersection-example.png](intersection-example.png)

Or find the component shapes generated from two path's intersections

![scissor-example.png](scissor-example.png)


## Sample Application
The Xcode workspace includes a ClippingExampleApp project that shows a fully functional integration of the ClippingBezier framework. You can refer to this example for any questions about how to integrate into your app.


## License
The ClippingBezier framework and sample code are provided under the MIT License.


## Support This Project
- Download [Loose Leaf](https://itunes.apple.com/us/app/loose-leaf/id625659452?mt=8&uo=4&at=10lNUI)
- Follow [@adamwulf](http://twitter.com/adamwulf) on twitter.

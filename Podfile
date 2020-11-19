# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'ClippingBezier' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for ClippingBezier
  pod 'PerformanceBezier', '~> 1.0'

  target 'ClippingBezierTests' do
      
    #if the test project not build successfully, solution is add inherit! search_paths, pod install, then remove it, and pod install again, from the test target, like this:
    #reference:- https://stackoverflow.com/questions/37400929/cocoapods-testing-linker-error
      
    # inherit! :search_paths
    # Pods for testing
    
  end

end

target 'ClippingExampleApp' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for ClippingExampleApp
  pod 'ClippingBezier', :path => '.'

end

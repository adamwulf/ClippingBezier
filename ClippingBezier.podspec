Pod::Spec.new do |s|
  s.name            = "ClippingBezier"
  s.version         = "1.0.1"
  s.summary         = "This library adds categories to UIBezierPath to simplify clipping a single closed UIBezierPath with another closed or unclosed UIBezierPath."
  s.author          = {
      'Adam Wulf' => 'adam.wulf@gmail.com',
  }
  s.homepage        = "https://github.com/adamwulf/ClippingBezier"
  s.license         = {:type => 'CC BY', :file => 'LICENSE' }

  s.source          = { :git => "https://github.com/adamwulf/ClippingBezier.git", :tag => s.version}
  s.source_files    = ['ClippingBezier/*.{h,m,mm,cpp,cxx,hxx,c}']
  s.public_header_files = ['ClippingBezier/UIBezierPath+*.h','ClippingBezier/DK*.h','ClippingBezier/ClippingBezier.h','ClippingBezier/MMBackwardCompatible.h']


  s.platform = :ios
  s.ios.deployment_target   = "8.0"

  s.framework = 'Foundation'
  s.dependency 'PerformanceBezier'

end

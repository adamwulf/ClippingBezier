Pod::Spec.new do |s|
  s.name            = "ClippingBezier"
  s.version         = "1.2.5"
  s.summary         = "This library adds categories to UIBezierPath to simplify clipping a single closed UIBezierPath with another closed or unclosed UIBezierPath."
  s.author          = {
      'Adam Wulf' => 'adam.wulf@gmail.com',
  }
  s.homepage        = "https://github.com/adamwulf/ClippingBezier"
  s.license         = {:type => 'CC BY', :file => 'LICENSE' }

  s.source          = { :git => "https://github.com/adamwulf/ClippingBezier.git", :tag => s.version}
  s.source_files    = ['ClippingBezier/*.{h,m,mm,cpp,cxx,hxx,c}','ClippingBezier/PublicHeaders/*.{h,m,mm,cpp,cxx,hxx,c}']
  s.public_header_files = ['ClippingBezier/PublicHeaders/*.h']

  s.platform = :ios
  s.ios.deployment_target   = "12.0"

  s.framework = 'Foundation'
  s.dependency 'PerformanceBezier', '~> 1.3'
  s.xcconfig = { "DEFINES_MODULE" => "YES", "OTHER_CPLUSPLUSFLAGS" => "$(OTHER_CFLAGS) -fmodules -fcxx-modules" }

end

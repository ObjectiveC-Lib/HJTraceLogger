Pod::Spec.new do |s|
  s.name         = 'HJTraceLogger'
  s.version      = '1.0.0'
  
  s.platform     = :ios, '8.0'
  
  s.summary      = 'A real time iOS log trace tool, view iOS log with pc web browser under local area network, which will automatically scroll like xcode.'
  s.homepage     = 'https://github.com/ObjectiveC-Lib/HJTraceLogger'
  s.source       = { :git => 'https://github.com/ObjectiveC-Lib/HJTraceLogger.git', :tag => s.version }
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'navy' => 'lzxy169@gmail.com' }
  
  s.requires_arc = true
#  s.libraries    = 'sqlite3'
  s.frameworks   = 'UIKit', 'Foundation', 'CoreFoundation', 'CoreGraphics'
  
  s.source_files = 'HJTraceLogger/HJTraceLogger.h'
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |core|
    core.source_files = 'HJTraceLogger/**/*.{h,m}'
  end
  
  s.dependency 'XLFacility'
  
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
end

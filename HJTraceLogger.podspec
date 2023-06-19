Pod::Spec.new do |s|
  s.name         = 'HJTraceLogger'
  s.version      = '2.0.1'
  
  s.ios.deployment_target = '10.0'
  
  s.summary      = 'A real time iOS log trace tool, view iOS log with pc web browser under local area network, which will automatically scroll like xcode.'
  s.homepage     = 'https://github.com/ObjectiveC-Lib/HJTraceLogger'
  s.source       = { :git => 'https://github.com/ObjectiveC-Lib/HJTraceLogger.git', :tag => s.version }
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'navy' => 'lzxy169@gmail.com' }
  
  s.requires_arc = true
  s.libraries    = 'sqlite3'
  
  s.source_files = 'HJTraceLogger/Core/HJTraceLogger.h'
  s.default_subspec = 'Core'
  
  s.subspec 'Public' do |ss|
    ss.source_files = 'HJTraceLogger/Public/**/*.{h,m,mm,cc}'
  end
  
  s.subspec 'Mars' do |ss|
    ss.source_files = 'HJTraceLogger/Mars/**/*.{h,m,mm,cc}'
    ss.vendored_frameworks = 'HJTraceLogger/Mars/**/*.{framework}'
    ss.frameworks   = 'CoreTelephony', 'SystemConfiguration'
    ss.dependency 'HJTraceLogger/Public'
    ss.dependency 'SSZipArchive'
  end
  
  s.subspec 'Core' do |ss|
    ss.source_files = 'HJTraceLogger/Core/**/*.{h,m,mm,cc}'
    ss.frameworks   = 'UIKit', 'Foundation', 'CoreFoundation', 'CoreGraphics'
    ss.dependency 'HJTraceLogger/Public'
    ss.dependency 'HJTraceLogger/Mars'
  end
  
  s.dependency 'XLFacility'
  
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
end

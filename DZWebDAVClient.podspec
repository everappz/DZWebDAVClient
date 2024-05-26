Pod::Spec.new do |s|
  s.name         = 'DZWebDAVClient'
  s.license      = 'MIT'
  s.version      = '1.0.6'
  s.summary      = 'An Objective-C WebDAV client based on AFNetworking.'
  s.homepage     = 'https://github.com/zwaldowski/DZWebDAVClient'
  s.author       = { 'Zachary Waldowski' => 'zwaldowski@gmail.com' }
  s.source       = { :git => 'https://github.com/zwaldowski/DZWebDAVClient.git', :tag => '1.0.1' }
  s.source_files = 'DZWebDAVClient/*.{h,m}'
  s.requires_arc = true
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.7'
  s.dependency 'Ono'
  s.dependency 'AFNetworking/NSURLSession', '~> 4'
  s.dependency 'AFNetworking/Reachability', '~> 4'
  s.dependency 'AFNetworking/Security', '~> 4'
  s.dependency 'AFNetworking/Serialization', '~> 4'
  s.frameworks = 'SystemConfiguration', 'MobileCoreServices', 'Security'
  s.prefix_header_contents = <<-EOS
  #import <Availability.h>

  #if __IPHONE_OS_VERSION_MIN_REQUIRED
    #import <SystemConfiguration/SystemConfiguration.h>
    #import <MobileCoreServices/MobileCoreServices.h>
    #import <Security/Security.h>
  #else
    #import <SystemConfiguration/SystemConfiguration.h>
    #import <CoreServices/CoreServices.h>
    #import <Security/Security.h>
  #endif
EOS
end

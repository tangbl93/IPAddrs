Pod::Spec.new do |s|
  s.name             = 'IPAddrs'
  s.version          = '1.0.0'
  s.summary          = 'IPAddrs Parser'
  s.description      = 'IPAddrs Parser for IPv4'
  s.homepage         = 'https://github.com/tangbl93/IPAddrs'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tangbl93' => 'tangbl93@gmail.com' }
  s.source           = { :git => 'https://github.com/tangbl93/IPAddrs.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = 'IPAddrs/**/*'
  s.public_header_files = 'IPAddrs/include/**/IPAddrs.h'
  
end

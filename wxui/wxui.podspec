
Pod::Spec.new do |s|
  s.name             = 'wxui'
  s.version          = '5.0.0'
  s.summary          = 'wuxieyun ui lib.'

  s.description      = <<-DESC
                      Online chat Lib for ios, Helpdesk system
                       DESC

  s.homepage         = 'http://wuxieyun.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'pengjinning' => '270580156@qq.com' }
  s.source           = { :git => 'https://github.com/pengjinning/wxui-ios.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'

  s.source_files = 'wxui/Classes/**/*'
  
  s.resource_bundles = {
     'wxui' => ['wxui/Assets/**/*.*']
  }  

  s.dependency "FMDB"
  s.dependency "Socket.IO-Client-Swift", "~> 13.1.0"
  s.dependency "AFNetworking"
  s.dependency 'QMUIKit'
  s.dependency 'M80AttributedLabel'
  s.dependency 'wxcore'
  
  s.swift_version = "4.0"

end

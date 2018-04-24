
Pod::Spec.new do |s|
  s.name             = 'wxui'
  s.version          = '5.0.3'
  s.summary          = 'wuxieyun ui lib.'

  s.description      = <<-DESC
                      Online chat Lib for ios, Helpdesk system
                       DESC

  s.homepage     = "http://wuxieyun.com"
  s.license      = "MIT"
  s.author       = { "jackning" => "270580156@qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/pengjinning/wxui-ios.git", :tag => "#{s.version}" }
  s.vendored_frameworks = "frameworks/cocoapods/wxui.framework"
  s.requires_arc = true

  s.dependency "FMDB"
  s.dependency "Socket.IO-Client-Swift", "~> 13.1.0"
  s.dependency "AFNetworking"
  s.dependency 'QMUIKit'
  s.dependency 'M80AttributedLabel'
  s.dependency 'wxcore'
  
  s.swift_version = "4.0"

end

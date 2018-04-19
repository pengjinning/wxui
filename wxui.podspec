
Pod::Spec.new do |s|

  s.name         = "wxui"
  s.version      = "5.0.0"
  s.summary      = "WuXieYun ui lib."

  s.description  = <<-DESC
                    Online chat Lib for ios, Helpdesk system
                   DESC

  s.homepage     = "http://wuxieyun.com"
  s.license      = "MIT"
  s.author       = { "jackning" => "270580156@qq.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/pengjinning/wxui-ios.git", :tag => "#{s.version}" }

  s.source_files  = "wxui", "wxui/Sources/**/*.{h,m}"
  s.public_header_files = "wxui/Sources/apis/*.h"

  s.resources = "wxui/Resources/**/*.*"
  s.requires_arc = true

  s.dependency "FMDB"
  s.dependency "Socket.IO-Client-Swift", "~> 13.1.0"
  s.dependency "AFNetworking"
  s.dependency "QMUIKit"
  s.dependency "M80AttributedLabel"
  s.dependency "wxcore"

  s.swift_version = "4.0"

end

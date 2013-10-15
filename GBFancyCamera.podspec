Pod::Spec.new do |s|
  s.name         = "GBFancyCamera"
  s.version      = "1.0.2"
  s.summary      = "A blocks based class for getting images from the camera and camera roll, with preview customisable UI and pluggable filters."
  s.homepage     = "https://github.com/lmirosevic/GBFancyCamera"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { "Luka Mirosevic" => "luka@goonbee.com" }
  s.platform     = :ios, '5.0'
  s.source       = { :git => "https://github.com/lmirosevic/GBFancyCamera.git", :tag => "1.0.2" }
  s.source_files  = 'GBFancyCamera'
  s.public_header_files = 'GBFancyCamera/GBFancyCamera.h'
  s.requires_arc = true

  s.dependency 'GBMotion'
  s.dependency 'GPUImage-Goonbee'
end

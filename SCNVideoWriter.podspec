Pod::Spec.new do |s|
  s.name             = 'SCNVideoWriter'
  s.version          = '0.5.0'
  s.summary          = 'A simple recorder for SceneKit.'

  s.description      = <<-DESC
SCNVideoWriter is a simple video writer for SCNScene.
It's support iOS10 or later on Metal supported device.
And support video and overlay of ARKit.
                       DESC

  s.homepage         = 'https://github.com/noppefoxwolf/SCNVideoWriter'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'noppefoxwolf' => 'noppelabs@gmail.com' }
  s.source           = { :git => 'https://github.com/noppefoxwolf/SCNVideoWriter.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'SCNVideoWriter/Classes/**/*'
end

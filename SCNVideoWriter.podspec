Pod::Spec.new do |s|
  s.name             = 'SCNVideoWriter'
  s.version          = '0.1.0'
  s.summary          = 'A short description of SCNVideoWriter.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/noppefoxwolf/SCNVideoWriter'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'noppefoxwolf' => 'noppelabs@gmail.com' }
  s.source           = { :git => 'https://github.com/noppefoxwolf/SCNVideoWriter.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'SCNVideoWriter/Classes/**/*'
end

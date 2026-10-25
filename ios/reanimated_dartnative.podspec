Pod::Spec.new do |s|
  s.name             = 'reanimated_dartnative'
  s.version          = '0.1.0'
  s.summary          = 'React Native Reanimated for DartNative: CoreMotion sensors and animation engine over FFI.'
  s.description      = <<-DESC
Native side of reanimated_dartnative for iOS: hardware sensor streams (accelerometer,
gyroscope, gravity, device rotation attitude, and magnetic field) on CoreMotion,
exposed to Dart as C entry points over FFI with zero platform channels.
                       DESC
  s.homepage         = 'https://github.com/edkluivert/reanimated_dartnative'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Kluivert' => 'team@funkash.com' }
  s.source           = { :path => '.' }

  s.source_files     = 'Classes/**/*.swift'
  s.swift_version    = '5.9'
  s.platform         = :ios, '14.0'
  s.frameworks       = 'CoreMotion', 'Foundation', 'UIKit'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end

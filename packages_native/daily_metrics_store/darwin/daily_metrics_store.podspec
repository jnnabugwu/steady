#
# CocoaPods fallback. The app integrates plugins through Swift Package
# Manager (darwin/daily_metrics_store/Package.swift); this only matters if
# SPM is ever turned off.
#
Pod::Spec.new do |s|
  s.name             = 'daily_metrics_store'
  s.version          = '0.0.1'
  s.summary          = 'SwiftData-backed DailyMetric store for Steady.'
  s.description      = 'Native side of the steady/daily_metrics MethodChannel.'
  s.homepage         = 'https://github.com/jnnabugwu/steady'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'Steady' => 'noreply@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'daily_metrics_store/Sources/daily_metrics_store/**/*.swift'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '17.0'
  s.osx.deployment_target = '14.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.9'
end

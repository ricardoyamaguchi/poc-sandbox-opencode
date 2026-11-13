platform :ios, '17.0'
use_frameworks!

project 'PocSandbox'

target 'PocSandbox' do
  # Pods for PocSandbox
  pod 'Alamofire', '~> 5.10'
  pod 'GoogleSignIn', '~> 10.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end
end

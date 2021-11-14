target 'Music Transfer (iOS)' do
  platform :ios, '14.0'

  pod 'RealmSwift', '~> 10.8.0', :modular_headers => true
  pod 'Realm', '~> 10.8.0', :modular_headers => true
  pod 'SwiftLint'
  pod 'URLImage', '~> 2.2.5'

end

target 'Music Transfer (macOS)' do
  platform :macos, '11.0'

  pod 'RealmSwift', '~> 10.8.0', :modular_headers => true
  pod 'Realm', '~> 10.8.0', :modular_headers => true
  pod 'SwiftLint'
  pod 'URLImage', '~> 2.2.5'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      config.build_settings.delete 'MACOSX_DEPLOYMENT_TARGET'
    end
  end
end

platform:ios, '13.0'

source 'https://github.com/CocoaPods/Specs.git'

target 'NotificareDemo' do
    use_frameworks!
    inhibit_all_warnings!

    # Helper Frameworks
    pod 'OneSignalXCFramework', '>= 3.0.0', '< 4.0'
    pod 'Notificare/NotificareKit'
    pod 'Notificare/NotificareGeoKit'
    pod 'Notificare/NotificarePushKit'
    pod 'Notificare/NotificarePushUIKit'

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        xcconfig_path = config.base_configuration_reference.real_path
        xcconfig = File.read(xcconfig_path)
        xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
        File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
      end
    end
  end
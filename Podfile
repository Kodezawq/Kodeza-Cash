# Uncomment the next line to define a global platform for your project
 platform :ios, '15.0'

target 'Loan_Zen' do

  use_frameworks!
  pod 'Masonry'
  pod 'SDWebImage'
  pod 'YYStarView'
  pod 'IQKeyboardManager',             '~> 6.5.1'
  pod 'Adjust',                        '~> 5.4.5'
  pod 'GoogleAdsOnDeviceConversion',   '3.0.0'
  pod 'LEEAlert'
  pod 'FWPopupViewOC'
  pod 'SVProgressHUD'
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['EXPAND_BUILD_SETTINGS'] = 'YES'
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      end
    end
  end
end

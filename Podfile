# Uncomment the next line to define a global platform for your project
platform :ios, '17.2'

target 'body_gym' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for body_gym
pod 'FirebaseAuth'
pod 'FirebaseFirestore'
pod 'FirebaseDatabase'
pod 'FirebaseStorage'
pod 'FSCalendar'
pod 'SDWebImage'
pod 'Kingfisher'

  target 'body_gymTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'body_gymUITests' do
    # Pods for testing
  end
end


post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.2'
         end
    end
  end
end
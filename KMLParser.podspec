#
# Be sure to run `pod lib lint KMLParser.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KMLParser'
  s.version          = '0.6.1'
  s.summary          = 'Swift KML parser base on the (NS)XMLParser found in Foundation'


  s.description      = <<-DESC
This lib tries to simplify parsing a KML document, currently it supports the followin KML features:
* Polygon, as well nested inner pollygons (inner boundaries of a Polygon)
* Points
                       DESC

  s.homepage         = 'https://github.com/avdwerff/KMLParser'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'avdwerff' => 'avdwerff@gmail.com' }
  s.source           = { :git => 'https://github.com/avdwerff/KMLParser.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/werffmeister'

  s.ios.deployment_target = '8.0'

  s.source_files = 'KMLParser/Classes/**/*'
  
  # s.resource_bundles = {
  #   'KMLParser' => ['KMLParser/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

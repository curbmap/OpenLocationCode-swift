#
#  Be sure to run `pod spec lint OpenLocationCode.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "OpenLocationCode"
  s.version      = "0.0.4.7"
  s.summary      = "Google's Open Location Code spec implemented in Swift 4."

  s.description  = <<-DESC
  OpenLocationCode-swift is an implementation similar to the code released by Google on their github repository for
  Open Location Codes (Plus Codes). Open Location Codes are generally 10 characters, but can be shorter (short codes,
  usually pinned to some nearby location that has a known prefix code) or longer (a full code with extra characters
  specifying grid-based reductions in the dimensions of a coded region). For more information about Google's Open
  Location Codes, see http://openlocationcode.com or https://en.wikipedia.org/wiki/Open_Location_Code
  or https://github.com/google/open-location-code
                   DESC

  s.homepage     = "https://github.com/curbmap/OpenLocationCode-swift"

  s.license      = { :type => 'Apache License, Version 2.0', :file => 'LICENSE.txt'}

  s.author             = { "Eli Selkin" => "ejselkin@cpp.edu" }
  s.source       = { :git => "https://github.com/curbmap/OpenLocationCode-swift.git", :tag => "#{s.version}" }
  s.source_files  = "OpenLocationCode", "OpenLocationCodes/**/*.{h,m,swift}"
  s.ios.framework  = 'UIKit'
  s.ios.deployment_target  = '10.0'
  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4' }
end

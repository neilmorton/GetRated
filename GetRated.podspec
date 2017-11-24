#
# Be sure to run `pod lib lint GetRated.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GetRated'
  s.version          = '1.0.2'
  s.summary          = 'Handy class to help you promote iPhone apps by using SKStoreReviewController in iOS 10.3 & later to prompt users to rate the app.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
GetRated is a handy class to help you promote your iPhone & iPad apps. GetRated uses SKStoreReviewController (available in iOS 10.3 and later) to prompt users to rate your app after using it for a few days. GetRated will then manage further attempts to get a rating by retrying periodically, in line with App Store recomendations. This approach is one of the best ways to get positive ratings by targetting only regular users (who presumably like the app or they wouldn't keep using it!).

GetRated will ensure that a number of configurable requirements are met before prompting. These include daysUntilFirstPrompt, daysUntilFuturePrompts, minimumDaysUntilPromptAfterVersionUpdate, usesUntilPrompt and eventsUntilPrompt.

By default GetRated will evenly spread 3 requests to prompt per year in order to make the best use of the maximum 3 prompts per year limit set by Apple.

GetRated was inspired by, and in parts based on [iRate](https://github.com/nicklockwood/iRate) by Nick Lockwood.
                       DESC

  s.homepage         = 'https://github.com/neilmorton/GetRated'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'Neil Morton'
  s.source           = { :git => 'https://github.com/neilmorton/GetRated.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '7.0'

  s.source_files = 'GetRated/getRated.{h,m}'
  
  s.frameworks = 'Foundation', 'SystemConfiguration', 'StoreKit'

end

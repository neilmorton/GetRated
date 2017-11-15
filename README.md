GetRated
=======

[![Version](https://img.shields.io/cocoapods/v/GetRated.svg?style=flat)](http://cocoapods.org/pods/GetRated)
[![License](https://img.shields.io/cocoapods/l/GetRated.svg?style=flat)](http://cocoapods.org/pods/GetRated)
[![Platform](https://img.shields.io/cocoapods/p/GetRated.svg?style=flat)](http://cocoapods.org/pods/GetRated)


Purpose
----------

GetRated is a handy class to help you promote your iPhone apps by using SKStoreReviewController in iOS 10.3 and later to prompt users to rate your app after using it for a few days. This approach is one of the best ways to get positive ratings by targetting only regular users (who presumably like the app or they wouldn't keep using it!).


Supported OS & SDK Versions
-----------------------------------

* Supported build target - iOS 11.1 (Xcode 9.1)
* Earliest supported deployment target - iOS 8.1
* Earliest compatible deployment target - iOS 7.0

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


Installation
------------

#### Manual

To install GetRated into your app, drag the getRated.h and .m files into your project.


#### Cocoapods

GetRated is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'GetRated'
```


### Basic Setup

GetRated typically requires no configuration and simply requires starting, the best time to do this is in your AppDelegate's `- [application:didFinishLaunchingWithOptions:]` method.

If you do wish to customise GetRated, the best time to do this is again in your AppDelegate's `-[application:didFinishLaunchingWithOptions:]` method. Any configuration should be applied _BEFORE CALLING START_, otherwise the prompt may already have been requested.

```
#import <GetRated/getRated.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //configure GetRated
    
    /* _optional_ */
    //don't prompt at launch - only set this if you intent to call GetRated to prompt manually
    [getRated sharedInstance].promptAtLaunch = NO;

    //enable preview mode - *** ONLY SET THIS FOR TESTING ONLY ***
    [getRated sharedInstance].previewMode = YES;

    /* _required_ */
    //start GetRated - should be called AFTER any optional configuration options (above)
    [[getRated sharedInstance] start];

    return YES;
}
```


Configuration
---------------

There are a number or properties of the GetRated class that can be used to alter the behaviour of GetRated. These should mostly be self-explanatory, but they are documented below:

    @property (nonatomic, assign) float daysUntilFirstPrompt;
    
This is the number of days the user must have had the app installed before they are prompted to rate it. The time is measured from the first time the app is launched. This is a floating point value, so it can be used to specify a fractional number of days (e.g. 0.5).
The default value is 10 days.

    @property (nonatomic, assign) float daysUntilFuturePrompts;

This is the number of days that must pass after a prompt was requested before the prompt will be requested again. The time is measure from the last prompt request. This is a floating point value, so it can be used to specify a fractional number of days (e.g. 0.5).
The default value is 123 days. This number is chosen as we are allowed to make a request to `SKStoreReviewController` only 3 times in a 12 month period.

    @property (nonatomic, assign) float minimumDaysUntilPromptAfterVersionUpdate;
    
This is the number of days the user must have had the latest version installed before they are prompted to rate it. The time is measured from the time the latest version of the app is first launched. This is a floating point value, so it can be used to specify a fractional number of days (e.g. 0.5).
The default value is 5 days. This avoids the scenario where a prompt is due but the user has only just updated the installed version, only to be asked for a rating straight away.
    
    @property (nonatomic, assign) NSUInteger usesUntilPrompt;
    
This is the minimum number of times the user must launch the app before they are prompted to rate it. This avoids the scenario where a user runs the app once, doesn't look at it for weeks and then launches it again, only to be immediately prompted to rate it. The minimum use count ensures that only frequent users are prompted. The prompt will appear only after the specified number of days AND uses has been reached.
The defauklt value is 10 uses.

    @property (nonatomic, assign) NSUInteger eventsUntilPrompt;

For some apps, launches are not a good metric for usage. For example the app might be a game where the user can't write an informed review until they've reached a particular level. In this case you can manually log significant events and have the prompt appear after a predetermined number of these events. Like the usesUntilPrompt setting, the prompt will appear only after the specified number of days AND events, however once the day threshold is reached, the prompt will appear if EITHER the event threshold OR uses threshold is reached.
The default value is 10 events.

    @property (nonatomic, assign) BOOL onlyPromptIfLatestVersion;
    
Set this to NO to enabled the rating prompt to be displayed even if the user is not running the latest version of the app.
The default value is YES because that way users won't leave bad reviews due to bugs that you've already fixed, etc.

    @property (nonatomic, assign) BOOL promptAtLaunch;
    
Set this to NO to disable the rating prompt appearing automatically when the application launches or returns from the background. The rating criteria will continue to be tracked, but the prompt will not be displayed automatically while this setting is in effect. You can use this option if you wish to manually control display of the rating prompt.
The default value is YES.
    
    @property (nonatomic, assign) BOOL verboseLogging;
    
This option will cause GetRated to send detailed logs to the console about the prompt decision process. If your app is not correctly prompting for a rating when you would expect it to, this will help you figure out why.
Verbose logging is enabled by default on debug builds, and disabled on release and deployment builds.

    @property (nonatomic, assign) BOOL previewMode;
    
If set to YES, GetRated will always display the rating prompt on launch, regardless of how long the app has been in use or whether it's the latest version (unless you have explicitly disabled the `promptAtLaunch` option). Use this to check your configuration is correct during testing, but disable it for the final release.
The default value is NO.

    @property (nonatomic, assign) BOOL promptEnabled;
    
This allows you to switch off the prompts. For instance you may wish to remotely manage whenther prompts are enabled or not.
The default value is YES.


Advanced properties
------------------------

If the default GetRated behaviour doesn't meet your requirements, you can implement your own by using the advanced properties and methods. The properties below let you access internal state and override it:

    @property (nonatomic, strong) NSDate *appFirstUsed;
    
The first date on which the user launched the app. This is used to calculate whether the daysUntilPrompt criterion has been met.

    @property (nonatomic, strong) NSDate *versionFirstUsed;
    
The first date on which the user launched the current version of the app. This is used to calculate whether the minimumDaysUntilPromptAfterVersionUpdate criterion has been met.
    
    @property (nonatomic, strong) NSDate *lastRequestedRating;
    
The date on which GetRated last attempted to request a rating (if any).
    
    @property (nonatomic, assign) NSUInteger usesCount;
    
The number of times the app has been used (launched).
    
    @property (nonatomic, assign) NSUInteger eventCount;
    
The number of significant application events that have been recorded since the app was installed. This is incremented by the logEvent method, but can also be manipulated directly.


Methods
----------

Besides configuration, GetRated has the following methods:

    - (BOOL)shouldPromptForRating;

Returns YES if the prompt criteria have been met, and NO if they have not. You can use this to decide when to display a rating prompt if you have disabled the automatic display at app launch.

    - (void)promptForRating;
    
This method will immediately trigger the rating prompt if a connection to the app store is available.
    
    - (void)promptIfAllCriteriaMet;
    
This method will check if all prompting criteria have been met, and if the app store is available, and if it is, it will display the rating prompt to the user.
    
    - (void)openRatingsPageOnAppStore;
    
This method skips the user alert and opens the application ratings page on the iPhone app store if a connection to the app store is available. This will also cause the `lastRequestedRating` property to  be updated. This can be used to allow the addition of a 'Please Rate on the App Store' button on an About screen or similar.
    
    - (void)logEvent:(BOOL)deferPrompt;
    
This method can be called from anywhere in your app (after GetRated has been configured) and increments the GetRated significant event count. When the predefined number of events is reached, the rating prompt will be shown. The optional deferPrompt parameter is used to determine if the prompt will be shown immediately (NO) or if the app will wait until the next launch (YES).


Example Projects
--------------------

The standard example demonstrates a basic implementation of GetRated, with a prompt appearing at launch if all crietia have been met.

The advanced example demonstrates how you might implement GetRated by performing calls to `promptIfAllCriteriaMet` from a suitable place in your app. This allows for the prompt to appear at a given point in your app if all criteria have been met.

_Note that both examples have `previewMode` enabled, therefore the `daysUntilFirstPrompt`, `daysUntilFuturePrompts`, `minimumDaysUntilPromptAfterVersionUpdate`, `usesUntilPrompt` and `eventsUntilPrompt` are ignored._

To run either example project, clone the repo, and run `pod install` from the relevant example directory first.


Author
--------

Neil Morton [GitHub](https://github.com/neilmorton) [Twitter](https://twitter.com/MrNeilM)


License
---------

GetRated is available under the MIT license. See the [LICENSE](https://github.com/neilmorton/GetRated/blob/master/LICENSE) file for more info.


Release Notes
-----------------

Version 0.1.1

- Removed commented code.
- Updated version info.

Version 0.1.0

- Inital build

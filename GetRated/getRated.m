//
//  getRated.m
//
//  Version 1.0.1
//
//  Created by Neil Morton on 29/09/2017.
//  Copyright © 2017 Neil Morton. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/neilmorton/GetRated
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//
//  Copyright © for portions of GetRated are held by Charcoal Design, 2011
//  as part of iRate.
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "getRated.h"

static NSString *const getRatedAppStoreIDKey = @"getRatedAppStoreID";
static NSString *const getRatedLatestAppStoreVersionCachedKey = @"getRatedLatestAppStoreVersionCached";
static NSString *const getRatedLastRequestedRatingKey = @"getRatedLastRequestedRating";
static NSString *const getRatedLastVersionUsedKey = @"getRatedLastVersionUsed";
static NSString *const getRatedAppFirstUsedKey = @"getRatedAppFirstUsed";
static NSString *const getRatedVersionFirstUsedKey = @"getRatedVersionFirstUsed";
static NSString *const getRatedUseCountKey = @"getRatedUseCount";
static NSString *const getRatedEventCountKey = @"getRatedEventCount";
static char *const getRatedItunesUrl = "itunes.apple.com";
static NSString *const getRatedAppLookupURLFormat = @"https://itunes.apple.com/lookup?bundleId=%@";
static NSString *const getRatedAppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%@?action=write-review";
static NSString *const getRatedDidRequestReview = @"getRatedDidRequestReview";
static NSString *const getRatedDidOpenRatingsPageOnAppSore = @"getRatedDidOpenRatingsPageOnAppSore";

#define SECONDS_IN_A_DAY 86400.0

@interface getRated()

@property (nonatomic, strong) NSString *lastVersionUsed;
@property (nonatomic, assign) NSUInteger appStoreID;

@end


@implementation getRated

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceTokenShared;
    static getRated *sharedInstance = nil;
    dispatch_once(&onceTokenShared, ^{
        sharedInstance = [(getRated *)[self alloc] init];
    });
    return sharedInstance;
}

- (getRated *)init
{
    if ((self = [super init]))
    {
        //application version
        self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        
        //default settings
        self.daysUntilFirstPrompt = 10.0;
        self.daysUntilFuturePrompts = 123.0;
        self.minimumDaysUntilPromptAfterVersionUpdate = 5.0;
        self.usesUntilPrompt = 10;
        self.eventsUntilPrompt = 10;
        
        self.onlyPromptIfLatestVersion = YES;
        self.promptAtLaunch = YES;
        self.verboseLogging = NO;
        self.previewMode = NO;
        self.promptEnabled = YES;
        
#if DEBUG
        
        //enable verbose logging in debug mode
        self.verboseLogging = YES;
        NSLog(@"getRated verbose logging enabled.");
        
#endif
        
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)start
{
    if (self.verboseLogging)
    {
        NSLog(@"getRated Start Called");
    }
    static dispatch_once_t onceTokenStart;
    dispatch_once(&onceTokenStart, ^{
        [self startGetRated];
    });
}

- (void)startGetRated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self applicationStarted];
    });
}

- (void)applicationStarted
{
    //register for iphone application events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    bool getLatestAppData = NO;
    //check if this is first install or new version
    if (!self.appFirstUsed)
    {
        //first install
        [self setAppFirstUsed:[NSDate date]];
        [self setLastVersionUsed:self.applicationVersion];
        [self setVersionFirstUsed:[NSDate date]];
        [self setUsesCount:0];
        [self setEventCount:0];
        getLatestAppData = true;
    }
    else if (![self.lastVersionUsed isEqualToString:self.applicationVersion])
    {
        //version updated
        [self setLastVersionUsed:self.applicationVersion];
        [self setVersionFirstUsed:[NSDate date]];
        getLatestAppData = true;
    }
    
    if (getLatestAppData)
    {
        //get latest data from app store
        if ([self hasConnection])
        {
            [self getLatestAppData:nil];
        }
    }
    
    [self incrementUseCount];
    
    if (self.verboseLogging)
    {
        NSString *onlyPromptIfLatestVersionText = self.onlyPromptIfLatestVersion ? @"YES" : @"NO";
        NSString *promptAtLaunchText = self.promptAtLaunch ? @"YES" : @"NO";
        NSString *verboseLoggingText = self.verboseLogging ? @"YES" : @"NO";
        NSString *previewModeText = self.previewMode ? @"YES" : @"NO";
        NSString *promptEnabledText = self.promptEnabled ? @"YES" : @"NO";
        NSLog(@"getRated running with configuration: daysUntilFirstPrompt=%f; daysUntilFuturePrompts=%f; minimumDaysUntilPromptAfterVersionUpdate=%f; usesUntilPrompt=%lu; eventsUntilPrompt=%lu; onlyPromptIfLatestVersion=%@; promptAtLaunch=%@; verboseLogging=%@; previewMode=%@; promptEnabled=%@.", self.daysUntilFirstPrompt, self.daysUntilFuturePrompts, self.minimumDaysUntilPromptAfterVersionUpdate, (unsigned long)self.usesUntilPrompt, (unsigned long)self.eventsUntilPrompt, onlyPromptIfLatestVersionText, promptAtLaunchText, verboseLoggingText, previewModeText, promptEnabledText);
    }
    
    if (self.promptAtLaunch)
    {
        [self promptIfAllCriteriaMet];
    }
}

- (void)applicationWillEnterForeground
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        [self incrementUseCount];
        
        if (self.promptAtLaunch)
        {
            [self promptIfAllCriteriaMet];
        }
    }
}


#pragma mark override getters & setters
- (NSString *)lastVersionUsed
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:getRatedLastVersionUsedKey];
}

- (void)setLastVersionUsed:(NSString *)currentVersion
{
    [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:getRatedLastVersionUsedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)appFirstUsed
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:getRatedAppFirstUsedKey];
}

- (void)setAppFirstUsed:(NSDate *)date
{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:getRatedAppFirstUsedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)versionFirstUsed
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:getRatedVersionFirstUsedKey];
}

- (void)setVersionFirstUsed:(NSDate *)date
{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:getRatedVersionFirstUsedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)lastRequestedRating
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:getRatedLastRequestedRatingKey];
}

- (void)setLastRequestedRating:(NSDate *)date
{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:getRatedLastRequestedRatingKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)usesCount
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:getRatedUseCountKey];
}

- (void)setUsesCount:(NSUInteger)count
{
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)count forKey:getRatedUseCountKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)eventCount
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:getRatedEventCountKey];
}

- (void)setEventCount:(NSUInteger)count
{
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)count forKey:getRatedEventCountKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)appStoreID
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:getRatedAppStoreIDKey] unsignedIntegerValue];
}

- (void)setAppStoreIDString:(NSString *)appStoreIDString
{
    [[NSUserDefaults standardUserDefaults] setInteger:[appStoreIDString integerValue] forKey:getRatedAppStoreIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)currentVersion{
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *currentVersion = bundleInfo[@"CFBundleShortVersionString"];
    return currentVersion;
}

- (NSString *)bundleIdentifier{
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleIdentifier = bundleInfo[@"CFBundleIdentifier"];
    return bundleIdentifier;
}

- (NSString *)latestAppStoreVersionCached
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:getRatedLatestAppStoreVersionCachedKey];
}

- (bool)setLatestAppStoreVersionCached:(NSString *)latestVersion
{
    [[NSUserDefaults standardUserDefaults] setObject:latestVersion forKey:getRatedLatestAppStoreVersionCachedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return true;
}

- (void)incrementUseCount
{
    self.usesCount ++;
}

- (void)incrementEventCount
{
    self.eventCount ++;
}

- (void)logEvent:(BOOL)deferPrompt
{
    [self incrementEventCount];
    if (!deferPrompt)
    {
        [self promptIfAllCriteriaMet];
    }
}

- (BOOL)shouldPromptForRating
{
    //check if preview mode
    if (self.previewMode)
    {
        NSLog(@"getRated preview mode is enabled - make sure you disable this for release");
        return YES;
    }
    
    //check if prompt is enabled
    if (!self.promptEnabled)
    {
        if (self.verboseLogging)
        {
            NSLog(@"getRated did not prompt for rating because promptEnabled has been set to NO");
        }
        return NO;
    }
    
    //check how long we've been using the app
    else if ([[NSDate date] timeIntervalSinceDate:self.appFirstUsed] < self.daysUntilFirstPrompt * SECONDS_IN_A_DAY)
    {
        if (self.verboseLogging)
        {
            NSLog(@"getRated did not prompt for rating because the app was first used less than %g days ago", self.daysUntilFirstPrompt);
        }
        return NO;
    }
    
    //check how many times we've used it and the number of significant events
    else if (self.usesCount < self.usesUntilPrompt && self.eventCount < self.eventsUntilPrompt)
    {
        if (self.verboseLogging)
        {
            NSLog(@"getRated did not prompt for rating because the app has only been used %@ times and only %@ events have been logged", @(self.usesCount), @(self.eventCount));
        }
        return NO;
    }
    
    //check how long we've been using this version
    else if ([[NSDate date] timeIntervalSinceDate:self.versionFirstUsed] < self.minimumDaysUntilPromptAfterVersionUpdate * SECONDS_IN_A_DAY)
    {
        if (self.verboseLogging)
        {
            NSLog(@"getRated did not prompt for rating because this version was first used less than %g days ago", self.minimumDaysUntilPromptAfterVersionUpdate);
        }
        return NO;
    }
    
    //check if within future prompt period
    else if (self.lastRequestedRating != nil && [[NSDate date] timeIntervalSinceDate:self.lastRequestedRating] < self.daysUntilFuturePrompts * SECONDS_IN_A_DAY)
    {
        if (self.verboseLogging)
        {
            NSLog(@"getRated did not prompt for rating because we attempted to prompt less than %g days ago", self.daysUntilFuturePrompts);
        }
        return NO;
    }
    
    //check if installed version is outdated from local cache data
    else if ([self isAppVersionOutdatedFromCache])
    {
        NSString *currentVersion = [self currentVersion];
        NSString *latestAppStoreVersionCached = [self latestAppStoreVersionCached];
        if (self.verboseLogging)
        {
            NSLog(@"getRated did not prompt for rating because the installed version (%@) is older than the App Store version (%@).", currentVersion, latestAppStoreVersionCached);
        }
        return NO;
    }
    
    //check if we have network connectivity
    else if (![self hasConnection])
    {
        if (self.verboseLogging)
        {
            NSLog(@"getRated did not prompt for rating because there is no connection to the app store.");
        }
        return NO;
    }
    
    //OK prompt! (Final check for app version (against latest App Store Data) will be done at prompt stage as requires network hit.)
    return YES;
}

- (void)setRequestedRating
{
    //set requested rating
    self.lastRequestedRating = [NSDate date];
}

- (void)promptForRating
{
    [self promptForRating: YES];
}

- (void)promptForRating:(BOOL)manual
{
    if (@available(iOS 10.3, *)) {
        if ([SKStoreReviewController class])
        {
            if ([self hasConnection])
            {
                if (manual)
                {
                    [self setRequestedRating];
                    [SKStoreReviewController requestReview];
                    [[NSNotificationCenter defaultCenter] postNotificationName:getRatedDidRequestReview
                                                                        object:nil];
                    if (self.verboseLogging)
                    {
                        NSLog(@"getRated called SKStoreReviewController requestReview.");
                    }
                }
                else
                {
                    [self getLatestAppData:^(BOOL isLatestVersion, NSString *appStoreVersion, NSString *currentVersion, NSString *appStoreID) {
                        if (isLatestVersion || self.previewMode)
                        {
                            [self setRequestedRating];
                            [SKStoreReviewController requestReview];
                            [[NSNotificationCenter defaultCenter] postNotificationName:getRatedDidRequestReview
                                                                                object:nil];
                            if (self.verboseLogging)
                            {
                                NSLog(@"getRated called SKStoreReviewController requestReview.");
                            }
                        }
                        else
                        {
                            if (self.verboseLogging)
                            {
                                if (appStoreVersion)
                                {
                                    NSLog(@"getRated did not prompt for rating because the installed version (%@) is older than the App Store version (%@).", currentVersion, appStoreVersion);
                                }
                                else
                                {
                                    NSLog(@"getRated did not prompt for rating because your app could not be found on iTunes.");
                                }
                            }
                        }
                    }];
                }
            }
        }
        else
        {
            if (self.verboseLogging)
            {
                NSLog(@"getRated did not prompt for rating because SKStoreReviewController class not found.");
            }
        }
    } else {
        if (self.verboseLogging)
        {
            NSLog(@"getRated did not prompt for rating because SKStoreReviewController class not found.");
        }
    }
}

- (void)promptIfAllCriteriaMet
{
    if ([self shouldPromptForRating]) {
        [self promptForRating: NO];
    }
}

#pragma mark - Private Methods
- (bool)isAppVersionOutdatedFromCache
{
    NSString *currentVersion = [self currentVersion];
    NSString *latestAppStoreVersionCached = [self latestAppStoreVersionCached];
    
    //compare any local stored latest version. If this is already later then no need to hit the network.
    if (latestAppStoreVersionCached && latestAppStoreVersionCached.length && [latestAppStoreVersionCached compare:currentVersion options:NSNumericSearch] == NSOrderedDescending) {
        return YES;
    }
    return NO;
}

- (void)isAppLatestVersion:(void(^)(BOOL isLatestVersion, NSString *appStoreVersion, NSString *currentVersion))completion
{
    [self getLatestAppData:^(BOOL isLatestVersion, NSString *appStoreVersion, NSString *currentVersion, NSString *appStoreID) {
        completion(isLatestVersion, appStoreVersion, currentVersion);
    }];
}

- (void)getLatestAppData:(void(^)(BOOL isLatestVersion, NSString *appStoreVersion, NSString *currentVersion, NSString *appStoreID))completion
{
    NSString *currentVersion = [self currentVersion];
    
    //go to network to check
    NSString *bundleIdentifier = [self bundleIdentifier];
    NSURL *lookupURL = [NSURL URLWithString:[NSString stringWithFormat:getRatedAppLookupURLFormat, bundleIdentifier]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        NSData *lookupResults = [NSData dataWithContentsOfURL:lookupURL];
        if (!lookupResults) {
            if (self.verboseLogging)
            {
                NSLog(@"getRated was unable to connect to iTunes");
            }
            if (completion) completion(NO, nil, currentVersion, nil);
            return;
        }
        
        NSDictionary *jsonResults = [NSJSONSerialization JSONObjectWithData:lookupResults options:0 error:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSUInteger resultCount = [jsonResults[@"resultCount"] integerValue];
            if (resultCount){
                
                //get all app details
                NSDictionary *appDetails = [jsonResults[@"results"] firstObject];
                
                //get and store app id
                NSString *appStoreIDString = appDetails[@"trackId"];
                if ((![self appStoreID]) || ([self appStoreID] != [appStoreIDString integerValue])) {
                    if (self.verboseLogging)
                    {
                        NSLog(@"getRated setting AppStoreIDString %@", appStoreIDString);
                    }
                    [self setAppStoreIDString:appStoreIDString];
                }
                
                //get app version
                NSString *latestVersion = appDetails[@"version"];
                if ([latestVersion compare:currentVersion options:NSNumericSearch] == NSOrderedDescending) {
                    if (self.verboseLogging)
                    {
                        NSLog(@"getRated setting latestAppStoreVersion %@", latestVersion);
                    }
                    [self setLatestAppStoreVersionCached:latestVersion];
                    if (completion) completion(NO, latestVersion, currentVersion, appStoreIDString);
                } else {
                    if (completion) completion(YES, latestVersion, currentVersion, appStoreIDString);
                }
            } else {
                if (self.verboseLogging)
                {
                    NSLog(@"getRated could not find your app on iTunes. If your app is not yet on the store or is not intended for App Store release then don't worry about this");
                }
                if (completion) completion(NO, nil, currentVersion, nil);
            }
        });
    });
}

#pragma mark - Network Connectivity
- (BOOL)hasConnection
{
    const char *host = getRatedItunesUrl;
    BOOL reachable;
    BOOL success;
    
    //must link SystemConfiguration.framework! <SystemConfiguration/SystemConfiguration.h>
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, host);
    SCNetworkReachabilityFlags flags;
    success = SCNetworkReachabilityGetFlags(reachability, &flags);
    reachable = success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);
    CFRelease(reachability);
    return reachable;
}

- (void)openRatingsPageOnAppStore
{
    if ([self hasConnection])
    {
        if (!self.appStoreID)
        {
            [self getLatestAppData:^(BOOL isLatestVersion, NSString *appStoreVersion, NSString *currentVersion, NSString *appStoreID) {
                if (self.appStoreID)
                {
                    if (self.verboseLogging)
                    {
                        NSLog(@"getRated will open the App Store ratings page");
                    }
                    [self setRequestedRating];
                    [self openRatingsPageWithAppID:appStoreID];
                    [[NSNotificationCenter defaultCenter] postNotificationName:getRatedDidOpenRatingsPageOnAppSore
                                                                        object:nil];
                }
                else
                {
                    if (self.verboseLogging)
                    {
                        NSLog(@"getRated could not find your app on iTunes. If your app is not yet on the store or is not intended for App Store release then don't worry about this");
                    }
                }
            }];
            return;
        }
        else
        {
            if (self.verboseLogging)
            {
                NSLog(@"getRated will open the App Store ratings page");
            }
            [self setRequestedRating];
            [self openRatingsPageWithAppID:[NSString stringWithFormat:@"%lu", (unsigned long)self.appStoreID]];
            [[NSNotificationCenter defaultCenter] postNotificationName:getRatedDidOpenRatingsPageOnAppSore
                                                                object:nil];
        }
    }
    else
    {
        if (self.verboseLogging)
        {
            NSLog(@"getRated did not open the App Store ratings page as no network connection was found");
        }
    }
}

- (void)openRatingsPageWithAppID:(NSString *)appId{
    
    NSURL *ratingsURL = [NSURL URLWithString:[NSString stringWithFormat:getRatedAppStoreURLFormat, appId]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_10_0
        
        [[UIApplication sharedApplication] openURL:ratingsURL options:@{} completionHandler:^(BOOL success){
            if (success)
            {
                if (self.verboseLogging)
                {
                    NSLog(@"getRated opened the App Store ratings page %@", ratingsURL);
                }
            }
            else
            {
                if (self.verboseLogging)
                {
                    NSLog(@"getRated error opening the App Store ratings page %@. Note the App Store is not available on the iOS simulator", ratingsURL);
                }
            }
        }];
        
#else
        
        if ([[UIApplication sharedApplication] openURL:ratingsURL])
        {
            if (self.verboseLogging)
            {
                NSLog(@"getRated opened the App Store ratings page %@", ratingsURL);
            }
        }
        else
        {
            if (self.verboseLogging)
            {
                NSLog(@"getRated error opening the App Store ratings page %@. Note the App Store is not available on the iOS simulator", ratingsURL);
            }
        }
        
#endif
        
    });
}

@end

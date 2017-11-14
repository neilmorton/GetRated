//
//  getRated.m
//
//  Version 0.1.0
//
//  Created by Neil Morton on 29/09/2017.
//  Copyright © 2017 Neil Morton. All rights reserved.
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
//  4. getRated was inspired by, and in parts based on iRate by Nick Lockwood.
//  It was developed to provide an easy way to manage SKStoreReviewController.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <StoreKit/StoreKit.h>

@interface getRated : NSObject

+ (instancetype)sharedInstance;

//start getRate - should be called AFTER any optional configuration options (below)
- (void)start;

//application version - this is set automatically
@property (nonatomic, copy) NSString *applicationVersion;

//usage settings - these have sensible defaults
@property (nonatomic, assign) float daysUntilFirstPrompt;
@property (nonatomic, assign) float daysUntilFuturePrompts;
@property (nonatomic, assign) float minimumDaysUntilPromptAfterVersionUpdate;
@property (nonatomic, assign) NSUInteger usesUntilPrompt;
@property (nonatomic, assign) NSUInteger eventsUntilPrompt;

//prompt and debug overrides
@property (nonatomic, assign) BOOL onlyPromptIfLatestVersion;
@property (nonatomic, assign) BOOL promptAtLaunch;
@property (nonatomic, assign) BOOL verboseLogging;
@property (nonatomic, assign) BOOL previewMode;
@property (nonatomic, assign) BOOL promptEnabled;

//advanced properties for implementing custom behaviour
@property (nonatomic, strong) NSDate *appFirstUsed;
@property (nonatomic, strong) NSDate *versionFirstUsed;
@property (nonatomic, strong) NSDate *lastRequestedRating;
@property (nonatomic, assign) NSUInteger usesCount;
@property (nonatomic, assign) NSUInteger eventCount;

//manually control behaviour
- (BOOL)shouldPromptForRating;
- (void)promptForRating;
- (void)promptIfAllCriteriaMet;
- (void)openRatingsPageOnAppStore;
- (void)logEvent:(BOOL)deferPrompt;

@end


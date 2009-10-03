/*
 
 The MIT License
 
 Copyright (c) 2008-2009 ClickToFlash Developers
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "SparkleManager.h"
#import <Sparkle/Sparkle.h>

#import "CTFUserDefaultsController.h"
#import "CTFPreferencesDictionary.h"

#import <objc/runtime.h>

// NSUserDefaults keys
static NSString *sAutomaticallyCheckForUpdates = @"checkForUpdatesOnFirstLoad";

@implementation SparkleManager

+ (id)sharedManager {
    static SparkleManager *result = nil;
    if (!result) {
        result = [[SparkleManager alloc] init];
    }
    return result;
}

- (void)dealloc {
    [_updater setDelegate:nil];
    [super dealloc];
}

- (BOOL)canUpdate {
    return (_updater != nil);
}

- (NSBundle *)frameworkForBundle:(NSBundle *)aBundle
{
	// Check the provided bundle for an embedded copy of the Sparkle framework.
	// Return an NSBundle for the framework if found, nil if not.
	
	NSString *frameworksPath = [aBundle privateFrameworksPath];
	NSString *sparkleFrameworkPath = [NSBundle pathForResource:@"Sparkle" ofType:@"framework" inDirectory:frameworksPath];
	
	NSBundle *framework = nil;
	
	if (sparkleFrameworkPath)
	{
		framework = [NSBundle bundleWithPath:sparkleFrameworkPath];
	}
	
	return framework;
}

- (NSBundle *)sparkleFrameworkRespectingHost
{
	// Check the host for an embedded version of Sparkle.
	// If we find one and it's version equals our own, return the host bundle.
	// If it's version is not compatible with ours, return nil. (disables update checks)
	// If the host doesn't make use of Sparkle, we return our own version of the bundle.
	// * This doesn't handle playing nice with other plugins.
	
	NSBundle *sparkleBundle = nil;
	
	NSBundle *sparkleForPlugin = [self frameworkForBundle:[NSBundle bundleForClass:[self class]]];
	NSBundle *sparkleForHost = [self frameworkForBundle:[NSBundle mainBundle]];
	
	if (sparkleForHost)
	{
		// The host provides Sparkle services. Use those if they match our requirements.
		
		NSString *hostVersion = [sparkleForHost objectForInfoDictionaryKey:@"CFBundleVersion"];
		NSString *bundledVersion = [sparkleForPlugin objectForInfoDictionaryKey:@"CFBundleVersion"];
		
		if ([hostVersion isEqualToString:bundledVersion])
		{
			sparkleBundle = sparkleForHost;
		}
	}
	
	else
	{
		// The host doesn't provide Sparkle. We'll use our version.
		
		sparkleBundle = sparkleForPlugin;
	}
	
	return sparkleBundle;
}

- (SUUpdater*)_updater {
	
    if (_updater)
        return _updater;
    
	NSBundle *sparkleFramework = [self sparkleFrameworkRespectingHost];
	
	// Since we only use Sparkle if it's the required version, we can assume the
	// required methods are present. We fail silently (log to console) if we encounter
	// any errors. Since we don't require major diagnostics the error handling is
	// mostly via nil messaging.
	
	Class updaterClass = [sparkleFramework classNamed:@"SUUpdater"];
	NSBundle *clickToFlashBundle = [NSBundle bundleWithIdentifier:@"com.github.rentzsch.clicktoflash"];
	
	if (clickToFlashBundle)
	{
		_updater = [updaterClass updaterForBundle:clickToFlashBundle];
		
		[_updater setDelegate:self];
	}
	
	if (_updater == nil) NSLog(@"ClickToFlash Sparkle updates disabled for host.");
	
	return _updater;
}

- (void)startAutomaticallyCheckingForUpdates {
    if (![[CTFUserDefaultsController standardUserDefaults] objectForKey:sAutomaticallyCheckForUpdates]) {
        // If the key isn't set yet, default to YES, automatically check for updates.
        [[CTFUserDefaultsController standardUserDefaults] setBool:YES forKey:sAutomaticallyCheckForUpdates];
    }
    
	SUUpdater *updater = [self _updater];
	if (updater) {
		if ([[CTFUserDefaultsController standardUserDefaults] boolForKey:sAutomaticallyCheckForUpdates]) {
			[updater setAutomaticallyChecksForUpdates:YES];
            static BOOL calledUpdaterApplicationDidFinishLaunching = NO;
            if (!calledUpdaterApplicationDidFinishLaunching) {
                calledUpdaterApplicationDidFinishLaunching = YES;
                [updater applicationDidFinishLaunching:nil];
            }
		} else {
			[updater setAutomaticallyChecksForUpdates:NO];
		}
	}
}

- (void)checkForUpdates {
    [[self _updater] checkForUpdates:nil];
}

- (void)setAutomaticallyChecksForUpdates:(BOOL)checksForUpdates
{
	[[self _updater] setAutomaticallyChecksForUpdates:checksForUpdates];
}

- (NSString*)pathToRelaunchForUpdater:(SUUpdater*)updater {
    return _pathToRelaunch;
}

- (BOOL)updater:(SUUpdater *)updater
shouldPostponeRelaunchForUpdate:(SUAppcastItem *)update
  untilInvoking:(NSInvocation *)invocation;
{
	NSString *appNameString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
	int relaunchResult = NSRunAlertPanel([NSString stringWithFormat:@"Relaunch %@ now?",appNameString],
										 [NSString stringWithFormat:@"To use the new features of ClickToFlash, %@ needs to be relaunched.",appNameString],
										 @"Relaunch",
										 @"Do not relaunch",
										 nil);
	
	BOOL shouldPostpone = YES;
	if (relaunchResult == NSAlertDefaultReturn) {
		// we want to relaunch now, so don't postpone the relaunch
		
		shouldPostpone = NO;
	} else {
		// we want to postpone the relaunch and let the user decide when to do so,
		// so we don't even bother with saving the invocation and reinvoking
		// it later
	}
	return shouldPostpone;
}

- (NSString *)pathToRelaunch
{
	return _pathToRelaunch;
}
- (void)setPathToRelaunch:(NSString *)newValue
{
	[newValue retain];
	[_pathToRelaunch release];
	_pathToRelaunch = newValue;
}

@end

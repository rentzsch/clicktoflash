//
//  SparkleManager.m
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-10-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SparkleManager.h"

#ifdef DEBUG
#define SU_DEFAULT_CHECK_INTERVAL 60
#else
#define SU_DEFAULT_CHECK_INTERVAL 60*60*24
#endif

// NSUserDefaults keys
static NSString *sAutomaticallyCheckForUpdates = @"checkForUpdatesOnFirstLoad";
static NSString *sLastUpdateCheck = @"CTFLastUpdateCheck";

@implementation SparkleManager

+ (id)sharedManager {
    static SparkleManager *result = nil;
    if (!result) {
        result = [[SparkleManager alloc] init];
    }
    return result;
}

- (void)dealloc;
{
	if (updaterTimer) [updaterTimer invalidate];
	[super dealloc];
}

- (void)activateUpdater:(id)sender inBackground:(BOOL)background;
{
	NSString *updaterAppPath = [[[NSBundle bundleForClass:[self class]] resourcePath]
								stringByAppendingPathComponent:@"ClickToFlash Updater.app"];
	NSString *updaterExecutablePath = [updaterAppPath stringByAppendingPathComponent:@"Contents/MacOS/ClickToFlash Updater"];
	
	/* the following should work, but for some reason it doesn't
	 NSString *updaterPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"ClickToFlash Updater"
	 ofType:@"app"];*/
	
	
	NSArray *launchedApps = [[NSWorkspace sharedWorkspace] launchedApplications];
	BOOL foundUpdater = NO;
	unsigned int i;
	for (i = 0; i < [launchedApps count]; i++) {
		NSString *currentBundleId = [[launchedApps objectAtIndex:i] objectForKey:@"NSApplicationBundleIdentifier"];
		if ( [currentBundleId isEqualToString:@"com.github.rentzsch.clicktoflash-updater"] ) {
			foundUpdater = YES;
			break;
		}
	}
	
	
	
	// the reason to launch via NSTask is because the Sparkle updater needs
	// to know about the host app so it can relaunch the host app after updating
	// ClickToFlash
	
	// an NSNotification here doesn't work so well because (unless I'm missing
	// something) we can't know that the updater is launched and ready by the time 
	// we send the notification, without simply delaying an arbitrary number of
	// seconds
	
	// inter-app communication via NSProxyObjects is inadvisable since there
	// are likely going to be many ClickToFlash objects available
	
	if (! foundUpdater) {
		NSArray *argsArray;
		if (background) {
			argsArray = [NSArray arrayWithObjects:[CTFClickToFlashPlugin launchedAppBundleIdentifier],@"--background",nil];
		} else {
			argsArray = [NSArray arrayWithObject:[CTFClickToFlashPlugin launchedAppBundleIdentifier]];
		}
		
		// we save our own last update check date instead of relying on Sparkle because
		// Sparkle's date is saved *after* the check is done, and that can cause multiple
		// updaters to launch because the old date could be checked by other instances
		// of the ClickToFlash plug-in (since many instances can be created on load
		// of a single page)

		[[CTFUserDefaultsController standardUserDefaults] setObject:[NSDate date]
															 forKey:sLastUpdateCheck];
		[NSTask launchedTaskWithLaunchPath:updaterExecutablePath
								 arguments:argsArray];
	} else {
		// send a notification to the existing updater to activate itself
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"CTFSparkleUpdaterShouldActivate"
																	   object:nil];
	}
}

- (void)resetUpdaterTimer;
{
	if (updaterTimer) [updaterTimer invalidate];
	updaterTimer = [NSTimer scheduledTimerWithTimeInterval:SU_DEFAULT_CHECK_INTERVAL
													target:self
												  selector:@selector(automaticallyCheckForUpdates)
												  userInfo:nil
												   repeats:YES];
}

- (void)automaticallyCheckForUpdates;
{
	if ([[CTFUserDefaultsController standardUserDefaults] objectForKey:sAutomaticallyCheckForUpdates]) {
		NSDate *lastUpdateCheck = [[CTFUserDefaultsController standardUserDefaults] objectForKey:sLastUpdateCheck];
		if (lastUpdateCheck) {
			int intervalSinceLastCheck = (int)[[NSDate date] timeIntervalSinceDate:lastUpdateCheck];
			if (intervalSinceLastCheck >= SU_DEFAULT_CHECK_INTERVAL) {
				// one day has passed since the last check
				[self activateUpdater:self inBackground:YES];
			}
		} else {
			// updater has never run, run it now, now, now!
			[self activateUpdater:self inBackground:YES];
		}
	}
	
	[self resetUpdaterTimer];
}

- (void)checkForUpdatesNow;
{
	[self activateUpdater:self inBackground:NO];
	[self resetUpdaterTimer];
}

- (void)setAutomaticallyChecksForUpdates:(BOOL)autoChecks;
{
	[[CTFUserDefaultsController standardUserDefaults] setBool:autoChecks
													   forKey:sAutomaticallyCheckForUpdates];
}

@end

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

- (void)activateUpdater;
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
		[NSTask launchedTaskWithLaunchPath:updaterExecutablePath
								 arguments:[NSArray arrayWithObject:[CTFClickToFlashPlugin launchedAppBundleIdentifier]]];
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
		NSDate *lastUpdateCheck = [[CTFUserDefaultsController standardUserDefaults] objectForKey:@"SULastCheckTime"];
		if (lastUpdateCheck) {
			int intervalSinceLastCheck = [[NSDate date] timeIntervalSinceDate:lastUpdateCheck];
			if (intervalSinceLastCheck > SU_DEFAULT_CHECK_INTERVAL) {
				// one day has passed since the last check
				[self activateUpdater];
			}
		} else {
			// updater has never run, run it now, now, now!
			[self activateUpdater];
		}
	}
	
	[self resetUpdaterTimer];
}

@end

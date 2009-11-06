//
//  CTFSparkleManager.m
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-10-26.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CTFSparkleManager.h"



@implementation CTFSparkleManager

- (void)awakeFromNib;
{	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateDriverDidFinish:)
												 name:@"SUUpdateDriverFinished"
											   object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(activateSelf:)
												 name:@"CTFSparkleUpdaterShouldActivate"
											   object:nil];
	[[SUUpdater sharedUpdater] setDelegate:self];
    
    {
        //  Truth table:
        //
        //  isBeta	useBetaAppcast
        //  ------  --------------
        //  true	true            Beta in a beta land. Easy: check beta appcast.
        //  false	true            Golden, but opted into betas by previously running a beta. Check beta appcast.
        //  true	false           Beta with a beta-virgin user. Set useBetaAppcast user default to true and check beta appcast.
        //  false	false           Golden boy -- never tried a beta. Check golden appcast.
        
        NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
        BOOL isBeta = [[infoPlist objectForKey:@"CFBundleVersion"] rangeOfString:@"b"].location != NSNotFound;
        BOOL useBetaAppcast = [[NSUserDefaults standardUserDefaults] boolForKey:@"useBetaAppcast"];
        NSString *feedURLKey = (!isBeta && !useBetaAppcast) ? @"SUFeedURL" : @"SUBetaFeedURL";
        if (isBeta && !useBetaAppcast) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"useBetaAppcast"];
        }
        [[SUUpdater sharedUpdater] setFeedURL:[NSURL URLWithString:[infoPlist objectForKey:feedURLKey]]];
    }
	
	NSArray *launchArgs = [[NSProcessInfo processInfo] arguments];
	NSString *checkInBackground = nil;
	if ([launchArgs count] > 2) {
		
		checkInBackground = [launchArgs objectAtIndex:2];
	}
	
	if (checkInBackground && [checkInBackground isEqualToString:@"--background"]) {
		[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
	} else {
		[[SUUpdater sharedUpdater] checkForUpdates:nil];
	}
}

- (void)updateDriverDidFinish:(NSNotification *)notification;
{
	[NSApp terminate:self];
}

- (void)activateSelf:(NSNotification *)notification;
{
	[NSApp activateIgnoringOtherApps:YES];
}

- (NSString*)pathToRelaunchForUpdater:(SUUpdater*)updater;
{
	NSString *hostAppBundleIdentifier = [[[NSProcessInfo processInfo] arguments] objectAtIndex:1];
	NSString *pathToRelaunch = [[NSWorkspace sharedWorkspace]
								absolutePathForAppBundleWithIdentifier:hostAppBundleIdentifier];
	return pathToRelaunch;
}

- (BOOL)updater:(SUUpdater *)updater
shouldPostponeRelaunchForUpdate:(SUAppcastItem *)update
  untilInvoking:(NSInvocation *)invocation;
{
	NSString *hostAppBundleIdentifier = [[[NSProcessInfo processInfo] arguments] objectAtIndex:1];
	NSString *appNameString = [[[NSBundle bundleWithIdentifier:hostAppBundleIdentifier] infoDictionary] objectForKey:@"CFBundleName"];
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

- (void)updater:(SUUpdater *)updater
didFindValidUpdate:(SUAppcastItem *)update;
{
	[NSApp activateIgnoringOtherApps:YES];
}

@end

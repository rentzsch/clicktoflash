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
	//NSLog(@"updater arguments: %@",[[NSProcessInfo processInfo] arguments]);
	[NSApp activateIgnoringOtherApps:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateDriverDidFinish:)
												 name:@"SUUpdateDriverFinished"
											   object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(activateSelf:)
												 name:@"CTFSparkleUpdaterShouldActivate"
											   object:nil];
	[[SUUpdater sharedUpdater] setDelegate:self];
	[[SUUpdater sharedUpdater] checkForUpdates:nil];
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
	NSString *hostAppBundleIdentifier = [[[NSProcessInfo processInfo] arguments] objectAtIndex:0];
	NSString *pathToRelaunch = [[NSWorkspace sharedWorkspace]
								absolutePathForAppBundleWithIdentifier:hostAppBundleIdentifier];
	return pathToRelaunch;
}

- (BOOL)updater:(SUUpdater *)updater
shouldPostponeRelaunchForUpdate:(SUAppcastItem *)update
  untilInvoking:(NSInvocation *)invocation;
{
	NSString *hostAppBundleIdentifier = [[[NSProcessInfo processInfo] arguments] objectAtIndex:0];
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

@end

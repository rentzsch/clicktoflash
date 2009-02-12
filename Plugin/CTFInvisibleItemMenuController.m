//
//  CTFInvisibleItemMenuController.m
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-02-02.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CTFInvisibleItemMenuController.h"
#import "Plugin.h"
#import "Safari.h"
#include <sys/types.h>
#include <unistd.h>
#import <OSAKit/OSAKit.h>

@implementation CTFInvisibleItemMenuController

@synthesize plugin;
@synthesize targets;

- (IBAction)loadInvisibleFlashContent:(id)sender;
{
	// [[NSBundle mainBundle] bundleIdentifier|executablePath|bundlePath] all return stuff for Safari
	// even if called from WebKit

	// the following line crashes WebKit, so we can't use the Scripting Bridge until that is fixed
	// SafariApplication *safari = [SBApplication applicationWithProcessIdentifier:getpid()];
	
	BOOL isWebKit = [[[NSProcessInfo processInfo] arguments] containsObject:@"-WebKitDeveloperExtras"];
	NSString *appString = @"";
	if (isWebKit) {
		appString = @"WebKit";
	} else {
		appString = @"Safari";
	}
	
	NSString *appleScriptSourceString = [NSString stringWithFormat:@"tell application \"%@\"\nURL of current tab of front window\nend tell",appString];
	
	
	// I didn't want to bring OSACrashyScript into this, but I had to; sorry guys, Scripting Bridge
	// just totally crashes WebKit and that's unacceptable
	
	NSDictionary *errorDict = nil;
	OSAScript *browserNameScript = [[OSAScript alloc] initWithSource:appleScriptSourceString];
	NSAppleEventDescriptor *aeDesc = [browserNameScript executeAndReturnError:&errorDict];
	[browserNameScript release];

	[plugin performSelector:@selector(loadInvisibleFlashContentForBaseURL:) withObject:[aeDesc stringValue] afterDelay:0];
}

- (NSMenuItem *)menu;
{
	return theMenu;
}

- (NSMenuItem *)loadInvisibleContentMenuItem;
{
	return loadInvisibleContentMenuItem;
}

@end

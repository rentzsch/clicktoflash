//
//  CTFUserDefaultsController.m
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-05-23.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CTFUserDefaultsController.h"


@implementation CTFUserDefaultsController

- (void)awakeFromNib;
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(pluginDefaultsDidChange:)
												 name:@"ClickToFlashPluginDefaultsDidChange"
											   object:nil];
	[self setValues:[CTFPreferencesDictionary dictionaryWithDictionary:
					 [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.github.rentzsch.clicktoflash"]]
	 ];
}

- (void)dealloc;
{
	[userDefaultsDict release];
	[super dealloc];
}

- (CTFPreferencesDictionary *)values;
{
	return userDefaultsDict;
}

- (void)setValues:(CTFPreferencesDictionary *)newUserDefaultsDict;
{
	if (! userDefaultsDict) userDefaultsDict = [[CTFPreferencesDictionary alloc] init]; 
	[userDefaultsDict removeAllObjects];
	[userDefaultsDict addEntriesFromDictionary:newUserDefaultsDict];
}

- (void)pluginDefaultsDidChange:(NSNotification *)notification;
{
	NSLog(@"Setting persistent domain defaults: %@", userDefaultsDict);
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:userDefaultsDict
													   forName:@"com.github.rentzsch.clicktoflash"];
}

@end

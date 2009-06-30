//
//  CTFPreferencesDictionary.m
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-05-25.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
//	the rationale for this class is so that we can monitor when
//	defaults change, and update the *external* preference file accordingly.
//	to do so, we need to monitor the mutable dictionary that represents the
//  defaults.  this class follows @bbum's suggestion at this URL:
//  http://www.omnigroup.com/mailman/archive/macosx-dev/1999-April/007726.html

#import "CTFPreferencesDictionary.h"

static CTFPreferencesDictionary *sharedInstance = nil;

@implementation CTFPreferencesDictionary

+ (id)dictionaryWithDictionary:(NSDictionary *)otherDictionary;
{
	return [[[CTFPreferencesDictionary alloc] initWithDictionary:otherDictionary] autorelease];
}

+ (id)allocWithZone:(NSZone *)zone;
{
	if (sharedInstance) {
		return [sharedInstance retain];
	} else {
		return [super allocWithZone:zone];
	}
}

- (id)init;
{
	if (! sharedInstance) {
		if ((self = [super init])) {
			realMutableDictionary = [[NSMutableDictionary alloc] init];
			hasInited = YES;
		}
	}
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *)otherDictionary;
{
	if (! sharedInstance) {
		if ((self = [super init])) {
			realMutableDictionary = [[NSMutableDictionary dictionaryWithDictionary:otherDictionary] retain];
			hasInited = YES;
		}
	} else {
		[sharedInstance setDictionary:otherDictionary];
	}
	
	return self;
}

- (void)dealloc;
{
	[realMutableDictionary release];
	[super dealloc];
}

- (void)setObject:(id)object forKey:(id)key;
{
	[realMutableDictionary setObject:object forKey:key];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ClickToFlashPluginDefaultsDidChange" object:self];
}

- (void)removeObjectForKey:(id)key;
{
	[realMutableDictionary removeObjectForKey:key];
}

- (id)objectForKey:(id)key;
{
	return [realMutableDictionary objectForKey:key];
}

- (NSUInteger)count;
{
	return [realMutableDictionary count];
}

- (NSEnumerator *)keyEnumerator;
{
	return [realMutableDictionary keyEnumerator];
}

@end

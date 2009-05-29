//
//  CTFPreferencesDictionary.m
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-05-25.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CTFPreferencesDictionary.h"


@implementation CTFPreferencesDictionary

+ (id)dictionaryWithDictionary:(NSDictionary *)otherDictionary;
{
	return [[CTFPreferencesDictionary alloc] initWithDictionary:otherDictionary];
}

- (id)init;
{
	if ((self = [super init])) {
		realMutableDictionary = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *)otherDictionary;
{
	if ((self = [super init])) {
		realMutableDictionary = [[NSMutableDictionary dictionaryWithDictionary:otherDictionary] retain];
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
	NSLog(@"posting a notification of defaults change");
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

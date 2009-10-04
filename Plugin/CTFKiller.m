/*
  CTFKiller.m
  ClickToFlash

 The MIT License
 
 Copyright (c) 2009 ClickToFlash Developers
 
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

#import "CTFKiller.h"
#import "Plugin.h"



@implementation CTFKiller

+ (CTFKiller*) killerForURL: (NSURL*) theURL src: (NSString*) theSrc attributes: (NSDictionary*) attributes forPlugin:(CTFClickToFlashPlugin*) thePlugin {
	CTFKiller * theKiller = nil;
	NSArray * killerArray = [NSArray arrayWithObjects: NSClassFromString(@"CTFKillerYouTube"), NSClassFromString(@"CTFKillerVimeo"), NSClassFromString(@"CTFKillerSIFR"),nil];
	NSEnumerator * myEnum = [killerArray objectEnumerator];
	Class killerClass; 
	while ((killerClass = [myEnum nextObject])) {
		if ([killerClass canHandleFlashAtURL: theURL src: theSrc attributes: attributes forPlugin: thePlugin]) {
			theKiller = [[(CTFKiller*)[killerClass alloc] initWithURL:theURL src: theSrc attributes: attributes forPlugin: thePlugin] autorelease];
			break;
		}
	}
	
	return theKiller;
}


+ (BOOL) canHandleFlashAtURL: (NSURL*) theURL src: (NSString*) theSrc attributes: (NSDictionary*) attributes forPlugin:(CTFClickToFlashPlugin*) thePlugin {
	return NO;
}


- (id) initWithURL: (NSURL*) theURL src:(NSString*) theSrc attributes: (NSDictionary*) theAttributes forPlugin:(CTFClickToFlashPlugin*) thePlugin {
	self = [super init];
	if (self != nil) {
		[self setPageURL: theURL];
		[self setSrcURLString: theSrc];
		[self setAttributes: theAttributes];
		NSString * fV  = [[self attributes] objectForKey: @"flashvars" ];
		[self setFlashVars: [CTFClickToFlashPlugin flashVarDictionary: fV]];
		[self setPlugin: thePlugin];
		
		[self setup];		
	}
	
	return self;
}

- (void) setup { }

- (NSString*) badgeLabelText {
	return @"CTFKiller";
}

- (void) addPrincipalMenuItemToContextualMenu { }

- (void) addAdditionalMenuItemsForContextualMenu { }

- (BOOL) convertToContainer { return NO; }


- (void) dealloc {
	[self setPageURL: nil];
	[self setSrcURLString: nil];
	[self setAttributes: nil];
	[self setFlashVars: nil];
	[self setPlugin: nil];
	[super dealloc];
}





#pragma mark ACCESSOR METHODS

- (NSURL *)pageURL
{
	return pageURL;
}

- (void)setPageURL:(NSURL *)newPageURL
{
	[newPageURL retain];
	[pageURL release];
	pageURL = newPageURL;
}


- (NSString *)srcURLString
{
	return srcURLString;
}

- (void)setSrcURLString:(NSString *)newSrcURLString
{
	[newSrcURLString retain];
	[srcURLString release];
	srcURLString = newSrcURLString;
}


- (NSDictionary *)attributes
{
	return attributes;
}

- (void)setAttributes:(NSDictionary *)newAttributes
{
	[newAttributes retain];
	[attributes release];
	attributes = newAttributes;
}


- (NSString*) flashVarWithName: (NSString*) argName
{
    return [[[ flashVars objectForKey: argName ] retain] autorelease];
}


- (NSDictionary *)flashVars
{
	return flashVars;
}

- (void)setFlashVars:(NSDictionary *)newFlashVars
{
	[newFlashVars retain];
	[flashVars release];
	flashVars = newFlashVars;
}


- (CTFClickToFlashPlugin *)plugin
{
	return plugin;
}

- (void)setPlugin:(CTFClickToFlashPlugin *)newPlugin
{
	[newPlugin retain];
	[plugin release];
	plugin = newPlugin;
}


@end

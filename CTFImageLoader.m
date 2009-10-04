//
//  CTFKillerImageLoader.m
//  ClickToFlash
//
//  Created by  Sven on 04.10.09.
//  Copyright 2009 earthlingsoft. All rights reserved.
//

#import "CTFImageLoader.h"
#import "Plugin.h"


@implementation CTFImageLoader

- (id) initWithURL: (NSURL *) theURL forPlugin: (CTFClickToFlashPlugin *) thePlugin {
	self = [super init];
	
	if (self != nil) {
		data = [[NSMutableData alloc] initWithCapacity:125000];
		plugin = [thePlugin retain];
		
		NSURLRequest * request = [NSURLRequest requestWithURL: theURL];
		[[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
		[self retain];
	}
	
	return self;
}


- (void) dealloc {
	[data release];
	[plugin release];
	[super dealloc];
}



- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *) newData {
	[data appendData: newData];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSImage * image = [[[NSImage alloc] initWithData: data] autorelease];
	if (image != nil) {
		[plugin setPreviewImage: image ];
	}

	[self cleanup];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"ClickToFlash couldn't download preview image: %@", [error description]);
	[self cleanup];
}


- (void) cleanup {
	[self autorelease];
}


@end

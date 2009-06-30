//
//  CTFURLConnection.m
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-06-30.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CTFURLConnection.h"


@implementation CTFURLConnection


- (NSHTTPURLResponse *)getURLResponseHeaders:(NSURL *)URL
									   error:(NSError **)error;
{
	theLock = [[NSConditionLock alloc] initWithCondition:0];
	
	NSLog(@"URL: %@",[URL absoluteString]);
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
	[request setHTTPMethod:@"HEAD"];
	
	
	// this header is required, because otherwise the URLRequest will download
	// the whole video before returning, which completely defeats the purpose
	// of checking for the video variants in the first place
	
	// this limits the download to the first 2 bytes of the video, which is
	// sufficient to see if there is a video there or not.
	
	// since the Range header is not always honored, we also stop getting data
	// from the NSURLConnection by stopping it once we get the NSURLResponse
	//[request setValue:@"bytes=0-1" forHTTPHeaderField:@"Range"];
	
	[NSThread detachNewThreadSelector:@selector(startRequest:) toTarget:self withObject:request];
	NSLog(@"Locking...");
	[theLock lockWhenCondition:1];
	*error = errorToReturn;
	return responseToReturn;
}

+ (NSHTTPURLResponse *)getURLResponseHeaders:(NSURL *)URL
									   error:(NSError **)error;
{
	CTFURLConnection *theConnection = [[CTFURLConnection alloc] init];
	NSHTTPURLResponse *theResponse = [theConnection getURLResponseHeaders:URL
																	error:error];
	[theConnection autorelease];
	return theResponse;
}

- (void)startRequest:(NSURLRequest *)request;
{
	NSLog(@"Starting request...");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NSURLConnection alloc] initWithRequest:request
									delegate:self
							startImmediately:YES];
	NSLog(@"%@",request);
	[pool drain];
	NSLog(@"Request should have started...");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	NSLog(@"Connection errored.");
	[theLock tryLock];
	
	errorToReturn = error;
	[theLock unlockWithCondition:1];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)theResponse;
{
	NSLog(@"Connection responded.");
	[theLock tryLock];
	
	// we cancel here, because otherwise NSURLConnection will continue to download
	// data due to a bug; even though we made a HEAD request, it still downloads
	// all the data at the given URL instead of stopping after receiving headers
	[connection cancel];
	responseToReturn = theResponse;
	[theLock unlockWithCondition:1];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
	NSLog(@"Connection finished.");
	[theLock tryLock];
	
	[theLock unlockWithCondition:1];
}

@end

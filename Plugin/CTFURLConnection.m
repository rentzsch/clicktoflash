//
//  CTFURLConnection.m
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-06-30.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CTFURLConnection.h"


@implementation CTFURLConnection

- (id)init;
{
	if ((self = [super init])) {
		responseToReturn = nil;
	}
	
	return self;
}

- (NSHTTPURLResponse *)getURLResponseHeaders:(NSURL *)URL
									   error:(NSError **)error;
{
	theLock = [[NSConditionLock alloc] initWithCondition:0];

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
	[request setHTTPMethod:@"HEAD"];
	
	
	// this header is required, because otherwise the URLRequest will download
	// the whole video before returning, which completely defeats the purpose
	// of checking for the video variants in the first place
	
	// this limits the download to the first 2 bytes of the video, which is
	// sufficient to see if there is a video there or not.
	
	// since the Range header is not always honored, we also stop getting data
	// from the NSURLConnection by stopping it once we get the NSURLResponse
	[request setValue:@"bytes=0-1" forHTTPHeaderField:@"Range"];
	
	[NSThread detachNewThreadSelector:@selector(startRequest:) toTarget:self withObject:request];
	[request release];
	
	[theLock lockWhenCondition:1];
	[theLock unlock];
	if (error) (*error) = errorToReturn;

	return [responseToReturn autorelease];
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
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[request retain];
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request
																  delegate:self
														  startImmediately:YES];
	
	NSRunLoop *rl = [NSRunLoop currentRunLoop];
	
	while ([rl runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
		if ([theLock tryLockWhenCondition:1]) {
			[theLock unlock];
			break;
		}
	}

	[connection release];

	[request release];
	[pool drain];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	[theLock lock];
	
	errorToReturn = error;
	[theLock unlockWithCondition:1];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)theResponse;
{
	[theLock lock];
	
	// we cancel here, because otherwise NSURLConnection will continue to download
	// data due to a bug; even though we made a HEAD request, it still downloads
	// all the data at the given URL instead of stopping after receiving headers
	[connection cancel];
	responseToReturn = [theResponse retain];
	[theLock unlockWithCondition:1];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
	[theLock lock];
	
	[theLock unlockWithCondition:1];
}

@end

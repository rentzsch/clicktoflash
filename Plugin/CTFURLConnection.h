//
//  CTFURLConnection.h
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-06-30.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CTFURLConnection : NSObject {
	NSConditionLock *theLock;
	NSHTTPURLResponse *responseToReturn;
	NSError *errorToReturn;
}

- (NSHTTPURLResponse *)getURLResponseHeaders:(NSURL *)URL
									   error:(NSError **)error;
+ (NSHTTPURLResponse *)getURLResponseHeaders:(NSURL *)URL
									   error:(NSError **)error;

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)theResponse;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end

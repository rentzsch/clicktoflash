/*
 CTFKillerVimeo.m
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


#import "CTFKillerVimeo.h"
#import "Plugin.h"
#import "CTFUtilities.h"
#import "CTFUserDefaultsController.h"

@implementation CTFKillerVimeo

#pragma mark CTFKiller subclass overrides

+ (BOOL) canHandleFlashAtURL: (NSURL*) theURL src: (NSString*) theSrc attributes: (NSDictionary*) attributes forPlugin:(CTFClickToFlashPlugin*) thePlugin {
	BOOL result = NO;
	
	result = result || ([theSrc rangeOfString:@"/moogaloop" options:NSAnchoredSearch].location != NSNotFound);
	
	NSURL * srcURL = [NSURL URLWithString: theSrc];
	if (srcURL != nil && [srcURL host] != nil) {
		result = result || ([[srcURL host] rangeOfString:@"vimeo.com" options:NSAnchoredSearch|NSBackwardsSearch].location != NSNotFound);
	}
	
	return result;
}



- (void) setup {
	[self setClipID: nil];
	[self setClipSignature: nil];
	[self setClipExpires: nil];
	downloadData = nil;
	lookupStatus = nothing;
	
	NSString * myID = [ self flashVarWithName:@"clip_id" ]; 

	if (myID == nil) {
		// we are embedded?
		NSArray * ar = [srcURLString componentsSeparatedByString:@"?"];
		if ( [ar count] > 0 ) {
			NSString * varString = [ar objectAtIndex:1];
			[self setFlashVars: [CTFClickToFlashPlugin flashVarDictionary:varString]];
			myID = [self flashVarWithName:@"clip_id"];
		}
	}
	
	if (myID != nil) {
		[self setClipID: myID];		
		[self getXML];
	}
}


- (void) dealloc {
	[self setClipID: nil];
	[self setClipSignature: nil];
	[self setClipExpires: nil];
	[super dealloc];
}





#pragma mark -
#pragma mark CTFVideoKiller subclassing overrides

// Name of the video service that can be used for automatic link text generation 
- (NSString*) siteName { 
	return CtFLocalizedString(@"Vimeo", @"Name of Vimeo");
}



// URL to the video file used for loading it in the player.
- (NSString *) videoURLString {
	NSString * URLString = nil;
	
	if ( clipID != nil && clipSignature != nil && clipExpires != nil) {
		URLString = [NSString stringWithFormat:@"http://vimeo.com/moogaloop/play/clip:%@/%@/%@/", clipID, clipSignature, clipExpires];
	}
	
	return URLString;
}


- (NSString *) videoHDURLString {
	NSString * URLString = nil;
	URLString = [[self videoURLString] stringByAppendingString:@"/?q=hd"];
	return URLString;
}



// URL of the web page displaying the video. Return nil if there is none.
- (NSString *) videoPageURLString {
	NSString * URLString = nil;
	if ( [self clipID] != nil ) {
		URLString = [NSString stringWithFormat:@"http://vimeo.com/%@", [self clipID]];
	}
	return URLString;
}






#pragma mark -
#pragma mark Determine Video type

/*
 1. download the XML file which provides the keys required to construct the URL to access the video file
 2. get headers for the video file to check whether it actually is MP4 
 [e.g  http://vimeo.com/1039366 doesn't seem to have a MP4 version]
*/

- (void) getXML {
	NSString * XMLURLString = [NSString stringWithFormat:@"http://vimeo.com/moogaloop/load/clip:%@", [self clipID]];
	NSURLRequest * request = [NSURLRequest requestWithURL: [NSURL URLWithString:XMLURLString]];
	if (request != nil) {
		downloadData = [[NSMutableData alloc] initWithLength:20000];
		[NSURLConnection connectionWithRequest: request delegate:self];
		[self setLookupStatus: inProgress];
	}
	else {
		[self setLookupStatus: failed];
	}
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[downloadData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if  ([self isFetchingXML]) {
		// only run when fetching the XML file, not for the video file header
		NSError * error;
		NSXMLDocument * XML = [[[NSXMLDocument alloc] initWithData:downloadData options:NSXMLDocumentTidyXML error:&error] autorelease];
		[self finishXMLFetching: connection];
		
		NSXMLNode * node;
		if (XML != nil) {
			NSArray * nodes = [XML nodesForXPath:@"//request_signature" error:&error];
			if ([nodes count] > 0) {
				node = [nodes objectAtIndex:0];
				[self setClipSignature:[node stringValue]];
			}
			nodes = [XML nodesForXPath:@"//request_signature_expires" error:&error];
			if ([nodes count] > 0) {
				node = [nodes objectAtIndex:0];
				[self setClipExpires: [node stringValue]];
			}
			CGFloat width = .0;
			nodes = [XML nodesForXPath:@"//width" error:&error];
			if ([nodes count] > 0) {
				node = [nodes objectAtIndex:0];
				width = [[node stringValue] floatValue];
			}
			CGFloat height = .0;
			nodes = [XML nodesForXPath:@"//height" error:&error];
			if ([nodes count] > 0) {
				node = [nodes objectAtIndex:0];
				height = [[node stringValue] floatValue];
			}
			videoSize = NSMakeSize(width, height);
			nodes = [XML nodesForXPath:@"//thumbnail" error:&error];
			if ([nodes count] > 0) {
				node = [nodes objectAtIndex:0];
				[self setPreviewURL: [NSURL URLWithString:[node stringValue]]];
			}
			nodes = [XML nodesForXPath:@"//isHD" error:&error];
			if ([nodes count] > 0) {
				node = [nodes objectAtIndex:0];
				[self setHasVideoHD: ([[node stringValue] integerValue] != 0)];
			}
		}

		
		// Now we collected the data but vimeo seem to have two video formats in the background flv/mp4. The only way I see so far to tell those apart is from the MIME Type of the video file's URL. Any better way to do this would be great.
		NSMutableURLRequest * request = [[[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:[self videoURLString]]] autorelease];
		if (request != nil) {
			[request setHTTPMethod:@"HEAD"];
			[NSURLConnection connectionWithRequest: request delegate: self];
		}
		else {
			[self setLookupStatus: failed];
		}
	}	
}



- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if ( [self isFetchingXML]) {
		[self finishXMLFetching: connection];
	}
	else {
		[self finishHEADFetching: connection];
	}
	[self setLookupStatus: failed];
}



- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	// Only run this for the head fetching connection
	if ( [self isFetchingHEAD] ) {
		NSInteger statusCode = [response statusCode];
		NSString * contentType = [response MIMEType];
	
		if ( statusCode == 200 && [contentType isEqualToString: @"video/mp4"] ) {
			[self setHasVideo: YES];
			[self setLookupStatus: finished];
		}
		
		[self finishHEADFetching: connection];		
	}
}



- (void) finishXMLFetching: (NSURLConnection *) connection {
	[connection cancel];
	[downloadData release];
	downloadData = nil;
}


- (void) finishHEADFetching: (NSURLConnection *) connection {
	[connection cancel];
}



- (NSURLRequest *)connection:(NSURLConnection *)connection 
			 willSendRequest:(NSURLRequest *)request 
			redirectResponse:(NSURLResponse *)redirectResponse
{
	NSURLRequest * result = request;
	
	// For the head fetching we need to fix the redirects to make sure the method they use is HEAD.
	if ( [self isFetchingHEAD] ) {
		if (![[request HTTPMethod] isEqualTo:@"HEAD"]) {
			NSMutableURLRequest * newRequest = [[request mutableCopy] autorelease];
			[newRequest setHTTPMethod:@"HEAD"];
			result = newRequest;
		}
	}

	return result;
}


// At most one connection runs at a time, if the downloadData variable is non-nil, it's the XML connection. Only for use inside the fetching methods.
- (BOOL) isFetchingXML {
	BOOL result = (downloadData != nil);
	return result;
}


- (BOOL) isFetchingHEAD {
	BOOL result = (downloadData == nil);
	return result;
}





#pragma mark ACCESSORS

- (NSString *)clipID
{
	return clipID;
}

- (void)setClipID:(NSString *)newClipID
{
	[newClipID retain];
	[clipID release];
	clipID = newClipID;
}

- (NSString *)clipSignature
{
	return clipSignature;
}

- (void)setClipSignature:(NSString *)newClipSignature
{
	[newClipSignature retain];
	[clipSignature release];
	clipSignature = newClipSignature;
}

- (NSString *)clipExpires
{
	return clipExpires;
}

- (void)setClipExpires:(NSString *)newClipExpires
{
	[newClipExpires retain];
	[clipExpires release];
	clipExpires = newClipExpires;
}



@end

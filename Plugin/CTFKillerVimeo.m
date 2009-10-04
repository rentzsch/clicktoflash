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
#import <QTKit/QTKit.h>

@implementation CTFKillerVimeo

#pragma mark CTFKiller subclass overrides

+ (BOOL) canHandleFlashAtURL: (NSURL*) theURL src: (NSString*) theSrc attributes: (NSDictionary*) theAttributes forPlugin:(CTFClickToFlashPlugin*) thePlugin {
	BOOL result = NO;
	
	if ([CTFKillerVideo isActive]) {
		result = ([theSrc rangeOfString:@"/moogaloop" options:NSAnchoredSearch].location != NSNotFound);
		
		NSURL * srcURL = [NSURL URLWithString: theSrc];
		if (srcURL != nil && [srcURL host] != nil) {
			result = result || ([[srcURL host] rangeOfString:@"vimeo.com" options:NSAnchoredSearch|NSBackwardsSearch].location != NSNotFound);
		}		
	}
	
	return result;
}



- (void) setup {
	[self setClipID: nil];
	[self setClipSignature: nil];
	[self setClipExpires: nil];
	[self setRedirectedURLString: nil];
	downloadData = nil;
	currentConnection = noConnection;
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
	[self setRedirectedURLString: nil];
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
	NSString * URLString = [self redirectedURLString];
	return URLString;
}


- (NSString *) videoHDURLString {
	NSString * URLString = nil;
	URLString = [[self videoURLString] stringByAppendingString:@"?q=hd"];
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
 2. get headers for the video file to figure out its file format. MP4 URL seem to be usable right away, but FLV URL (which require Perian anyway) seem to include a redirect which the WebKit video element doesn't seem to resolve.
 [e.g  http://vimeo.com/1039366 doesn't seem to have a MP4 version]
 3. For FLV files resolve the redirect.
*/

- (void) getXML {
	NSString * XMLURLString = [NSString stringWithFormat:@"http://vimeo.com/moogaloop/load/clip:%@", [self clipID]];
	NSURLRequest * request = [NSURLRequest requestWithURL: [NSURL URLWithString:XMLURLString]];
	if (request != nil) {
		downloadData = [[NSMutableData alloc] initWithLength: 20000];
		[NSURLConnection connectionWithRequest: request delegate:self];
		[self setCurrentConnection: XML];
		[self setLookupStatus: inProgress];
	}
	else {
		[self setLookupStatus: failed];
	}
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if ( [self currentConnection] == XML ) {
		[downloadData appendData:data];		
	}
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if  ( [self currentConnection] == XML ) {
		// only run when fetching the XML file, not for the video file header
		NSError * error = nil;
		NSXMLDocument * XML = [[[NSXMLDocument alloc] initWithData:downloadData options:NSXMLDocumentTidyXML error:&error] autorelease];
		[self finishXMLFetching: connection];
		[self setCurrentConnection: noConnection];
		
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
				[[self plugin] setPreviewURL: [NSURL URLWithString:[node stringValue]]];
			}
			nodes = [XML nodesForXPath:@"//isHD" error:&error];
			if ([nodes count] > 0) {
				node = [nodes objectAtIndex:0];
				[self setHasVideoHD: ([[node stringValue] integerValue] != 0)];
			}
		}

		
		// Now we collected the data but vimeo seem to have two video formats in the background flv/mp4. The only way I see so far to tell those apart is from the MIME Type of the video file's URL. Any better way to do this would be great.		
		NSString * HEADURLString = [NSString stringWithFormat:@"http://vimeo.com/moogaloop/play/clip:%@/%@/%@/", [self clipID], [self clipSignature], [self clipExpires]];

		NSMutableURLRequest * request = [[[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: HEADURLString]] autorelease];
		if (request != nil) {
			[request setHTTPMethod:@"HEAD"];
			[self setCurrentConnection: HEAD];
			[NSURLConnection connectionWithRequest: request delegate: self];
		}
		else {
			[self setLookupStatus: failed];
		}
	}	
}



- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	switch ([self currentConnection]) {
		case XML:
			[self finishXMLFetching: connection];
			break;
		case HEAD:
			[self finishHEADFetching: connection];
			break;
		default:
			break;
	}
	
	[self setCurrentConnection: noConnection ];
	[self setLookupStatus: failed];
}



- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	NSInteger statusCode = [response statusCode];
	NSString * contentType = [response MIMEType];

	if ( [self currentConnection] == HEAD ) {
		if ( statusCode == 200 ) {
			if ([contentType isEqualToString: @"video/mp4"] ) {
				[self setHasVideo: YES];
				[self setLookupStatus: finished];
			}
			else if ( [contentType isEqualToString: @"video/x-flv"] ) {
				if ( [[QTMovie movieFileTypes: QTIncludeCommonTypes] containsObject: @"flv"] ) {
					// QuickTime can play flv (Perian?)
					[self setHasVideo: YES];
				}
			}
		}
		[self finishHEADFetching: connection];
		[self setCurrentConnection: noConnection];
		[self setLookupStatus: finished];
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
//	NSLog(@"type %i, redirect to: %@", [self currentConnection], [[request URL] absoluteString]);
																  
	// For the head fetching we need to fix the redirects to make sure the method they use is HEAD.
	if ( [self currentConnection] == HEAD ) {
		if (![[request HTTPMethod] isEqualTo:@"HEAD"]) {
			NSMutableURLRequest * newRequest = [[request mutableCopy] autorelease];
			[newRequest setHTTPMethod:@"HEAD"];
			result = newRequest;
		}
		[self setRedirectedURLString: [[request URL] absoluteString]];
	} 		
	
	return result;
}



#pragma mark -
#pragma mark Accessors

- (NSString *) clipID {
	return clipID;
}

- (void) setClipID: (NSString *) newClipID {
	[newClipID retain];
	[clipID release];
	clipID = newClipID;
}

- (NSString *) clipSignature {
	return clipSignature;
}

- (void) setClipSignature: (NSString *) newClipSignature {
	[newClipSignature retain];
	[clipSignature release];
	clipSignature = newClipSignature;
}

- (NSString *) clipExpires {
	return clipExpires;
}

- (void) setClipExpires: (NSString *) newClipExpires {
	[newClipExpires retain];
	[clipExpires release];
	clipExpires = newClipExpires;
}


- (NSString *) redirectedURLString {
	return redirectedURLString;
}

- (void) setRedirectedURLString: (NSString *) newRedirectedURLString {
	[newRedirectedURLString retain];
	[redirectedURLString release];
	redirectedURLString = newRedirectedURLString;
}


- (enum CTFVimeoConnectionType) currentConnection {
	return currentConnection;
}

- (void) setCurrentConnection: (enum CTFVimeoConnectionType) newConnectionType {
	currentConnection = newConnectionType;
}

@end

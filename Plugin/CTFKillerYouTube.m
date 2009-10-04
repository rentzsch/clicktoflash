/*
 CTFKillerYouTube.m
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

#import "CTFKillerYouTube.h"
#import "CTFUserDefaultsController.h"
#import "Plugin.h"
#import "CTFUtilities.h"

@implementation CTFKillerYouTube


#pragma mark CTFKiller subclassing overrides

+ (BOOL) canHandleFlashAtURL: (NSURL*) theURL src: (NSString*) theSrc attributes: (NSDictionary*) attributes forPlugin:(CTFClickToFlashPlugin*) thePlugin {
	BOOL result = NO;

	if (theSrc != nil) {
		NSURL * srcURL = [NSURL URLWithString: theSrc];
		NSString * host = [srcURL host];
		if (host != nil ) {
			result = result 
			|| ( [host rangeOfString: @"youtube.com" options: NSAnchoredSearch|NSBackwardsSearch].location != NSNotFound )
			|| ( [host rangeOfString: @"youtube-nocookie.com" options: NSAnchoredSearch|NSBackwardsSearch].location != NSNotFound )
			|| ( [host rangeOfString: @"ytimg.com" options: NSAnchoredSearch|NSBackwardsSearch].location != NSNotFound );
		}
	}
	
	if (!result) {
		NSString* fV = [attributes objectForKey: @"flashvars" ];
		if (fV != nil) {
			NSDictionary * flashVars = [CTFClickToFlashPlugin flashVarDictionary:fV];
			NSString * URLString = [flashVars objectForKey:@"rv.0.url"];
			if (URLString != nil) {
				result = result || ([URLString rangeOfString: @"youtube.com"].location != NSNotFound )
				|| ([URLString rangeOfString: @"youtube-nocookie.com"].location != NSNotFound );
			}		
		}
	}
	
	return result;
}



- (void) setup {
	lookupStatus = nothing;
	NSString * myVideoID = [ self flashVarWithName:@"video_id" ]; 
	
	if (myVideoID != nil) {
		[self setVideoID: myVideoID];
		// this retrieves new data from the internets, but the NSURLConnection
		// methods already spawn separate threads for the data retrieval,
		// so no need to spawn a separate thread

		[self setLookupStatus: inProgress];
		[self _checkForH264VideoVariants];
	} 
	else {
		// it's an embedded YouTube flash view; scrub the URL to
		// determine the video_id, then get the source of the YouTube
		// page to get the Flash vars
			
		NSScanner *URLScanner = [[NSScanner alloc] initWithString: srcURLString ];
		[URLScanner scanUpToString:@"youtube.com/v/" intoString:nil];
		if ([URLScanner scanString:@"youtube.com/v/" intoString:nil]) {
			// URL is in required format, next characters are the id
			
			[URLScanner scanUpToString:@"&" intoString:&myVideoID];
		} else {
			[URLScanner setScanLocation:0];
			[URLScanner scanUpToString:@"youtube-nocookie.com/v/" intoString:nil];
			if ([URLScanner scanString:@"youtube-nocookie.com/v/" intoString:nil]) {
				[URLScanner scanUpToString:@"&" intoString:&myVideoID];
			}
		}
		[URLScanner release];
		
		if (myVideoID != nil) {
			[self setVideoID: myVideoID];
			// this block of code introduces a situation where we have to download
			// additional data from the internets, so we want to spin this off
			// to another thread to prevent blocking of the Safari user interface
			
			[self setLookupStatus: inProgress];
			// this method is a stub for calling the real method on a different thread
			[self _getEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:videoID];
		}
	}
	
	if ([CTFKillerYouTube isYouTubeSiteURL: pageURL]) {
		[self setAutoPlay: YES];
	} else {
		[self setAutoPlay: [[self flashVarWithName: @"autoplay"] isEqualToString:@"1"]];
	}
}


- (void) dealloc {
	[self setVideoID: nil];
	[connections[0] cancel];
	[connections[0] release];
	[connections[1] cancel];
	[connections[1] release];
			
	[super dealloc];
}





#pragma mark -
#pragma mark CTFVideoKiller subclassing overrides

// Name of the video service that can be used for automatic link text generation 
- (NSString*) siteName { 
	return CtFLocalizedString(@"YouTube", @"Name of YouTube");
}



// URL to the video file used for loading it in the player.
- (NSString*) videoURLString { 
	NSString * result = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=18&video_id=%@&t=%@", [self videoID], [self videoHash] ];

	return result;
} 


- (NSString*) videoHDURLString { 
	NSString * result = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=22&video_id=%@&t=%@", [self videoID], [self videoHash] ];

	return result; 
}



// URL of the web page displaying the video. Return nil if there is none.
- (NSString *) videoPageURLString
{
	return [ NSString stringWithFormat: @"http://www.youtube.com/watch?v=%@", [self videoID] ];
}





#pragma mark -
#pragma mark CTFKillerYouTube methods

+ (BOOL) isYouTubeSiteURL: (NSURL*) theURL {
	NSString * host = [theURL host];
	BOOL result = [host isEqualToString:@"www.youtube.com"]	|| [host isEqualToString:@"www.youtube-nocookie.com"];

	return result;
}




#pragma mark -
#pragma mark Check for Videos

- (void)_checkForH264VideoVariants
{
	for (int i = 0; i < 2; ++i) {
		NSMutableURLRequest *request;
		NSString * URLString;
		if (i == 0) { URLString = [self videoURLString]; }
		else { URLString = [self videoHDURLString]; }
		
		request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:URLString]];
		
		if (request != nil) {
			[request setHTTPMethod:@"HEAD"];
			connections[i] = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		}
	}
	
	expectedResponses = 2;
	receivedAllResponses = NO;
}



- (void)finishedWithConnection:(NSURLConnection *)connection
{
	BOOL didReceiveAllResponses = YES;
	
	for (int i = 0; i < 2; ++i) {
		if (connection == connections[i]) {
			[connection cancel];
			[connection release];
			connections[i] = nil;
		} else if (connections[i])
			didReceiveAllResponses = NO;
	}
	
	if (didReceiveAllResponses) {
		receivedAllResponses = YES;
		[self setLookupStatus: finished];
	}
	
}



- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
	int statusCode = [response statusCode];
	
	if (statusCode == 200) {
		if (connection == connections[0])
			[self setHasVideo: YES];
		else 
			[self setHasVideoHD: YES];
	}
	
	[self finishedWithConnection:connection];
}



- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self finishedWithConnection:connection];
}



- (NSURLRequest *)connection:(NSURLConnection *)connection 
			 willSendRequest:(NSURLRequest *)request 
			redirectResponse:(NSURLResponse *)redirectResponse
{
	// We need to fix the redirects to make sure the method they use is HEAD.
	if ([[request HTTPMethod] isEqualTo:@"HEAD"])
		return request;
	
	NSMutableURLRequest *newRequest = [request mutableCopy];
	[newRequest setHTTPMethod:@"HEAD"];
	
	return [newRequest autorelease];
}






#pragma mark -
#pragma mark Other

- (void)_didRetrieveEmbeddedPlayerFlashVars:(NSDictionary *) playerFlashVars
{
	if (playerFlashVars != nil)
	{
		[self setFlashVars: playerFlashVars];
		NSString *myVideoID = [self flashVarWithName: @"video_id"];
		[self setVideoID: myVideoID];
	}
	
	[self _checkForH264VideoVariants];
}


- (void)_retrieveEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:(NSString *)videoId
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSURL *YouTubePageURL = [NSURL URLWithString: [self videoPageURLString]];
	NSError *pageSourceError = nil;
	NSString *pageSourceString = [NSString stringWithContentsOfURL:YouTubePageURL
													  usedEncoding:nil
															 error:&pageSourceError];
	NSDictionary *myFlashVars = nil;
	if (pageSourceString && !pageSourceError) {
		myFlashVars = [self _flashVarDictionaryFromYouTubePageHTML:pageSourceString];
	}
	
	[self performSelectorOnMainThread:@selector(_didRetrieveEmbeddedPlayerFlashVars:)
						   withObject:myFlashVars
						waitUntilDone:NO];
	
	[pool drain];
}


- (NSDictionary*) _flashVarDictionaryFromYouTubePageHTML: (NSString*) youTubePageHTML
{
	NSMutableDictionary* flashVarsDictionary = [ NSMutableDictionary dictionary ];
	NSScanner *HTMLScanner = [[NSScanner alloc] initWithString:youTubePageHTML];
	
	[HTMLScanner scanUpToString:@"var swfArgs = {" intoString:nil];
	BOOL swfArgsFound = [HTMLScanner scanString:@"var swfArgs = {" intoString:nil];
	
	if (swfArgsFound) {
		NSString *swfArgsString = nil;
		[HTMLScanner scanUpToString:@"}" intoString:&swfArgsString];
		NSArray *arrayOfSWFArgs = [swfArgsString componentsSeparatedByString:@", "];
		CTFForEachObject( NSString, currentArgPairString, arrayOfSWFArgs ) {
			NSRange sepRange = [ currentArgPairString rangeOfString:@": "];
			if (sepRange.location != NSNotFound) {
				NSString *potentialKey = [currentArgPairString substringToIndex:sepRange.location];
				NSString *potentialVal = [currentArgPairString substringFromIndex:NSMaxRange(sepRange)];
				
				// we might need to strip the surrounding quotes from the keys and values
				// (but not always)
				NSString *key = nil;
				if ([[potentialKey substringToIndex:1] isEqualToString:@"\""]) {
					key = [potentialKey substringWithRange:NSMakeRange(1,[potentialKey length] - 2)];
				} else {
					key = potentialKey;
				}
				
				NSString *val = nil;
				if ([[potentialVal substringToIndex:1] isEqualToString:@"\""]) {
					val = [potentialVal substringWithRange:NSMakeRange(1,[potentialVal length] - 2)];
				} else {
					val = potentialVal;
				}
				
				[flashVarsDictionary setObject:val forKey:key];
			}
		}
	}
	
	[HTMLScanner release];
	return flashVarsDictionary;
}


- (void)_getEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:(NSString *)videoId
{
	[NSThread detachNewThreadSelector:@selector(_retrieveEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:)
							 toTarget:self
						   withObject:videoId];
}




#pragma mark -
#pragma mark Accessors

- (NSString *)videoID
{
	return videoID;
}

- (void)setVideoID:(NSString *)newVideoID
{
	[newVideoID retain];
	[videoID release];
	videoID = newVideoID;
}


- (NSString*) videoHash
{
    return [ self flashVarWithName: @"t" ];
}

@end

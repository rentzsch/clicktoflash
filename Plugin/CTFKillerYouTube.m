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
#import "CTFLoader.h"

@implementation CTFKillerYouTube


#pragma mark CTFKiller subclassing overrides

+ (BOOL) canHandleFlashAtURL: (NSURL*) theURL src: (NSString*) theSrc attributes: (NSDictionary*) theAttributes forPlugin:(CTFClickToFlashPlugin*) thePlugin {
	BOOL result = NO;
	
	if ([CTFKillerVideo isActive]) {
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
			NSString* fV = [theAttributes objectForKey: @"flashvars" ];
			if (fV != nil) {
				NSDictionary * flashVars = [CTFClickToFlashPlugin flashVarDictionary:fV];
				NSString * URLString = [flashVars objectForKey:@"rv.0.url"];
				if (URLString != nil) {
					result = result || ([URLString rangeOfString: @"youtube.com"].location != NSNotFound )
					|| ([URLString rangeOfString: @"youtube-nocookie.com"].location != NSNotFound );
				}		
			}
		}
	}
	
	return result;
}




- (void) setup {
	lookupStatus = nothing;
	[self setInfoFromFlashVars];

	NSString * myVideoID = [self videoID];
	NSString * myVideoHash = [self videoHash];
	
	if (myVideoID != nil && myVideoHash != nil) {
		[self _checkForH264VideoVariants];
	} 
	else {
		// it's an embedded YouTube flash view; scrub the URL to
		// determine the video_id, then get the source of the YouTube
		// page to get the Flash vars
		
		if ( myVideoID == nil ) {
			NSURL * ytURL = [NSURL URLWithString: srcURLString];
			NSString * host = [ytURL host];
			if (([host rangeOfString:@"youtube.com" options: NSAnchoredSearch | NSBackwardsSearch].location != NSNotFound) || ([host rangeOfString:@"youtube-nocookie.com" options: NSAnchoredSearch | NSBackwardsSearch].location != NSNotFound ) ) {
				
				NSString * path = [ytURL path];
				NSRange lastSlashRange = [path rangeOfString:@"/" options:NSLiteralSearch | NSBackwardsSearch];
				NSInteger lastSlash = lastSlashRange.location;
				NSRange firstAmpersandRange = [path rangeOfString:@"&" options:NSLiteralSearch];
				if ( lastSlash != NSNotFound ) {
					NSInteger firstAmpersand = firstAmpersandRange.location;
					if (firstAmpersand == NSNotFound) {
						firstAmpersand = [path length];
					}
					if (lastSlash < firstAmpersand ) {
						NSRange IDRange = NSMakeRange(lastSlash + 1, firstAmpersand - lastSlash - 1);
						myVideoID = [path substringWithRange:IDRange];
					}
				}
			}			
		}
		
		
		if (myVideoID != nil) {
			[self setVideoID: myVideoID];

			// this block of code introduces a situation where we have to download
			// additional data from the internets, so we want to spin this off
			// to another thread to prevent blocking of the Safari user interface
			[self _getEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:videoID];
		}
	}
	
	if ( myVideoID != nil ) {
		[[self plugin] setPreviewURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://img.youtube.com/vi/%@/0.jpg", myVideoID]]];
	}
	
	if ([CTFKillerYouTube isYouTubeSiteURL: pageURL]) {
		[self setAutoPlay: YES];
	} else {
		[self setAutoPlay: [[self flashVarWithName: @"autoplay"] isEqualToString:@"1"]];
	}
}



- (void) dealloc {
	[self setVideoID: nil];
	[self setVideoHash: nil];
	
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
	NSString * result = nil;
	NSString * ID = [self videoID];
	NSString * hash = [self videoHash];
	if (ID != nil && hash != nil) {
		result = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=18&video_id=%@&t=%@", ID, hash ];		
	}

	return result;
} 


- (NSString*) videoHDURLString { 
	NSString * result = nil;
	NSString * ID = [self videoID];
	NSString * hash = [self videoHash];
	if (ID != nil && hash != nil) {	
		result = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=22&video_id=%@&t=%@", ID, hash ];
	}
	
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

- (void)_checkForH264VideoVariants {
	CTFLoader * loader;
	
	loader= [[[CTFLoader alloc] initWithURL: [NSURL URLWithString:[self videoURLString]] delegate: self selector: @selector(HEADDownloadFinished:)] autorelease];
	if (loader != nil) {
		[loader setHEADOnly: YES];
		[loader start];
		[self increaseActiveLookups];
	}
	else {
		[self setLookupStatus: failed];
	}
	
	loader= [[[CTFLoader alloc] initWithURL: [NSURL URLWithString:[self videoHDURLString]] delegate: self selector: @selector(HEADHDDownloadFinished:)] autorelease];
	if (loader != nil) {
		[loader setHEADOnly: YES];
		[loader start];
		[self increaseActiveLookups];
	}
	else {
		[self setLookupStatus: failed];
	}
}



- (void) HEADDownloadFinished: (CTFLoader *) loader {
	[self decreaseActiveLookups];
	
	if ( [self canPlayResponseResult: [loader response]] ) {
		[self setHasVideo: YES];
	}
}


- (void) HEADHDDownloadFinished: (CTFLoader *) loader {
	[self decreaseActiveLookups];
	
	if ( [self canPlayResponseResult: [loader response]] ) {
		[self setHasVideoHD: YES];
	}
}






#pragma mark -
#pragma mark Other


- (void) setInfoFromFlashVars {
	NSString * myVideoID = [self flashVarWithName: @"video_id"];
	if ( myVideoID != nil ) {
		if ( ![myVideoID isEqualToString: [self videoID]] ) {
			if ([self videoID] != nil) {
				NSLog(@"ClickToFlash: YouTube video with ambiguous IDs at %@ (%@, %@)", [self pageURL], [self videoID], myVideoID);
			}
			[self setVideoID: myVideoID];
		}
		
		NSString * myHash = [self flashVarWithName: @"t"];
		if ( myHash != nil ) {
			[self setVideoHash: myHash];
			[self _checkForH264VideoVariants];
		}
		else {
		//	NSLog(@"ClickToFlash: No 't' parameter found for video %@", [self videoID]);
		}
	}
}



- (void)_didRetrieveEmbeddedPlayerFlashVars:(NSDictionary *) playerFlashVars {
	if (playerFlashVars != nil) {
		[self setFlashVars: playerFlashVars];
		[self setInfoFromFlashVars];
		[self decreaseActiveLookups];
	}
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
	
	[HTMLScanner scanUpToString:@"var swfArgs = {" intoString: nil];
	BOOL swfArgsFound = [HTMLScanner scanString:@"var swfArgs = {" intoString:nil];
	if (!swfArgsFound) {
		// the magic words seems to be SWF_ARGS in places (or now?)
		[HTMLScanner setScanLocation:0];
		[HTMLScanner scanUpToString:@"'SWF_ARGS': {" intoString: nil];
		swfArgsFound = [HTMLScanner scanString:@"'SWF_ARGS': {" intoString:nil];
	}
		

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
	[self increaseActiveLookups];
	[NSThread detachNewThreadSelector:@selector(_retrieveEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:)
							 toTarget:self
						   withObject:videoId];
}




#pragma mark -
#pragma mark Accessors

- (NSString *)videoID {
	return videoID;
}

- (void)setVideoID:(NSString *)newVideoID {
	[newVideoID retain];
	[videoID release];
	videoID = newVideoID;
}


- (NSString*) videoHash {
	return videoHash;
}

- (void)setVideoHash:(NSString *)newVideoHash {
	[newVideoHash retain];
	[videoHash release];
	videoHash = newVideoHash;
}


@end

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
	BOOL result = [CTFKillerYouTube isYouTubeSiteURL: theURL];

	NSString* fV = [attributes objectForKey: @"flashvars" ];
	if (fV != nil) {
		result = result || ([fV rangeOfString: @"www.youtube.com"].location != NSNotFound )
		|| ([fV rangeOfString: @"www.youtube-nocookie.com"].location != NSNotFound );
	}
	
	if (theSrc != nil) {
		result = result || ( [theSrc rangeOfString: @"youtube.com"].location != NSNotFound )
		|| ( [theSrc rangeOfString: @"youtube-nocookie.com"].location != NSNotFound );
	}
	
	return result;
}



- (void) setup {
	hasH264Version = NO;
	hasH264HDVersion = NO;
	autoPlay = NO;
	
	NSString * myVideoID = [ self flashVarWithName:@"video_id" ]; 
	
	if (myVideoID != nil) {
		[self setVideoID: myVideoID];
		// this retrieves new data from the internets, but the NSURLConnection
		// methods already spawn separate threads for the data retrieval,
		// so no need to spawn a separate thread

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
			
			// this method is a stub for calling the real method on a different thread
			[self _getEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:videoID];
		}
	}
}


- (void) dealloc {
	[self setVideoID: nil];
	[super dealloc];
}



- (NSString*) badgeLabelText;
{
	NSString * label = nil;
	
	if( [ self useH264HDVersion ] ) {
		label = CtFLocalizedString( @"HD H.264", @"HD H.264 badge text" );
	} else if( [ self useH264Version ] ) {
		if (receivedAllResponses) {
			label = CtFLocalizedString( @"H.264", @"H.264 badge text" );
		} else {
			label = CtFLocalizedString( @"H.264…", @"H.264 badge waiting text" );
		}
    } else if( videoID != nil ) {
		// we check the video ID too because if it's a Flash ad on YouTube.com,
		// we don't want to identify it as an actual YouTube video -- but if
		// the flash object actually has a video ID parameter, it means its
		// a bona fide YouTube video
		
		if (receivedAllResponses) {
			label = CtFLocalizedString( @"YouTube", @"YouTube badge text" );
		} else {
			label = CtFLocalizedString( @"YouTube…", @"YouTube badge waiting text" );
		}
	}
	
	return label;
}



- (void) addPrincipalMenuItemToContextualMenu;
{
	NSMenuItem * menuItem;
	
	if ([self hasH264Version]) {
		[[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Load H.264", @"Load H.264 contextual menu item" ) 
											   action: @selector( loadH264: )
											   target: self ];
		if ([self hasH264HDVersion]) {
			if ([self useH264HDVersion]) {
				menuItem = [[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Load H.264 SD Version", @"Load Smaller Version contextual menu item (alternate for the standard Load H.264 item when the default uses the 'HD' version)" )
																  action: @selector( loadH264SD: )
																  target: self ];
			}
			else {
				menuItem = [[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Load H.264 HD Version", @"Load Larger Version  contextual menu item (alternate for the standard item when the default uses the non-'HD' version)" )
																  action: @selector( loadH264HD: )
																  target: self ];
			}
			[menuItem setAlternate:YES];
			[menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
		}
	}
}



- (void) addAdditionalMenuItemsForContextualMenu;
{
	NSMenuItem * menuItem;
	
	if (![self isOnVideoPage]) {
		// Command to Open YouTube page for embedded videos
		[[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Load YouTube.com page for this video", @"Load YouTube page contextual menu item" )
											   action: @selector( loadYouTubePage: )
											   target: self ];
	}
	
	if ([self hasH264Version]) {
		// menu item and alternate for full screen viewing in QuickTime Player
		[[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Play Fullscreen in QuickTime Player", @"Open Fullscreen in QT Player contextual menu item" )
											   action: @selector( openFullscreenInQTPlayer: )
											   target: self ];
		if ([self hasH264HDVersion]) {
			if ([self useH264HDVersion]) {
				menuItem = [[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Play Smaller Version Fullscreen in QuickTime Player", @"Open Smaller Version Fullscreen in QT Player contextual menu item (alternate for the standard item when the default uses the 'HD' version)" )
																  action: @selector( openFullscreenInQTPlayerSD: ) 
																  target: self ];
			}
			else {
				menuItem = [[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Play Larger Version Fullscreen in QuickTime Player", @"Open Larger Version Fullscreen in QT Player contextual menu item (alternate for the standard item when the default uses the non-'HD' version)" )
																  action: @selector( openFullscreenInQTPlayerHD: ) 
																  target: self ];
			}
			[menuItem setAlternate:YES];
			[menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
		}
		
		// menu item and alternate for downloading movie file
		[[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Download H.264", @"Download H.264 menu item" )
											   action: @selector( downloadH264: )
											   target: self ];
		if ([self hasH264HDVersion]) {
			if ([self useH264HDVersion]) {
				menuItem = [[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Download SD H.264", @"Download small size H.264 menu item (alternate for the standard item when the default uses the 'HD' version)" )
																  action: @selector( downloadH264SD: ) 
																  target: self ];
			}
			else {
				menuItem = [[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Download HD H.264", @"Download large size H.264 menu item (alternate for the standard item when the default uses the non-'HD' version)" )
																  action: @selector( downloadH264HD: ) 
																  target: self ];
			}
			[menuItem setAlternate:YES];
			[menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
		}
	}	
}



- (BOOL) convertToContainer {
	[self convertToMP4ContainerUsingHD:nil];
	return YES;
}




#pragma mark CTFVideoKiller subclass overrides

- (NSString *) videoPageURLString
{
	return [ NSString stringWithFormat: @"http://www.youtube.com/watch?v=%@", [self videoID] ];
}

- (NSString *) videoPageLinkText
{
	return CtFLocalizedString(@"Go to YouTube page", @"Text of link to YouTube page appearing beneath the video");
}


- (DOMElement *) enhanceVideoDescriptionElement: (DOMElement*) descriptionElement {
	if ( [self hasH264HDVersion] && ![self useH264HDVersion]) {
		// offer additional link for HD download if available
		NSString * extraLinkCSS = @"margin:0px;padding:0px;border:0px none;";
		DOMElement * extraDownloadLinkElement = [[descriptionElement ownerDocument] createElement: @"a"];
		[extraDownloadLinkElement setAttribute: @"href" value: [self H264HDURLString]];
		[extraDownloadLinkElement setAttribute: @"style" value: extraLinkCSS];
		[extraDownloadLinkElement setAttribute: @"class" value: @"clicktoflash-link videodownload"];
		[extraDownloadLinkElement setTextContent: CtFLocalizedString(@"(Larger Size)", @"Text of link to additional Large Size H.264 Download appearing beneath the video after the standard link")];
		[descriptionElement appendChild: extraDownloadLinkElement];
	}

	return descriptionElement;
}



#pragma mark CTFKillerYouTube methods

+ (BOOL) isYouTubeSiteURL: (NSURL*) theURL {
	NSString * host = [theURL host];
	BOOL result = [host isEqualToString:@"www.youtube.com"]	|| [host isEqualToString:@"www.youtube-nocookie.com"];

	return result;
}


- (BOOL) youTubeAutoPlay {
	BOOL result= NO;
	
	if ([[CTFUserDefaultsController standardUserDefaults] objectForKey:sYouTubeAutoPlay]) {
		if ([CTFKillerYouTube isYouTubeSiteURL: pageURL]){
			result = YES;
		} else {
			result = [[[CTFClickToFlashPlugin flashVarDictionary: srcURLString] objectForKey:@"autoplay"] isEqualToString:@"1"];
		}
	}
	
	return result;
}






#pragma mark Check for Videos


- (void)_checkForH264VideoVariants
{
	for (int i = 0; i < 2; ++i) {
		NSMutableURLRequest *request;
		NSString * URLString;
		if (i == 0) { URLString = [self H264URLString]; }
		else { URLString = [self H264HDURLString]; }
		
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
	
	if (didReceiveAllResponses) receivedAllResponses = YES;
	
	[plugin setNeedsDisplay:YES];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
	int statusCode = [response statusCode];
	
	if (statusCode == 200) {
		if (connection == connections[0])
			[self setHasH264Version:YES];
		else 
			[self setHasH264HDVersion:YES];
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
	/* We need to fix the redirects to make sure the method they use
	 is HEAD. */
	if ([[request HTTPMethod] isEqualTo:@"HEAD"])
		return request;
	
	NSMutableURLRequest *newRequest = [request mutableCopy];
	[newRequest setHTTPMethod:@"HEAD"];
	
	return [newRequest autorelease];
}





# pragma mark INSERT VIDEOS

/*
 The useHD parameter indicates whether we want to override the default behaviour to use or not use HD.
 Passing nil invokes the default behaviour based on user preferences and HD availability.
*/
- (void) convertToMP4ContainerUsingHD: (NSNumber*) useHD
{
	[plugin revertToOriginalOpacityAttributes];
	
	// Delay this until the end of the event loop, because it may cause self to be deallocated
	[plugin prepareForConversion];
	[self performSelector:@selector(_convertToMP4ContainerAfterDelayUsingHD:) withObject:useHD afterDelay:0.0];
}



- (void) _convertToMP4ContainerAfterDelayUsingHD: (NSNumber*) useHDNumber
{
	BOOL useHD = [ self useH264HDVersion ];
	if (useHDNumber) {
		useHD = [useHDNumber boolValue];
	}
	
	NSString * URLString;
	if ( useHD && [ self hasH264HDVersion ] ) {
		URLString = [ self H264HDURLString ];
	}
	else {
		URLString = [ self H264URLString ];
	}
	
	[self convertToMP4ContainerAtURL: URLString];
}
	



# pragma mark OTHER

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


#pragma mark ACTIONS

- (IBAction)loadH264:(id)sender;
{
    [self convertToMP4ContainerUsingHD:nil];
}

- (IBAction) loadH264SD:(id)sender;
{
	[self convertToMP4ContainerUsingHD:[NSNumber numberWithBool:NO]];
}

- (IBAction) loadH264HD:(id)sender;
{
	[self convertToMP4ContainerUsingHD:[NSNumber numberWithBool:YES]];
}


- (void) downloadH264UsingHD: (BOOL) useHD {
	NSString * URLString;
	if ( useHD && [self hasH264HDVersion]) {
		URLString = [ self H264HDURLString ];
	} else {
		URLString = [ self H264URLString ];
	}
	
	[plugin downloadURLString: URLString];
}


- (IBAction)downloadH264:(id)sender
{
	BOOL wantHD = [[CTFUserDefaultsController standardUserDefaults] boolForKey:sUseYouTubeHDH264DefaultsKey];
	[self downloadH264UsingHD: wantHD];
}


- (IBAction)downloadH264SD:(id)sender {
	[self downloadH264UsingHD: NO];
}


- (IBAction)downloadH264HD:(id)sender {
	[self downloadH264UsingHD: YES];
}


- (IBAction)loadYouTubePage:(id)sender
{	
    [plugin browseToURLString:[self videoPageURLString]];
}


- (void)openFullscreenInQTPlayerUsingHD:(BOOL) useHD {
	NSString * src;
	if (useHD && [self hasH264HDVersion]) {
		src = [ self H264HDURLString ];
	} else {
		src = [ self H264URLString ];
	}
	
	NSString *scriptSource = nil;
	if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_5) {
		// Snowy Leopard
		scriptSource = [NSString stringWithFormat:
						@"tell application \"QuickTime Player\"\nactivate\nopen URL \"%@\"\nrepeat while (front document is not presenting)\ndelay 1\npresent front document\nend repeat\nrepeat while (playing of front document is false)\ndelay 1\nplay front document\nend repeat\nend tell",src];
	} else {
		scriptSource = [NSString stringWithFormat:
						@"tell application \"QuickTime Player\"\nactivate\ngetURL \"%@\"\nrepeat while (display state of front document is not presentation)\ndelay 1\npresent front document scale screen\nend repeat\nrepeat while (playing of front document is false)\ndelay 1\nplay front document\nend repeat\nend tell",src];
	}
	NSAppleScript *openInQTPlayerScript = [[NSAppleScript alloc] initWithSource:scriptSource];
	[openInQTPlayerScript executeAndReturnError:nil];
	[openInQTPlayerScript release];	
}

- (IBAction)openFullscreenInQTPlayer:(id)sender;
{
	BOOL useHD = [[CTFUserDefaultsController standardUserDefaults] boolForKey:sUseYouTubeHDH264DefaultsKey];
	
	[self openFullscreenInQTPlayerUsingHD: useHD];
}

- (IBAction)openFullscreenInQTPlayerSD:(id)sender{
	[self openFullscreenInQTPlayerUsingHD: NO];	
}

- (IBAction)openFullscreenInQTPlayerHD:(id)sender{
	[self openFullscreenInQTPlayerUsingHD: YES];	
}






#pragma mark ACCESSORS

- (NSString *) H264URLString
{
    return [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=18&video_id=%@&t=%@", [self videoID], [self videoHash] ];
}

- (NSString *) H264HDURLString
{
    return [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=22&video_id=%@&t=%@", [self videoID], [self videoHash] ];
}

- (BOOL) hasH264Version
{
	return hasH264Version;
}

- (void) setHasH264Version:(BOOL)newValue
{
	hasH264Version = newValue;
	[plugin setNeedsDisplay:YES];
}

- (BOOL) hasH264HDVersion
{
	return hasH264HDVersion;
}

- (void) setHasH264HDVersion:(BOOL)newValue
{
	hasH264HDVersion = newValue;
	[plugin setNeedsDisplay:YES];
}

- (BOOL) useH264Version
{
    return [ self hasH264Version ] 
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sUseYouTubeH264DefaultsKey ]; 
}

- (BOOL) useH264HDVersion
{
	return [ self hasH264HDVersion ] 
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sUseYouTubeH264DefaultsKey ] 
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sUseYouTubeHDH264DefaultsKey ];
}


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

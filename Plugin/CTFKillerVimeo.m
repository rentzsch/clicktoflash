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
	clipIsMP4 = NO;
	clipIsHD = NO;
	downloadData = nil;
	
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



- (NSString*) badgeLabelText {
	NSString * label = nil;
	
	if ( [self hasMP4URL] ) {
		// can load proper video
		label = CtFLocalizedString( @"H.264", @"");
	}
	else if ( [self isProcessing] ) {
		// we're still downloading the XML
		label = CtFLocalizedString( @"Vimeo...", @"Vimeo waiting badge text");
	}
	else {
		label = CtFLocalizedString( @"Vimeo", @"Vimeo badge text");
	}
	
	return label;
}



- (void) addPrincipalMenuItemToContextualMenu;
{
	NSMenuItem * menuItem;
	
	if ([self hasMP4URL]) {
		[[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Load H.264", @"Load H.264 contextual menu item" ) 
											   action: @selector( loadH264: )
											   target: self ];
		if ([self hasHDVersion]) {
			if ([self useHDVersion]) {
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
	
	if ([self isOnVideoPage]) {
		// Command to Open YouTube page for embedded videos
		[[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Load YouTube.com page for this video", @"Load YouTube page contextual menu item" )
											   action: @selector( loadYouTubePage: )
											   target: self ];
	}
	
	if ([self hasMP4URL]) {
		// menu item and alternate for full screen viewing in QuickTime Player
		[[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Play Fullscreen in QuickTime Player", @"Open Fullscreen in QT Player contextual menu item" )
											   action: @selector( openFullscreenInQTPlayer: )
											   target: self ];
		if ([self hasHDVersion]) {
			if ([self useHDVersion]) {
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
		if ([self hasHDVersion]) {
			if ([self useHDVersion]) {
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
	BOOL success = NO;
	
	if ( clipIsMP4 ) {
		[[self plugin] revertToOriginalOpacityAttributes];
		[[self plugin] prepareForConversion];
		
		[self performSelector:@selector(convertToMP4ContainerAtURL:) withObject:[self MP4URLString] afterDelay:0.0];
		
		success = YES;
	}

	return success;
}




#pragma mark CTFKillerVideo subclass overrrides

- (NSString *) videoPageURLString {
	NSString * URLString = [NSString stringWithFormat:@"http://vimeo.com/%@", [self clipID]];
	return URLString;
}




#pragma mark DETERMINE VIDEO TYPE
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
		[[self plugin] setNeedsDisplay:YES];
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
		[self finishXMLFetching];
		
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
				clipIsHD = ([[node stringValue] integerValue] != 0);
			}
			
		}
		else {
			[[self plugin] setNeedsDisplay: YES];
		}

		
		// Now we collected the data but vimeo seem to have two video formats in the background flv/mp4. The only way I see so far to tell those apart is from the MIME Type of the video file's URL. Any better way to do this would be great.
		NSMutableURLRequest * request = [[[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:[self MP4URLString]]] autorelease];
		if (request != nil) {
			[request setHTTPMethod:@"HEAD"];
			[[[NSURLConnection alloc] initWithRequest: request delegate:self] autorelease];
		}
		else {
			[[self plugin] setNeedsDisplay:YES];
		}
	}	
}



- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if ( [self isFetchingXML]) {
		[self finishXMLFetching];
	}
	else {
		[self finishHEADFetching: connection];
	}
}



- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	// Only run this for the head fetching connection
	if ( [self isFetchingHEAD] ) {
		NSInteger statusCode = [response statusCode];
		NSString * contentType = [response MIMEType];
	
		if ( statusCode == 200 && [contentType isEqualToString: @"video/mp4"] ) {
			clipIsMP4 = YES;
		}
		
		[self finishHEADFetching: connection];		
	}
}



- (void) finishXMLFetching {
	[downloadData release];
	downloadData = nil;
	
	[[self plugin] setNeedsDisplay: YES];
}


- (void) finishHEADFetching: (NSURLConnection *) connection {
	[connection cancel];
	[connection release];
	
	[[self plugin] setNeedsDisplay: YES];
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


- (BOOL) isProcessing {
	BOOL result = ([self clipExpires] != nil) && ([self clipSignature] != nil) && !clipIsMP4;
	return result;
}



#pragma mark HELPERS 

- (BOOL) hasMP4URL {
	BOOL result = clipIsMP4;
	return result;
}


- (NSString *) MP4URLString {
	NSString * URLString = [NSString stringWithFormat:@"http://vimeo.com/moogaloop/play/clip:%@/%@/%@/", clipID, clipSignature, clipExpires];
	return URLString;
}


- (NSString *) MP4HDURLString {
	NSString * URLString = [[self MP4URLString] stringByAppendingString:@"/?q=hd"];
	return URLString;
}



/* needs figuring out, vimeo can provide smaller versions for HD videos */
- (BOOL) hasHDVersion {
	return clipIsHD;
}

- (BOOL) useHDVersion {
	return [ self hasHDVersion ] 
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sUseYouTubeH264DefaultsKey ] 
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sUseYouTubeHDH264DefaultsKey ];
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

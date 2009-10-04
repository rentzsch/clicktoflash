/*
 CTFKillerVideo.m
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

#import "CTFKillerVideo.h"
#import <WebKit/WebKit.h>
#import "CTFUserDefaultsController.h"
#import "CTFUtilities.h"
#import "Plugin.h"

static NSString * divCSS = @"margin:auto;padding:0px;border:0px none;text-align:center;display:block;float:none;";
static NSString * sDisableVideoElement = @"disableVideoElement";


@implementation CTFKillerVideo

#pragma mark Come and Go

- (id) init {
	self = [super init];
	if (self != nil) {
		autoPlay = NO;
		hasVideo = NO;
		hasVideoHD = NO;
		
		lookupStatus = nothing;
		requiresConversion = NO;
		
		videoSize = NSZeroSize;
		[self setPreviewURL:nil];
	}
	
	return self;
}


- (void) dealloc {
	[self setPreviewURL: nil];
	[super dealloc];
}



#pragma mark -
#pragma mark Default implementations to be overridden by subclasses

// Name of the video service that can be used for automatic link text generation 
- (NSString*) siteName { return nil; }

// URL to the video file used for loading it in the player.
- (NSString*) videoURLString { return nil;} 
- (NSString*) videoHDURLString { return nil; }

// URL for downloading the video file. Return nil to use the same URL the video element uses.
- (NSString *) videoDownloadURLString {	return nil; }
- (NSString *) videoHDDownloadURLString { return nil; }

// Text used for video file download link. Return nil to use standard text.
- (NSString *) videoDownloadLinkText { return nil; }

// URL of the web page displaying the video. Return nil if there is none.
- (NSString *) videoPageURLString { return nil; }

// Text used for link to video page. Return nil to use standard text.
- (NSString *) videoPageLinkText { return nil; }

// Edit or replace the markup that is added for the links beneath the video. The descriptionElement passed to the method already conatins Go to Webpage and Download Video File links.
- (DOMElement *) enhanceVideoDescriptionElement: (DOMElement*) descriptionElement {
	return descriptionElement;
}



// If we are on the video's home page return YES, otherwise NO. This is used to determine whether we need links pointing to the video's home page.
- (BOOL) isOnVideoPage {
	BOOL result = NO;
	NSString * videoPage = [self cleanURLString:[self videoPageURLString]];
	
	if (videoPage != nil) {
		NSString * URLString = [self cleanURLString:[[self pageURL] absoluteString]];
		result = [URLString hasPrefix: videoPage];
	}
	return result;
}





// Remove http:// and www. from beginning of URL.
- (NSString *) cleanURLString: (NSString*) URLString {
	NSString * result = URLString;

	NSRange range = [URLString rangeOfString:@"http://www." options:NSAnchoredSearch];
	if (range.location == NSNotFound) {
		range = [URLString rangeOfString:@"http://" options:NSAnchoredSearch];
	}
	if (range.location != NSNotFound) {
		result = [URLString substringFromIndex: range.length];
	}
	
	return result;
}
					


					
					
					
#pragma mark -
#pragma mark Subclass override of CTFKiller

// Create gemeric labels based on the Service's name, so our subclasses don't need to.
- (NSString*) badgeLabelText {
	NSString * label = nil;
	if( [ self useVideoHD ] ) {
		label = CtFLocalizedString( @"HD H.264", @"HD H.264 badge text" );
	} 
	else if( [ self useVideo ] ) {
		NSString * H264Name = CtFLocalizedString( @"H.264", @"H.264 badge text" );
		if ( [self lookupStatus] == finished ) {
			label = H264Name;
		} else {
			NSString * ellipsisFormat = CtFLocalizedString(@"%@...", @"");
			label = [NSString stringWithFormat: ellipsisFormat, H264Name];
		}
    } 
	else  {
		NSString * serviceName = [NSString stringWithFormat: CtFLocalizedString( @"%@ (VideoServiceName)", @"Format for badge text for video service. This should probably just be %@" ), [self siteName]];
		if ( [self lookupStatus] >= finished ) {
			label = serviceName;
		} else {
			NSString * ellipsisFormat = CtFLocalizedString(@"%@...", @"");
			label = [NSString stringWithFormat:ellipsisFormat, serviceName];
		}
	}
	
	return label;
}



// Create a default principal menu item, so our subclasses don't need to. The menu item loads the MP4 video according the current settings. If the video is available in another size as well, holding the option key will reveal a command to load that version instead.
- (void) addPrincipalMenuItemToContextualMenu;
{
	NSMenuItem * menuItem;
	
	if ([self hasVideo]) {
		[[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Load H.264", @"Load H.264 contextual menu item" ) 
											   action: @selector( loadVideo: )
											   target: self ];
		if ( [self hasVideoHD] ) {
			if ( [self useVideoHD] ) {
				menuItem = [[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Load H.264 SD Version", @"Load Smaller Version contextual menu item (alternate for the standard Load H.264 item when the default uses the 'HD' version)" )
																  action: @selector( loadVideoSD: )
																  target: self ];
			}
			else {
				menuItem = [[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Load H.264 HD Version", @"Load Larger Version  contextual menu item (alternate for the standard item when the default uses the non-'HD' version)" )
																  action: @selector( loadVideoHD: )
																  target: self ];
			}
			[menuItem setAlternate:YES];
			[menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
		}
	}
}



/* 
 Create a default set of additional menu items, so our subclasses don't need to. These consist of:
 1. A command to go to the web page belonging to the video (if there is one)
 2. A command for fullscreen playback in QuickTime Player. If the video is available in another size as well, holding the option key will reveal a command to load that version in QuickTime Player instead.
 3. A command to download the video file. If the video is available in another size as well, holding the option key will reveal a command to download that version instead.
*/
- (void) addAdditionalMenuItemsForContextualMenu;
{
	NSMenuItem * menuItem;
	NSString * formatString;
	NSString * labelString;
	
	if (![self isOnVideoPage] && [self videoPageURLString] != nil) {
		// Command to Open web page for embedded videos
		formatString = CtFLocalizedString( @"Load %@ page for this video", @"Load SITENAME page for this video contextual menu item" );
		labelString = [NSString stringWithFormat: formatString, [self siteName]];
		[[self plugin] addContextualMenuItemWithTitle: labelString
											   action: @selector( gotoVideoPage: )
											   target: self ];
	}
	
	if ( [self hasVideo] ) {
		// menu item and alternate for full screen viewing in QuickTime Player
		labelString = CtFLocalizedString( @"Play Fullscreen in QuickTime Player", @"Open Fullscreen in QT Player contextual menu item" );
		[[self plugin] addContextualMenuItemWithTitle: labelString
											   action: @selector( openFullscreenInQTPlayer: )
											   target: self ];
		if ( [self hasVideoHD]) {
			if ( [self useVideoHD] ) {
				labelString = CtFLocalizedString( @"Play Smaller Version Fullscreen in QuickTime Player", @"Open Smaller Version Fullscreen in QT Player contextual menu item (alternate for the standard item when the default uses the 'HD' version)" );
				menuItem = [[self plugin] addContextualMenuItemWithTitle: labelString
																  action: @selector( openFullscreenInQTPlayerSD: )
																  target: self ];
			}
			else {
				labelString = CtFLocalizedString( @"Play Larger Version Fullscreen in QuickTime Player", @"Open Larger Version Fullscreen in QT Player contextual menu item (alternate for the standard item when the default uses the non-'HD' version)" );
				menuItem = [[self plugin] addContextualMenuItemWithTitle: labelString
																  action: @selector( openFullscreenInQTPlayerHD: ) 
																  target: self ];
			}
			[menuItem setAlternate:YES];
			[menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
		}
		
		// menu item and alternate for downloading movie file
		labelString = CtFLocalizedString( @"Download H.264", @"Download H.264 menu item" );
		[[self plugin] addContextualMenuItemWithTitle: labelString
											   action: @selector( downloadVideo: )
											   target: self ];
		
		if ( [self hasVideoHD]) {
			if ( [self useVideoHD] ) {
				labelString = CtFLocalizedString( @"Download SD H.264", @"Download small size H.264 menu item (alternate for the standard item when the default uses the 'HD' version)" );
				menuItem = [[self plugin] addContextualMenuItemWithTitle: labelString
																  action: @selector( downloadVideoSD: ) 
																  target: self ];
			}
			else {
				labelString = CtFLocalizedString( @"Download HD H.264", @"Download large size H.264 menu item (alternate for the standard item when the default uses the non-'HD' version)" );
				menuItem = [[self plugin] addContextualMenuItemWithTitle: labelString
																  action: @selector( downloadVideoHD: ) 
																  target: self ];
			}
			[menuItem setAlternate:YES];
			[menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
		}
	}	
}



// Implement default container conversion: If there is a film, use it.
- (BOOL) convertToContainer {
	BOOL result = NO;
	
	if ([self lookupStatus] == finished && [self hasVideo]) {
		[self convertToMP4ContainerUsingHD:nil];
		result = YES;
	}
	else if ([self lookupStatus] == inProgress) {
		[self setRequiresConversion: YES];
		result = YES;
	}
	
	return result;
}



#pragma mark -
#pragma mark Actions

// Load the video in the WebView
- (IBAction) loadVideo:(id)sender {
    [self convertToMP4ContainerUsingHD: nil];
}

- (IBAction) loadVideoSD:(id)sender {
	[self convertToMP4ContainerUsingHD: [NSNumber numberWithBool:NO]];
}

- (IBAction) loadVideoHD:(id)sender {
	[self convertToMP4ContainerUsingHD: [NSNumber numberWithBool:YES]];
}


// Download the video's movie file
- (void) downloadVideoUsingHD: (BOOL) useHD {
	NSString * URLString = [self videoURLStringForHD: useHD];
	[[self plugin] downloadURLString: URLString];
}

- (IBAction) downloadVideo: (id) sender {
	BOOL wantHD = [[CTFUserDefaultsController standardUserDefaults] boolForKey:sUseYouTubeHDH264DefaultsKey];
	[self downloadVideoUsingHD: wantHD];
}

- (IBAction) downloadVideoSD: (id) sender {
	[self downloadVideoUsingHD: NO];
}

- (IBAction) downloadVideoHD: (id) sender {
	[self downloadVideoUsingHD: YES];
}


// Go to video's page in the browser
- (IBAction) gotoVideoPage:(id)sender {
	[[self plugin] browseToURLString:[self videoPageURLString]];
}



// Play the film fullscreen in QuickTime Player
- (void)openFullscreenInQTPlayerUsingHD:(BOOL) useHD {
	NSString * URLString = [self videoURLStringForHD: useHD];
	
	NSString *scriptSource = nil;
	if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_5) {
		// Snowy Leopard
		scriptSource = [NSString stringWithFormat:
						@"tell application \"QuickTime Player\"\nactivate\nopen URL \"%@\"\nrepeat while (front document is not presenting)\ndelay 1\npresent front document\nend repeat\nrepeat while (playing of front document is false)\ndelay 1\nplay front document\nend repeat\nend tell", URLString];
	} else {
		scriptSource = [NSString stringWithFormat:
						@"tell application \"QuickTime Player\"\nactivate\ngetURL \"%@\"\nrepeat while (display state of front document is not presentation)\ndelay 1\npresent front document scale screen\nend repeat\nrepeat while (playing of front document is false)\ndelay 1\nplay front document\nend repeat\nend tell",URLString];
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






#pragma mark -
#pragma mark Insert Video

- (void) _convertElementForMP4: (DOMElement*) element atURL: (NSString*) URLString
{
	// some tags (OBJECT) want a data attribute, and some want a src attribute
	// for some reason, though, some cloned elements are not reporting themselves
	// as OBJECT tags, even though they are; more investigation on this is needed,
	// but for now, setting both the data and the src attribute corrects the problem
	// (see bug #294)
	
	[ element setAttribute: @"data" value: URLString ];
	[ element setAttribute: @"src" value: URLString ];
	[ element setAttribute: @"type" value: @"video/mp4" ];
    [ element setAttribute: @"scale" value: @"aspect" ];
    if (autoPlay) {
		[ element setAttribute: @"autoplay" value: @"true" ];
	} else {
		[ element setAttribute: @"autoplay" value: @"false" ];
	}
    [ element setAttribute: @"cache" value: @"false" ];
	[ element setAttribute: @"bgcolor" value: @"transparent" ];
    [ element setAttribute: @"flashvars" value: nil ];
}



- (void) _convertElementForVideoElement: (DOMElement*) element atURL: (NSString*) URLString
{
    [ element setAttribute: @"src" value: URLString ];
	[ element setAttribute: @"autobuffer" value:@"autobuffer"];
	if (autoPlay) {
		[ element setAttribute: @"autoplay" value:@"autoplay" ];
	} else {
		if ( [element hasAttribute:@"autoplay"] )
			[ element removeAttribute:@"autoplay" ];
	}
	[ element setAttribute: @"controls" value:@"controls"];
	[ element setAttribute:@"width" value:@"100%"];
}



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
	BOOL useHD = [ self useVideoHD ];
	if (useHDNumber != nil) {
		useHD = [useHDNumber boolValue];
	}
	
	NSString * URLString = [self videoURLStringForHD: useHD];
	
	[self convertToMP4ContainerAtURL: URLString];
}



- (void) convertToMP4ContainerAtURL: (NSString*) URLString {
	DOMElement * container = [[self plugin] container];
	DOMDocument* document = [container ownerDocument];

	DOMElement* videoElement;
	if ([ self isVideoElementAvailable ]) {
		videoElement = [document createElement:@"video"];
		[ self _convertElementForVideoElement: videoElement atURL: URLString ];
    } else {
		videoElement = (DOMElement*) [container cloneNode: NO ];
		[ self _convertElementForMP4: videoElement atURL: URLString ];
	}
	
	
	DOMNode * widthNode = [[container attributes ] getNamedItem:@"width"];
	NSString * width = @"100%"; // default to 100% width
	if (widthNode != nil) {
		// width is already set explicitly, preserve that
		width = [widthNode nodeValue];
		if ( [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[width characterAtIndex:[width length] - 1]] ) {
			// add 'px' if existing width is just a number (ends with a digit)
			width = [width stringByAppendingString:@"px"];
		}
	}
	NSString * widthCSS = [NSString stringWithFormat:@"%@width:%@;", divCSS, width];
	
	DOMElement* CtFContainerElement = [document createElement: @"div"]; 
	[CtFContainerElement setAttribute: @"style" value: widthCSS];
	[CtFContainerElement setAttribute: @"class" value: @"clicktoflash-container"];
	[CtFContainerElement appendChild: videoElement];
	
	DOMElement* linkContainerElement = [self linkContainerElementForURL:URLString];
	if ( linkContainerElement != nil ) {
		[CtFContainerElement appendChild: linkContainerElement];		
	}
	
    // Just to be safe, since we are about to replace our containing element
    [[self retain] autorelease];
    
    // Replace self with element.
	[[container parentNode] replaceChild: CtFContainerElement oldChild: container];
	
    [[self plugin] setContainer:nil];
}



- (DOMElement*) linkContainerElementForURL: (NSString*) URLString {
	// Link container
	DOMDocument* document = [[[self plugin] container] ownerDocument];
	DOMElement* linkContainerElement = [document createElement: @"div"];
	[linkContainerElement setAttribute: @"style" value: divCSS];
	[linkContainerElement setAttribute: @"class" value: @"clicktoflash-linkcontainer"];
	NSString * linkCSS = @"margin:0px 0.5em;padding:0px;border:0px none;";
	
	// Link to the video's web page if we're not there already
	NSString * videoPageURLString = [self videoPageURLString];
	if ( videoPageURLString != nil && ![self isOnVideoPage] )  {
		DOMElement* videoPageLinkElement = [document createElement: @"a"];
		[videoPageLinkElement setAttribute: @"href" value: videoPageURLString];
		[videoPageLinkElement setAttribute: @"style" value: linkCSS];
		[videoPageLinkElement setAttribute: @"class" value: @"clicktoflash-link"];
		NSString * videoPageLinkText = [self videoPageLinkText];
		if (videoPageLinkText == nil) {
			NSString * formatString = CtFLocalizedString(@"Go to %@ Page", @"Text of link to the video page on SITENAME appearing beneath the video");
			videoPageLinkText = [NSString stringWithFormat:formatString, [self siteName]];
		}
		[videoPageLinkElement setTextContent: videoPageLinkText];

		[linkContainerElement appendChild: videoPageLinkElement];
	}
	
	// Link to Movie file download if possible
	NSString * videoDownloadURLString = [self videoDownloadURLString];
	if ( videoDownloadURLString == nil ) {
		videoDownloadURLString = URLString;
	}
	if ( videoDownloadURLString != nil ) {
		DOMElement* downloadLinkElement = [document createElement: @"a"];
		[downloadLinkElement setAttribute: @"href" value: [self videoURLString]];
		[downloadLinkElement setAttribute: @"style" value: linkCSS];
		[downloadLinkElement setAttribute: @"class" value: @"clicktoflash-link videodownload"];
		NSString * videoDownloadLinkText = [self videoDownloadLinkText];
		if (videoDownloadLinkText == nil) {
			videoDownloadLinkText = CtFLocalizedString(@"Download video file", @"Text of link to H.264 Download appearing beneath the video");
		}
		[downloadLinkElement setTextContent: videoDownloadLinkText];
		
		[linkContainerElement appendChild:downloadLinkElement];
	}
	
	// offer additional link for HD download if available
	if ( [self hasVideoHD] && ![self useVideoHD]) {
		NSString * extraLinkCSS = @"margin:0px;padding:0px;border:0px none;";
		DOMElement * extraDownloadLinkElement = [document createElement: @"a"];
		[extraDownloadLinkElement setAttribute: @"href" value: [self videoHDURLString]];
		[extraDownloadLinkElement setAttribute: @"style" value: extraLinkCSS];
		[extraDownloadLinkElement setAttribute: @"class" value: @"clicktoflash-link videodownload"];
		[extraDownloadLinkElement setTextContent: CtFLocalizedString(@"(Larger Size)", @"Text of link to additional Large Size H.264 Download appearing beneath the video after the standard link")];
		[linkContainerElement appendChild: extraDownloadLinkElement];
	}
	
	
	// Let subclasses add their own link (or delete ours)
	linkContainerElement = [self enhanceVideoDescriptionElement: linkContainerElement];

	return linkContainerElement;
}






#pragma mark -
#pragma mark Helpers

// Determine whether we want to use the video. Returns YES if a video is available and the relevant preference is set.
- (BOOL) useVideo {
    return [ self hasVideo ] 
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sUseYouTubeH264DefaultsKey ]; 
}


// Determine whether we want to use the video's HD version. Returns YES if the HD version is available and the relevant preferences are set.
- (BOOL) useVideoHD {
	return [ self hasVideoHD ] && [self hasVideo]
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sUseYouTubeH264DefaultsKey ] 
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sUseYouTubeHDH264DefaultsKey ];
}


// Return the URL to the video. When told to provide a HD version the SD version may be provided if no HD version exists.
- (NSString *) videoURLStringForHD: (BOOL) useHD {
	NSString * URLString;
	
	if (useHD && [self hasVideoHD]) {
		URLString = [ self videoHDURLString ];
	} else {
		URLString = [ self videoURLString ];
	}
	
	return URLString;
}



- (BOOL) isVideoElementAvailable
{
	if ( [[CTFUserDefaultsController standardUserDefaults] boolForKey:sDisableVideoElement] )
		return NO;
	
	/* <video> element compatibility was added to WebKit in or shortly before version 525. */
	
    NSBundle* webKitBundle;
    webKitBundle = [ NSBundle bundleForClass: [ WebView class ] ];
    if (webKitBundle) {
		/* ref. http://lists.apple.com/archives/webkitsdk-dev/2008/Nov/msg00003.html:
		 * CFBundleVersion is 5xxx.y on WebKits built to run on Leopard, 4xxx.y on Tiger.
		 * Unspecific builds (such as the ones in OmniWeb) get xxx.y numbers without a prefix.
		 */
		int normalizedVersion;
		float wkVersion = [ (NSString*) [ [ webKitBundle infoDictionary ] 
										 valueForKey: @"CFBundleVersion" ] 
						   floatValue ];
		if (wkVersion > 4000)
			normalizedVersion = (int)wkVersion % 1000;
		else
			normalizedVersion = wkVersion;
		
		// unfortunately, versions of WebKit above 531.5 also introduce a nasty
		// scrolling bug with video elements that cause them to be unviewable;
		// this bug was fixed shortly after being reported by @simX, so we can
		// now re-enable it for correct WebKit versions
		//
		// this bug actually only affected certain machines that had graphics
		// cards with a certain max texture size, and it was partially fixed, but
		// still didn't work for MacBooks with embedded graphics, and we could
		// detect that if we really wanted, but that would require importing
		// the OpenGL framework, which we probably shouldn't do, so we'll just
		// wholesale disable for certain WebKit versions
		//
		// https://bugs.webkit.org/show_bug.cgi?id=28705
		
		if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_5) {
			// Snowy Leopard; this bug doesn't seem to be exhibited here
			return (normalizedVersion >= 525);
		} else {
			// this bug was introduced in version 531.5, but has been fixed in
			// 532 and above
			
			return ((normalizedVersion >= 532) ||
					((normalizedVersion >= 525) && (normalizedVersion < 531.5))
					);
		}
	}
	return NO;
}




// Called when asynchronous lookups are finished. This will convert the element if it has been marked for conversion previously but the kind of conversion wasn't clear yet because of the pending lookups.
- (void) finishedLookups {
	if ([self requiresConversion]) {
		[self convertToContainer];
	}
}




#pragma mark -
#pragma mark Accessors

- (BOOL)autoPlay {
	BOOL result = autoPlay;
	result = result && [[CTFUserDefaultsController standardUserDefaults] objectForKey:sYouTubeAutoPlay];
	return result;
}

- (void)setAutoPlay:(BOOL)newAutoPlay {
	autoPlay = newAutoPlay;
}


- (BOOL)hasVideo {
	return hasVideo;
}

- (void)setHasVideo:(BOOL)newHasVideo {
	hasVideo = newHasVideo;
	[[self plugin] setNeedsDisplay: YES];
}


- (BOOL)hasVideoHD {
	return hasVideoHD;
}

- (void)setHasVideoHD:(BOOL)newHasVideoHD {
	hasVideoHD = newHasVideoHD;
	[[self plugin] setNeedsDisplay: YES];
}


- (enum CTFKVLookupStatus) lookupStatus {
	return lookupStatus;
}

- (void) setLookupStatus: (enum CTFKVLookupStatus) newLookupStatus {
	lookupStatus = newLookupStatus;
	if (lookupStatus == finished || lookupStatus == failed) {
		[self finishedLookups];
	}
	[[self plugin] setNeedsDisplay: YES];
}


- (BOOL)requiresConversion
{
	return requiresConversion;
}

- (void)setRequiresConversion:(BOOL)newRequiresConversion
{
	requiresConversion = newRequiresConversion;
}


- (NSURL *)previewURL {
	return previewURL;
}

- (void)setPreviewURL:(NSURL *)newPreviewURL {
	[newPreviewURL retain];
	[previewURL release];
	previewURL = newPreviewURL;
}



@end
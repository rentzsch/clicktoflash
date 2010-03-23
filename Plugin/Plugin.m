/*

The MIT License

Copyright (c) 2008-2009 ClickToFlash Developers

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

#import "Plugin.h"
#import "CTFUserDefaultsController.h"
#import "CTFPreferencesDictionary.h"

#import "MATrackingArea.h"
#import "CTFMenubarMenuController.h"
#import "CTFsIFRSupport.h"
#import "CTFUtilities.h"
#import "CTFWhitelist.h"
#import "NSBezierPath-RoundedRectangle.h"
#import "CTFGradient.h"
#import "SparkleManager.h"

#define LOGGING_ENABLED 0

#ifndef NSAppKitVersionNumber10_5
#define NSAppKitVersionNumber10_5 949
#endif

    // MIME types
static NSString *sFlashOldMIMEType = @"application/x-shockwave-flash";
static NSString *sFlashNewMIMEType = @"application/futuresplash";

    // CTFUserDefaultsController keys
static NSString *sUseYouTubeH264DefaultsKey = @"useYouTubeH264";
static NSString *sUseYouTubeHDH264DefaultsKey = @"useYouTubeHDH264";
static NSString *sAutoLoadInvisibleFlashViewsKey = @"autoLoadInvisibleViews";
static NSString *sPluginEnabled = @"pluginEnabled";
static NSString *sApplicationWhitelist = @"applicationWhitelist";
static NSString *sDrawGearImageOnlyOnMouseOverHiddenPref = @"drawGearImageOnlyOnMouseOver";
static NSString *sDisableVideoElement = @"disableVideoElement";
static NSString *sYouTubeAutoPlay = @"enableYouTubeAutoPlay";

	// Info.plist key for app developers
static NSString *sCTFOptOutKey = @"ClickToFlashOptOut";

BOOL usingMATrackingArea = NO;

@interface CTFClickToFlashPlugin (Internal)
- (void) _convertTypesForFlashContainer;
- (void) _convertTypesForFlashContainerAfterDelay;
- (void) _convertToMP4Container;
- (void) _convertToMP4ContainerAfterDelay;
- (void) _prepareForConversion;
- (void) _revertToOriginalOpacityAttributes;

- (void) _drawBackground;
- (BOOL) _isOptionPressed;
- (void) _checkMouseLocation;
- (void) _addTrackingAreaForCTF;
- (void) _removeTrackingAreaForCTF;

- (void) _loadContent: (NSNotification*) notification;
- (void) _loadContentForWindow: (NSNotification*) notification;

- (NSDictionary*) _flashVarDictionary: (NSString*) flashvarString;
- (NSDictionary*) _flashVarDictionaryFromYouTubePageHTML: (NSString*) youTubePageHTML;
- (void)_didRetrieveEmbeddedPlayerFlashVars:(NSDictionary *)flashVars;
- (void)_getEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:(NSString *)videoId;
- (NSString*) flashvarWithName: (NSString*) argName;
- (void) _checkForH264VideoVariants;
- (BOOL) _hasH264Version;
- (BOOL) _useH264Version;
- (BOOL) _hasHDH264Version;
- (BOOL) _useHDH264Version;
- (NSString *)launchedAppBundleIdentifier;
@end


#pragma mark -
#pragma mark Whitelist Utility Functions


@implementation CTFClickToFlashPlugin


#pragma mark -
#pragma mark Class Methods

+ (NSView *)plugInViewWithArguments:(NSDictionary *)arguments
{
    return [[[self alloc] initWithArguments:arguments] autorelease];
}


#pragma mark -
#pragma mark Initialization and Superclass Overrides


- (id) initWithArguments:(NSDictionary *)arguments
{
    self = [super init];
    if (self) {
		_hasH264Version = NO;
		_hasHDH264Version = NO;
		_contextMenuIsVisible = NO;
		_embeddedYouTubeView = NO;
		_youTubeAutoPlay = NO;
		_delayingTimer = nil;
		defaultWhitelist = [NSArray arrayWithObjects:	@"com.apple.frontrow",
														@"com.apple.dashboard.client",
														@"com.apple.ScreenSaver.Engine",
														@"com.hulu.HuluDesktop",
														@"com.riverfold.WiiTransfer",
														@"com.bitcartel.pandorajam",
														@"com.adobe.flexbuilder",
														@"com.Zattoo.prefs",
														@"fr.understudy.HuluPlayer",
														@"com.apple.iWeb",
														@"com.realmacsoftware.rapidweaverpro",
														@"com.realmacsoftware.littlesnapper",
							nil];
		
		SparkleManager *sharedSparkleManager = [SparkleManager sharedManager];
		NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
		NSString *pathToRelaunch = [sharedWorkspace absolutePathForAppBundleWithIdentifier:[self launchedAppBundleIdentifier]];
		[sharedSparkleManager setPathToRelaunch:pathToRelaunch];
        [sharedSparkleManager startAutomaticallyCheckingForUpdates];
        if (![[CTFUserDefaultsController standardUserDefaults] objectForKey:sAutoLoadInvisibleFlashViewsKey]) {
            //  Default to auto-loading invisible flash views.
            [[CTFUserDefaultsController standardUserDefaults] setBool:YES forKey:sAutoLoadInvisibleFlashViewsKey];
        }
		if (![[CTFUserDefaultsController standardUserDefaults] objectForKey:sPluginEnabled]) {
			// Default to enable the plugin
			[[CTFUserDefaultsController standardUserDefaults] setBool:YES forKey:sPluginEnabled];
		}
		[self setLaunchedAppBundleIdentifier:[self launchedAppBundleIdentifier]];
		
		[self setWebView:[[[arguments objectForKey:WebPlugInContainerKey] webFrame] webView]];
		
        [self setContainer:[arguments objectForKey:WebPlugInContainingElementKey]];
        
        [self _migrateWhitelist];
		[self _migratePrefsToExternalFile];
		[self _uniquePrefsFileWhitelist];
		[self _addApplicationWhitelistArrayToPrefsFile];
        
		
        // Get URL
        
        NSURL *base = [arguments objectForKey:WebPlugInBaseURLKey];
		[self setBaseURL:[base absoluteString]];
		[self setHost:[base host]];

		[self setAttributes:[arguments objectForKey:WebPlugInAttributesKey]];
		NSString *srcAttribute = [[self attributes] objectForKey:@"src"];
        
		if (srcAttribute) {
			[self setSrc:srcAttribute];
		} else {
			NSString *dataAttribute = [[self attributes] objectForKey:@"data"];
			if (dataAttribute) [self setSrc:dataAttribute];
		}
		
		
		// set tooltip
		
		if ([self src]) {
			int srcLength = [[self src] length];
			if ([[self src] length] > 200) {
				NSString *srcStart = [[self src] substringToIndex:150];
				NSString *srcEnd = [[self src] substringFromIndex:(srcLength-50)];
				NSString *shortenedSrc = [NSString stringWithFormat:@"%@…%@",srcStart,srcEnd];
				[self setToolTip:shortenedSrc];
			} else {
				[self setToolTip:[self src]];
			}
		}
		
        
        // Read in flashvars (needed to determine YouTube videos)
        
        NSString* flashvars = [[self attributes] objectForKey: @"flashvars" ];
        if( flashvars != nil )
            _flashVars = [ [ self _flashVarDictionary: flashvars ] retain ];
		
		// check whether it's from YouTube and get the video_id
		
        _fromYouTube = [[self host] isEqualToString:@"www.youtube.com"]
		|| [[self host] isEqualToString:@"www.youtube-nocookie.com"]
		|| ( flashvars != nil && [flashvars rangeOfString: @"www.youtube.com"].location != NSNotFound )
		|| ( flashvars != nil && [flashvars rangeOfString: @"www.youtube-nocookie.com"].location != NSNotFound )
		|| ([self src] != nil && [[self src] rangeOfString: @"youtube.com"].location != NSNotFound )
		|| ([self src] != nil && [[self src] rangeOfString: @"youtube-nocookie.com"].location != NSNotFound );
		
        if (_fromYouTube) {
			
			// Check wether autoplay is wanted
			if ([[CTFUserDefaultsController standardUserDefaults] objectForKey:sYouTubeAutoPlay]) {
				if ([[self host] isEqualToString:@"www.youtube.com"]
					|| [[self host] isEqualToString:@"www.youtube-nocookie.com"]) {
					_youTubeAutoPlay = YES;
				} else {
					_youTubeAutoPlay = [[[self _flashVarDictionary:[self src]] objectForKey:@"autoplay"] isEqualToString:@"1"];
				}
			} else {
				_youTubeAutoPlay = NO;
			}

			
			NSString *videoId = [ self flashvarWithName: @"video_id" ];
			if (videoId != nil) {
				[self setVideoId:videoId];
				
				// this retrieves new data from the internets, but the NSURLConnection
				// methods already spawn separate threads for the data retrieval,
				// so no need to spawn a separate thread
				[self _checkForH264VideoVariants];
			} else {
				// it's an embedded YouTube flash view; scrub the URL to
				// determine the video_id, then get the source of the YouTube
				// page to get the Flash vars
				
				_embeddedYouTubeView = YES;
				
				NSString *videoIdFromURL = nil;
				NSScanner *URLScanner = [[NSScanner alloc] initWithString:[self src]];
				[URLScanner scanUpToString:@"youtube.com/v/" intoString:nil];
				if ([URLScanner scanString:@"youtube.com/v/" intoString:nil]) {
					// URL is in required format, next characters are the id
					
					[URLScanner scanUpToString:@"&" intoString:&videoIdFromURL];
					if (videoIdFromURL) [self setVideoId:videoIdFromURL];
				} else {
					[URLScanner setScanLocation:0];
					[URLScanner scanUpToString:@"youtube-nocookie.com/v/" intoString:nil];
					if ([URLScanner scanString:@"youtube-nocookie.com/v/" intoString:nil]) {
						[URLScanner scanUpToString:@"&" intoString:&videoIdFromURL];
						if (videoIdFromURL) [self setVideoId:videoIdFromURL];
					}
				}
				[URLScanner release];
				
				if (videoIdFromURL) {
					// this block of code introduces a situation where we have to download
					// additional data from the internets, so we want to spin this off
					// to another thread to prevent blocking of the Safari user interface
					
					// this method is a stub for calling the real method on a different thread
					[self _getEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:videoIdFromURL];
				}
			}
		}
        
        _fromFlickr = [[self host] rangeOfString:@"flickr.com"].location != NSNotFound;
		
#if LOGGING_ENABLED
        NSLog( @"arguments = %@", arguments );
        NSLog( @"flashvars = %@", _flashVars );
#endif
		
		
		// check whether plugin is disabled, load all content as normal if so
		
		CTFUserDefaultsController *standardUserDefaults = [CTFUserDefaultsController standardUserDefaults];
		BOOL pluginEnabled = [standardUserDefaults boolForKey:sPluginEnabled ];
		NSString *hostAppBundleID = [[NSBundle mainBundle] bundleIdentifier];
		BOOL hostAppIsInDefaultWhitelist = [defaultWhitelist containsObject:hostAppBundleID];
		BOOL hostAppIsInUserWhitelist = [[standardUserDefaults arrayForKey:sApplicationWhitelist] containsObject:hostAppBundleID];
		BOOL hostAppWhitelistedInInfoPlist = NO;
		if ([[[NSBundle mainBundle] infoDictionary] objectForKey:sCTFOptOutKey]) hostAppWhitelistedInInfoPlist = YES;
		if ( (! pluginEnabled) || (hostAppIsInDefaultWhitelist || hostAppIsInUserWhitelist || hostAppWhitelistedInInfoPlist) ) {
            _isLoadingFromWhitelist = YES;
			[self _convertTypesForContainer];
			return self;
		}		
		
		
        // Set up main menus
        
		[ CTFMenubarMenuController sharedController ];	// trigger the menu items to be added
		
        
        // Check for sIFR
        
        if ([self _isSIFRText: arguments]) {
            _badgeText = NSLocalizedString(@"sIFR Flash", @"sIFR Flash badge text");
            
            if ([self _shouldAutoLoadSIFR]) {
				_isLoadingFromWhitelist = YES;
				[self _convertTypesForContainer];
				return self;
			}
            else if ([self _shouldDeSIFR]) {
				_isLoadingFromWhitelist = YES;
                [self performSelector:@selector(_disableSIFR) withObject:nil afterDelay:0];
				return self;
			}
        }
		
		if ( [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sAutoLoadInvisibleFlashViewsKey ]
			&& [ self isConsideredInvisible ] ) {
			// auto-loading is on and this view meets the size constraints
            _isLoadingFromWhitelist = YES;
			[self _convertTypesForContainer];
			return self;
		}
		
		
		BOOL loadFromWhiteList = [self _isHostWhitelisted];
		
		// Check the SWF src URL itself against the whitelist (allows embbeded videos from whitelisted sites to play, e.g. YouTube)
		
		if( !loadFromWhiteList )
		{
            if (srcAttribute) {
                NSURL* swfSrc = [NSURL URLWithString:srcAttribute];
                
                if( [self _isWhiteListedForHostString:[swfSrc host] ] )
                {
                    loadFromWhiteList = YES;
                }
            }
		}
		
        
        // Handle if this is loading from whitelist
        
        if(loadFromWhiteList && ![self _isOptionPressed]) {
            _isLoadingFromWhitelist = YES;
			
			if (_fromYouTube) {
				// we do this because checking for H.264 variants is handled
				// on another thread, so the results of that check may not have
				// been returned yet; if the user has this site on a whitelist
				// and the results haven't been returned, then the *Flash* will
				// load (ewwwwwww!) instead of the H.264, even if the user's
				// preferences are for the H.264
				
				// the _checkForH264VideoVariants method will manually fire
				// this timer if it finishes before the 3 seconds are up
				_delayingTimer = [NSTimer scheduledTimerWithTimeInterval:3
																  target:self
																selector:@selector(_convertTypesForContainer)
																userInfo:nil
																 repeats:NO];
			} else {
				[self _convertTypesForContainer];
			}
			
			return self;
        }
		
		
		// send a notification so that all flash objects can be tracked
		// we only want to track it if we don't auto-load it
		[[CTFMenubarMenuController sharedController] registerView: self];
        
        // Observe various things:
        
        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        
        // Observe for additions to the whitelist:
        [self _addWhitelistObserver];
		
		[center addObserver: self 
				   selector: @selector( _loadContent: ) 
					   name: kCTFLoadAllFlashViews 
					 object: nil ];
		
		[center addObserver: self 
				   selector: @selector( _loadContentForWindow: ) 
					   name: kCTFLoadFlashViewsForWindow 
					 object: nil ];
		
		[center addObserver: self 
				   selector: @selector( _loadInvisibleContentForWindow: ) 
					   name: kCTFLoadInvisibleFlashViewsForWindow
					 object: nil ];
		
		
		// if a Flash view has style attributes that make it transparent, the CtF
		// view will similarly be transparent; we want to make it temporarily
		// visible, and then restore the original attributes so that we don't
		// have any display issues once the Flash view is loaded
		
		// Should we apply this to the parent?
		// That seems to be problematic.
		
		// well, in my experience w/CSS, to get a layout to work a lot of the
		// time, you need to create parent objects and apply styles to parents,
		// so it seemed reasonable to check both self and parent for potential
		// problems with opacity
		
		NSMutableDictionary *originalOpacityDict = [NSMutableDictionary dictionary];
		NSString *opacityResetString = @"; opacity: 1.000 !important; -moz-opacity: 1 !important; filter: alpha(opacity=1) !important;";
		
		NSString *originalWmode = [[self container] getAttribute:@"wmode"];
		NSString *originalStyle = [[self container] getAttribute:@"style"];
		NSString *originalParentWmode = [(DOMElement *)[[self container] parentNode] getAttribute:@"wmode"];
		NSString *originalParentStyle = [(DOMElement *)[[self container] parentNode] getAttribute:@"style"];
		
		if (originalWmode != nil && [originalWmode length] > 0u && ![originalWmode isEqualToString:@"opaque"]) {
			[originalOpacityDict setObject:originalWmode forKey:@"self-wmode"];
			[[self container] setAttribute:@"wmode" value:@"opaque"];
		}
		
		if (originalStyle != nil && [originalStyle length] > 0u && ![originalStyle hasSuffix:opacityResetString]) {
			[originalOpacityDict setObject:originalStyle forKey:@"self-style"];
			[originalOpacityDict setObject:[originalStyle stringByAppendingString:opacityResetString] forKey:@"modified-self-style"];
			[[self container] setAttribute:@"style" value:[originalStyle stringByAppendingString:opacityResetString]];
		}
		
		if (originalParentWmode != nil && [originalParentWmode length] > 0u && ![originalParentWmode isEqualToString:@"opaque"]) {
			[originalOpacityDict setObject:originalParentWmode forKey:@"parent-wmode"];
			[(DOMElement *)[[self container] parentNode] setAttribute:@"wmode" value:@"opaque"];
		}
		
		if (originalParentStyle != nil && [originalParentStyle length] > 0u && ![originalParentStyle hasSuffix:opacityResetString]) {
			[originalOpacityDict setObject:originalParentStyle forKey:@"parent-style"];
			[originalOpacityDict setObject:[originalParentStyle stringByAppendingString:opacityResetString] forKey:@"modified-parent-style"];
			[(DOMElement *)[[self container] parentNode] setAttribute:@"style" value:[originalParentStyle stringByAppendingString:opacityResetString]];
		}
		
		[self setOriginalOpacityAttributes:originalOpacityDict];

		[self _checkMouseLocation];
        [self _addTrackingAreaForCTF];
    }

    return self;
}

- (void)webPlugInDestroy
{
	[self _removeTrackingAreaForCTF];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[self _abortAlert];        // to be on the safe side
	
	// notify that this ClickToFlash plugin is going away
	[[CTFMenubarMenuController sharedController] unregisterView:self];
	
	[self setContainer:nil];
	[self setHost:nil];
	[self setWebView:nil];
	[self setBaseURL:nil];
	[self setSrc:nil];
	[self setAttributes:nil];
	[self setOriginalOpacityAttributes:nil];
	
	[_flashVars release];
	_flashVars = nil;
	[_badgeText release];
	_badgeText = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	for (int i = 0; i < 2; ++i) {
		[connections[i] release];
		connections[i] = nil;
	}	
}

- (void) dealloc
{
	// Just in case...
	[self webPlugInDestroy];
	
#if LOGGING_ENABLED
	NSLog(@"ClickToFlash:\tdealloc");
#endif
	
    [super dealloc];
}

- (void) _migratePrefsToExternalFile
{
	NSArray *parasiticDefaultsNameArray = [NSArray arrayWithObjects:@"ClickToFlash_pluginEnabled",
										   @"ClickToFlash_useYouTubeH264",
										   @"ClickToFlash_autoLoadInvisibleViews",
										   @"ClickToFlash_sifrMode",
										   @"ClickToFlash_checkForUpdatesOnFirstLoad",
										   @"ClickToFlash_siteInfo",
										   nil];
	
	NSArray *externalDefaultsNameArray = [NSArray arrayWithObjects:@"pluginEnabled",
										  @"useYouTubeH264",
										  @"autoLoadInvisibleViews",
										  @"sifrMode",
										  @"checkForUpdatesOnFirstLoad",
										  @"siteInfo",
										  nil];
	
	NSMutableDictionary *externalFileDefaults = [[CTFUserDefaultsController standardUserDefaults] dictionaryRepresentation];

	[[NSUserDefaults standardUserDefaults] addSuiteNamed:@"com.github.rentzsch.clicktoflash"];
	unsigned int i;
	for (i = 0; i < [parasiticDefaultsNameArray count]; i++) {
		NSString *currentParasiticDefault = [parasiticDefaultsNameArray objectAtIndex:i];
		id prefValue = [[NSUserDefaults standardUserDefaults] objectForKey:currentParasiticDefault];
		if (prefValue) {
			NSString *externalPrefDefaultName = [externalDefaultsNameArray objectAtIndex:i];
			id existingExternalPref = [[CTFUserDefaultsController standardUserDefaults] objectForKey:externalPrefDefaultName];
			if (! existingExternalPref) {
				// don't overwrite existing external preferences
				[externalFileDefaults setObject:prefValue forKey:externalPrefDefaultName];
			} else {
				if ([currentParasiticDefault isEqualToString:@"ClickToFlash_siteInfo"]) {
					// merge the arrays of whitelisted sites, in case they're not identical
					
					NSMutableArray *combinedWhitelist = [NSMutableArray arrayWithArray:prefValue];
					[combinedWhitelist addObjectsFromArray:existingExternalPref];
					[externalFileDefaults setObject:combinedWhitelist forKey:externalPrefDefaultName];
					
					// because people named Kevin Ballard messed up their preferences file and somehow
					// managed to retain ClickToFlash_siteInfo in their com.github plist file
					[externalFileDefaults removeObjectForKey:currentParasiticDefault];
				}
			}
			// eliminate the parasitic default, regardless of whether we transferred them or not
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:currentParasiticDefault];
		}
	}
	[[NSUserDefaults standardUserDefaults] removeSuiteNamed:@"com.github.rentzsch.clicktoflash"];
}

- (void) _uniquePrefsFileWhitelist
{
	NSArray *siteInfoArray = [[CTFUserDefaultsController standardUserDefaults] arrayForKey:@"siteInfo"];
	NSSet *siteInfoSet = [NSSet setWithArray:siteInfoArray];
	
	[[CTFUserDefaultsController standardUserDefaults] setValue:[siteInfoSet allObjects] forKeyPath:@"values.siteInfo"];
}


- (void) _addApplicationWhitelistArrayToPrefsFile
{
	CTFUserDefaultsController *standardUserDefaults = [CTFUserDefaultsController standardUserDefaults];
	NSArray *applicationWhitelist = [standardUserDefaults arrayForKey:sApplicationWhitelist];
	if (! applicationWhitelist) {
		// add an empty array to the plist file so people know exactly where to
		// whitelist apps
		
		[standardUserDefaults setObject:[NSArray array] forKey:sApplicationWhitelist];
	}
}

- (void) drawRect:(NSRect)rect
{
	if(!_isLoadingFromWhitelist)
		[self _drawBackground];
}

- (BOOL) _gearVisible
{
	NSRect bounds = [ self bounds ];
	return NSWidth( bounds ) > 32 && NSHeight( bounds ) > 32;
}

- (BOOL) mouseEventIsWithinGearIconBorders:(NSEvent *)event
{
	float margin = 5.0;
	float gearImageHeight = 16.0;
	float gearImageWidth = 16.0;
	
	BOOL xCoordWithinGearImage = NO;
	BOOL yCoordWithinGearImage = NO;
	
	// if the view is 32 pixels or smaller in either direction,
	// the gear image is not drawn, so we shouldn't pop-up the contextual
	// menu on a single-click either
	if ( [ self _gearVisible ] ) {
        float viewHeight = NSHeight( [ self bounds ] );
		NSPoint mouseLocation = [event locationInWindow];
		NSPoint localMouseLocation = [self convertPoint:mouseLocation fromView:nil];
		
		xCoordWithinGearImage = ( (localMouseLocation.x >= (0 + margin)) &&
								 (localMouseLocation.x <= (0 + margin + gearImageWidth)) );
		
		yCoordWithinGearImage = ( (localMouseLocation.y >= (viewHeight - margin - gearImageHeight)) &&
								 (localMouseLocation.y <= (viewHeight - margin)) );
	}
	
	return (xCoordWithinGearImage && yCoordWithinGearImage);
}

- (void) mouseDown:(NSEvent *)event
{
	if ([self mouseEventIsWithinGearIconBorders:event]) {
		_contextMenuIsVisible = YES;
		[NSMenu popUpContextMenu:[self menuForEvent:event] withEvent:event forView:self];
	} else {
		mouseIsDown = YES;
		mouseInside = YES;
		[self setNeedsDisplay:YES];

		// Track the mouse so that we can undo our pressed-in look if the user drags the mouse outside the view, and reinstate it if the user drags it back in.
        //[self _addTrackingAreaForCTF];
            // Now that we track the mouse for mouse-over when the mouse is up 
            // for drawing the gear only on mouse-over, we don't need to add it here.
	}
}

- (void) mouseEntered:(NSEvent *)event
{
    mouseInside = YES;
    [self setNeedsDisplay:YES];
}
- (void) mouseExited:(NSEvent *)event
{
    mouseInside = NO;
    [self setNeedsDisplay:YES];
}

- (void) mouseUp:(NSEvent *)event
{
    mouseIsDown = NO;
    // Display immediately because we don't want to end up drawing after we've swapped in the Flash movie.
    [self display];
    
    // We're done tracking.
    //[self _removeTrackingAreaForCTF];
        // Now that we track the mouse for mouse-over when the mouse is up 
        // for drawing the gear only on mouse-over, we don't remove it here.
    
    if (mouseInside && (! _contextMenuIsVisible) ) {
        if ([self _isOptionPressed] && ![self _isHostWhitelisted]) {
            [self _askToAddCurrentSiteToWhitelist];
        } else {
            [self _convertTypesForContainer];
        }
    } else {
		_contextMenuIsVisible = NO;
	}
}

- (BOOL) _isOptionPressed
{
    BOOL isOptionPressed = (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0);
    return isOptionPressed;
}

- (BOOL) isConsideredInvisible
{
	int height = (int)([[self webView] frame].size.height);
	int width = (int)([[self webView] frame].size.width);
	
	if ( (height <= maxInvisibleDimension) && (width <= maxInvisibleDimension) )
	{
		return YES;
	}
	
	NSDictionary *attributes = [self attributes];
	if ( attributes != nil )
	{
		NSString *heightObject = [attributes objectForKey:@"height"];
		NSString *widthObject = [attributes objectForKey:@"width"];
		if ( heightObject != nil && widthObject != nil )
		{
			height = [heightObject intValue];
			width = [widthObject intValue];
			if ( (height <= maxInvisibleDimension) && (width <= maxInvisibleDimension) )
			{
				return YES;
			}
		}
	}
	
	return NO;
}

#pragma mark -
#pragma mark Contextual menu

- (void) setUpExtraMenuItems
{
	if( [ self menu ] ) {
		// if the menu is not set up, then the menuForEvent: method will call
		// this method when the menu is requested
		
		if (_fromYouTube) {
			if ([[self menu] indexOfItemWithTarget:self andAction:@selector(loadYouTubePage:)] == -1) {
				if (_embeddedYouTubeView) {
					[[self menu] insertItem:[NSMenuItem separatorItem] atIndex:2];
					[[self menu] insertItemWithTitle: NSLocalizedString ( @"Load YouTube.com page for this video", "Load YouTube page menu item" )
											  action: @selector (loadYouTubePage: ) keyEquivalent: @"" atIndex: 3];
					[[[self menu] itemAtIndex: 3] setTarget: self];
				}
			}
		}
			
		if (_fromYouTube && [self _hasH264Version]) {
			if ([[self menu] indexOfItemWithTarget:self andAction:@selector(loadH264:)] == -1) {
				int QTMenuItemIndex, downloadMenuItemIndex;
				if (! _embeddedYouTubeView) {
					[[self menu] insertItem:[NSMenuItem separatorItem] atIndex:2];
					
					QTMenuItemIndex = 4;
					downloadMenuItemIndex = 5;
				} else {
					QTMenuItemIndex = 5;
					downloadMenuItemIndex = 6;
				}
				
				[[self menu] insertItemWithTitle: NSLocalizedString( @"Load H.264", "Load H.264 context menu item" )
										  action: @selector( loadH264: ) keyEquivalent: @"" atIndex: 1];
				[[self menu] insertItemWithTitle: NSLocalizedString( @"Play Fullscreen in QuickTime Player", "Open Fullscreen in QT Player menu item" )
										  action: @selector( openFullscreenInQTPlayer: ) keyEquivalent: @"" atIndex: QTMenuItemIndex];
				[[self menu] insertItemWithTitle: NSLocalizedString( @"Download H.264", "Download H.264 menu item" )
										  action: @selector( downloadH264: ) keyEquivalent: @"" atIndex: downloadMenuItemIndex];
				[[[self menu] itemAtIndex: 1] setTarget: self];
				[[[self menu] itemAtIndex: QTMenuItemIndex] setTarget: self];
				[[[self menu] itemAtIndex: downloadMenuItemIndex] setTarget: self];
			}
		}
	}
	
}

- (NSMenu*) menuForEvent: (NSEvent*) event
{
    // Set up contextual menu
    
    if( ![ self menu ] ) {
        if (![NSBundle loadNibNamed:@"ContextualMenu" owner:self]) {
            NSLog(@"Could not load contextual menu plugin");
        }
        else {
			[self setUpExtraMenuItems];
        }
    }
    
    return [self menu];
}

- (BOOL) validateMenuItem: (NSMenuItem *)menuItem
{
    BOOL enabled = YES;
    SEL action = [menuItem action];
    if (action == @selector(addToWhitelist:))
    {
		if ([self host]) {
			NSString* title = [NSString stringWithFormat:
							   NSLocalizedString(@"Add %@ to Whitelist", @"Add <sitename> to Whitelist menu title"), 
							   [self host]];
			[menuItem setTitle: title];
		} else {
			// this case happens sometimes if the base URL is "about:blank",
			// so there's no base URL to use for the whitelist, so just disable
			// the menu item
			enabled = NO;
		}
       
        if ([self _isHostWhitelisted])
            enabled = NO;
    }
    
    return enabled;
}

#pragma mark -
#pragma mark Loading

- (IBAction)loadFlash:(id)sender;
{
    [self _convertTypesForFlashContainer];
}

- (IBAction)loadH264:(id)sender;
{
    [self _convertToMP4Container];
}

- (IBAction)loadAllOnPage:(id)sender
{
    [[CTFMenubarMenuController sharedController] loadFlashForWindow: [self window]];
}

- (void) _loadContent: (NSNotification*) notification
{
    [self _convertTypesForContainer];
}

- (void) _loadContentForWindow: (NSNotification*) notification
{
	if( [ notification object ] == [ self window ] )
		[ self _convertTypesForContainer ];
}

- (void) _loadInvisibleContentForWindow: (NSNotification*) notification
{
	if( [ notification object ] == [ self window ] && [ self isConsideredInvisible ] ) {
		[ self _convertTypesForContainer ];
	}
}

#pragma mark -
#pragma mark Drawing

- (NSString*) badgeLabelText
{
	if( [ self _useHDH264Version ] && [self _hasHDH264Version]) {
		return NSLocalizedString( @"HD H.264", @"HD H.264 badge text" );
	} else if( [ self _useH264Version ] && [self _hasH264Version]) {
		if (_receivedAllResponses) {
			return NSLocalizedString( @"H.264", @"H.264 badge text" );
		} else {
			return NSLocalizedString( @"H.264…", @"H.264 badge waiting text" );
		}
    } else if( _fromYouTube && _videoId) {
		// we check the video ID too because if it's a flash ad on YouTube.com,
		// we don't want to identify it as an actual YouTube video -- but if
		// the flash object actually has a video ID parameter, it means its
		// a bona fide YouTube video
		
		if (_receivedAllResponses) {
			return NSLocalizedString( @"YouTube", @"YouTube badge text" );
		} else {
			return NSLocalizedString( @"YouTube…", @"YouTube badge waiting text" );
		}
    } else if( _badgeText ) {
        return _badgeText;
    } else {
        return NSLocalizedString( @"Flash", @"Flash badge text" );
	}
}

- (void) _drawBadgeWithPressed: (BOOL) pressed
{
	// What and how are we going to draw?
	
	const float kFrameXInset = 10;
	const float kFrameYInset =  4;
	const float kMinMargin   = 11;
	const float kMinHeight   =  6;
	
	NSString* str = [ self badgeLabelText ];
	
	NSShadow *superAwesomeShadow = [[NSShadow alloc] init];
	[superAwesomeShadow setShadowOffset:NSMakeSize(2.0, -2.0)];
	[superAwesomeShadow setShadowColor:[NSColor whiteColor]];
	[superAwesomeShadow autorelease];
	NSDictionary* attrs = [ NSDictionary dictionaryWithObjectsAndKeys: 
						   [ NSFont boldSystemFontOfSize: 20 ], NSFontAttributeName,
						   [ NSNumber numberWithInt: -1 ], NSKernAttributeName,
						   [ NSColor blackColor ], NSForegroundColorAttributeName,
						   superAwesomeShadow, NSShadowAttributeName,
						   nil ];
	
	// Set up for drawing.
	
	NSRect bounds = [ self bounds ];
	
	// How large would this text be?
	
	NSSize strSize = [ str sizeWithAttributes: attrs ];
	
	float w = strSize.width  + kFrameXInset * 2;
	float h = strSize.height + kFrameYInset * 2;
	
	// Compute a scale factor based on the view's size.
	
	float maxW = NSWidth( bounds ) - kMinMargin;
	// the 9/10 factor here is to account for the 60% vertical top-biasing
	float maxH = _fromFlickr ? NSHeight( bounds )*9/10 - kMinMargin : NSHeight( bounds ) - kMinMargin;
	float minW = kMinHeight * w / h;
	
	BOOL rotate = NO;
	if( maxW <= minW )	// too narrow in width, so rotate it
		rotate = YES;
	
	if( rotate ) {		// swap the dimensions to scale into
		float temp = maxW;
		maxW = maxH;
		maxH = temp;
	}
	
	if( maxH <= kMinHeight ) {
		// Too short in height for full margin.
		
		// Draw at the smallest size, with less margin,
		// unless even that would get clipped off.
		
		if( maxH + kMinMargin < kMinHeight )
			return;
        
		maxH = kMinHeight;
	}
	
	float scaleFactor = 1.0;
	
	if( maxW < w )
		scaleFactor = maxW / w;
    
	if( maxH < h && maxH / h < scaleFactor )
		scaleFactor = maxH / h;
	
	// Apply the scale, and a transform so the result is centered in the view.
	
	[ NSGraphicsContext saveGraphicsState ];
    
	NSAffineTransform* xform = [ NSAffineTransform transform ];
	// vertical top-bias by 60% here
    if (_fromFlickr) {
        [ xform translateXBy: NSWidth( bounds ) / 2 yBy: NSHeight( bounds ) / 10 * 6 ];
    } else {
        [ xform translateXBy: NSWidth( bounds ) / 2 yBy: NSHeight( bounds ) / 2 ];
    }
	[ xform scaleBy: scaleFactor ];
	if( rotate )
		[ xform rotateByDegrees: 90 ];
	[ xform concat ];
	
    CGContextRef context = [ [ NSGraphicsContext currentContext ] graphicsPort ];
    
    CGContextSetAlpha( context, pressed ? 0.45 : 0.30 );
    CGContextBeginTransparencyLayer( context, nil );
	
	// Draw everything at full size, centered on the origin.
	
	NSPoint loc = { -strSize.width / 2, -strSize.height / 2 };
	NSRect borderRect = NSMakeRect( loc.x - kFrameXInset, loc.y - kFrameYInset, w, h );
	
    NSBezierPath* fillPath = bezierPathWithRoundedRectCornerRadius( borderRect, 4 );
    [ [ NSColor colorWithCalibratedWhite: 1.0 alpha: 0.45 ] set ];
    [ fillPath fill ];
    
    NSBezierPath* darkBorderPath = bezierPathWithRoundedRectCornerRadius( borderRect, 4 );
    [[NSColor blackColor] set];
    [ darkBorderPath setLineWidth: 3 ];
    [ darkBorderPath stroke ];
    
    NSBezierPath* lightBorderPath = bezierPathWithRoundedRectCornerRadius( NSInsetRect(borderRect, -2, -2), 6 );
    [ [ NSColor colorWithCalibratedWhite: 1.0 alpha: 0.45 ] set ];
    [ lightBorderPath setLineWidth: 2 ];
    [ lightBorderPath stroke ];
    
    [ str drawAtPoint: loc withAttributes: attrs ];
	
	// Now restore the graphics state:
	
    CGContextEndTransparencyLayer( context );
    
    [ NSGraphicsContext restoreGraphicsState ];
}

- (void) _drawGearIcon
{
    // add the gear for the contextual menu, but only if the view is
    // greater than a certain size
        
    if ([self _gearVisible]) {
        NSRect bounds = [ self bounds ];

        float margin = 5.0;
        NSImage *gearImage = [NSImage imageNamed:@"NSActionTemplate"];
        // On systems older than 10.5 we need to supply our own image.
        if (gearImage == nil)
        {
            NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"NSActionTemplate" ofType:@"png"];
            gearImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
        }

        if( gearImage ) {
            CGContextRef context = [ [ NSGraphicsContext currentContext ] graphicsPort ];
            
            CGContextSetAlpha( context, 0.25 );
            CGContextBeginTransparencyLayer( context, nil );
            
            NSPoint gearImageCenter = NSMakePoint(NSMinX( bounds ) + ( margin + [gearImage size].width/2 ),
                                                  NSMaxY( bounds ) - ( margin + [gearImage size].height/2 ));
            
            id gradient = [NSClassFromString(@"NSGradient") alloc];
            if (gradient != nil)
            {
                NSColor *startingColor = [NSColor colorWithDeviceWhite:1.0 alpha:1.0];
                NSColor *endingColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.0];
                
                gradient = [gradient initWithStartingColor:startingColor endingColor:endingColor];
                
                // draw gradient behind gear so that it's visible even on dark backgrounds
                [gradient drawFromCenter:gearImageCenter
                                  radius:0.0
                                toCenter:gearImageCenter
                                  radius:[gearImage size].height/2*1.5
                                 options:0];
                
                [gradient release];
            }
            
            // draw the gear image
            [gearImage drawAtPoint:NSMakePoint(gearImageCenter.x - [gearImage size].width/2, 
                                               gearImageCenter.y - [gearImage size].height/2)
                          fromRect:NSZeroRect
                         operation:NSCompositeSourceOver
                          fraction:1.0];

            CGContextEndTransparencyLayer( context );
       }
    }
}

- (void) _drawBackground
{
    NSRect selfBounds = [self bounds];

    NSRect fillRect   = NSInsetRect(selfBounds, 1.0, 1.0);
    NSRect strokeRect = selfBounds;

    NSColor *startingColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.15];
    NSColor *endingColor = [NSColor colorWithDeviceWhite:0.0 alpha:0.15];

    // When the mouse is up or outside the view, we want a convex look, so we draw the gradient downward (90+180=270 degrees).
    // When the mouse is down and inside the view, we want a concave look, so we draw the gradient upward (90 degrees).
    id gradient = [NSClassFromString(@"NSGradient") alloc];
    if (gradient != nil)
    {
        gradient = [gradient initWithStartingColor:startingColor endingColor:endingColor];

        [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:fillRect] angle:90.0 + ((mouseIsDown && mouseInside) ? 0.0 : 180.0)];

        [gradient release];
    }
    else
    {
		//tweak the opacity of the endingColor for compatibility with CTGradient
		endingColor = [NSColor colorWithDeviceWhite:0.0 alpha:0.00];
		
		gradient = [CTFGradient gradientWithBeginningColor:startingColor
											  endingColor:endingColor];
		
		//angle is reversed compared to NSGradient
		[gradient fillBezierPath:[NSBezierPath bezierPathWithRect:fillRect] angle:-90.0 - ((mouseIsDown && mouseInside) ? 0.0 : 180.0)];
		
		//CTGradient instances are returned autoreleased - no need for explicit release here
    }

    // Draw stroke
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.50] set];
    [NSBezierPath setDefaultLineWidth:2.0];
    [NSBezierPath setDefaultLineCapStyle:NSSquareLineCapStyle];
    [[NSBezierPath bezierPathWithRect:strokeRect] stroke];

    // Draw label
    [ self _drawBadgeWithPressed: mouseIsDown && mouseInside ];
    
    // Draw the gear icon
	if ([[CTFUserDefaultsController standardUserDefaults] boolForKey:sDrawGearImageOnlyOnMouseOverHiddenPref]) {
		if( mouseInside && !mouseIsDown )
			[ self _drawGearIcon ];
	} else {
		[ self _drawGearIcon ];
	}
}

- (void) _checkMouseLocation
{
	NSPoint mouseLoc = [NSEvent mouseLocation];
	
	BOOL nowInside = NSPointInRect(mouseLoc, [_webView bounds]);
	if (nowInside) {
		mouseInside = YES;
	} else {
		mouseInside = NO;
	}
}

- (void) _addTrackingAreaForCTF
{
    if (trackingArea)
        return;
    
    trackingArea = [NSClassFromString(@"NSTrackingArea") alloc];
    if (trackingArea != nil)
    {
        [(MATrackingArea *)trackingArea initWithRect:[self bounds]
                                             options:MATrackingMouseEnteredAndExited | MATrackingActiveInKeyWindow | MATrackingEnabledDuringMouseDrag | MATrackingInVisibleRect
                                               owner:self
                                            userInfo:nil];
        [self addTrackingArea:trackingArea];
    }
    else
    {
        trackingArea = [NSClassFromString(@"MATrackingArea") alloc];
        [(MATrackingArea *)trackingArea initWithRect:[self bounds]
                                             options:MATrackingMouseEnteredAndExited | MATrackingActiveInKeyWindow | MATrackingEnabledDuringMouseDrag | MATrackingInVisibleRect
                                               owner:self
                                            userInfo:nil];
        [MATrackingArea addTrackingArea:trackingArea toView:self];
        usingMATrackingArea = YES;
    }
}

- (void) _removeTrackingAreaForCTF
{
    if (trackingArea)
    {
        if (usingMATrackingArea)
        {
            [MATrackingArea removeTrackingArea:trackingArea fromView:self];
        }
        else
        {
            [self removeTrackingArea:trackingArea];
        }
        [trackingArea release];
        trackingArea = nil;
    }
}


#pragma mark -
#pragma mark WebScripting Protocol

- (id)objectForWebScript {
    //NSLog(@"objectForWebScript => %@", self);
	return self;
}

+ (NSString *)webScriptNameForSelector:(SEL)aSelector {
	// javascript may call GetVariable("$version") on us
    
    NSString *result = nil;
    
	if (aSelector == @selector(flashGetVariable:))
		result = @"GetVariable";
    
    //NSLog(@"webScriptNameForSelector:%@ => %@", NSStringFromSelector(aSelector), result);
    return result;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
    BOOL result = YES;
    
    if (aSelector == @selector(flashGetVariable:))
		result = NO;
    
    //NSLog(@"isSelectorExcludedFromWebScript:%@ => %d", NSStringFromSelector(aSelector), result);
    return result;
}

- (id)flashGetVariable:(id)flashVar {
	static NSString *sFlashVersion = nil;
    static NSString *sClickToFlashVersion = nil;
    
    //NSLog(@"flashVar: %p %@", flashVar, flashVar);
	
	if (flashVar && [flashVar isKindOfClass:[NSString class]]) {
		if ([flashVar isEqualToString:@"$version"]) {
			if (sFlashVersion == nil) {
				NSBundle *bundle = [NSBundle bundleForClass:[self class]];
				if (bundle) {
					id version = [bundle objectForInfoDictionaryKey:@"CTFFlashVariableVersion"];
					if (version && [version isKindOfClass:[NSString class]]) {
						sFlashVersion = [(NSString *)version copy];
					}
				}
			}
			
			return sFlashVersion;
		} else if ([flashVar isEqualToString:@"$ClickToFlashVersion"]) {
            if (sClickToFlashVersion == nil) {
				NSBundle *bundle = [NSBundle bundleForClass:[self class]];
				if (bundle) {
					id version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
					if (version && [version isKindOfClass:[NSString class]]) {
						sClickToFlashVersion = [(NSString *)version copy];
					}
				}
			}
			
			return sClickToFlashVersion;
        } else {
			return [self flashvarWithName:flashVar];
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark YouTube H.264 support


- (NSDictionary*) _flashVarDictionary: (NSString*) flashvarString
{
    NSMutableDictionary* flashVarsDictionary = [ NSMutableDictionary dictionary ];
    
    NSArray* args = [ flashvarString componentsSeparatedByString: @"&" ];
    
    CTFForEachObject( NSString, oneArg, args ) {
        NSRange sepRange = [ oneArg rangeOfString: @"=" ];
        if( sepRange.location != NSNotFound ) {
            NSString* key = [ oneArg substringToIndex: sepRange.location ];
            NSString* val = [ oneArg substringFromIndex: NSMaxRange( sepRange ) ];
            
            [ flashVarsDictionary setObject: val forKey: key ];
        }
    }
    
    return flashVarsDictionary;
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

- (NSString*) flashvarWithName: (NSString*) argName
{
    return [[[ _flashVars objectForKey: argName ] retain] autorelease];
}

/*- (NSString*) _videoId
{
    return [ self flashvarWithName: @"video_id" ];
}*/

- (NSString*) _videoHash
{
    return [ self flashvarWithName: @"t" ];
}

- (void)_checkForH264VideoVariants
{
	NSString *video_id = [self videoId];
	NSString *video_hash = [self _videoHash];
	
	if (video_id && video_hash) {
		// The standard H264 stream is format 18. HD is 22
		unsigned formats[] = { 18, 22 };

		for (int i = 0; i < 2; ++i) {
			NSMutableURLRequest *request;
			
			request = [NSMutableURLRequest requestWithURL:
					   [NSURL URLWithString:
						[NSString stringWithFormat:
						 @"http://www.youtube.com/get_video?fmt=%u&video_id=%@&t=%@",
						 formats[i], video_id, video_hash]]];
			
			[request setHTTPMethod:@"HEAD"];
			
			connections[i] = [[NSURLConnection alloc] initWithRequest:request
															 delegate:self];
		}

		expectedResponses = 2;
		_receivedAllResponses = NO;
	}
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
	
	if (didReceiveAllResponses) _receivedAllResponses = YES;
	
	[self setUpExtraMenuItems];
	[self setNeedsDisplay:YES];
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSHTTPURLResponse *)response
{
	int statusCode = [response statusCode];
	
	if (statusCode == 200) {
		if (connection == connections[0])
			[self _setHasH264Version:YES];
		else 
			[self _setHasHDH264Version:YES];
	}
	
	[self finishedWithConnection:connection];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
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

- (BOOL) _useHDH264Version
{
	return [ self _hasHDH264Version ]
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sUseYouTubeH264DefaultsKey ] 
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sUseYouTubeHDH264DefaultsKey ]
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sPluginEnabled ];
}

- (BOOL) _useH264Version
{
    return [ self _hasH264Version ] 
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sUseYouTubeH264DefaultsKey ] 
	&& [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sPluginEnabled ];
}

- (BOOL)_isVideoElementAvailable
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

- (NSString*) _h264VersionUrl
{
    NSString* video_id = [self videoId];
    NSString* video_hash = [ self _videoHash ];
    
	NSString* src;
	if ([ self _hasHDH264Version ]) {
		src = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=22&video_id=%@&t=%@",
			   video_id, video_hash ];
	} else {
		src = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=18&video_id=%@&t=%@",
			   video_id, video_hash ];
	}
	return src;
}

- (void) _convertElementForMP4: (DOMElement*) element
{
	// some tags (OBJECT) want a data attribute, and some want a src attribute
	// for some reason, though, some cloned elements are not reporting themselves
	// as OBJECT tags, even though they are; more investigation on this is needed,
	// but for now, setting both the data and the src attribute corrects the problem
	// (see bug #294)
	
	[ element setAttribute: @"data" value: [ self _h264VersionUrl ]];
	[ element setAttribute: @"src" value: [ self _h264VersionUrl ]];
	
    [ element setAttribute: @"type" value: @"video/mp4" ];
    [ element setAttribute: @"scale" value: @"aspect" ];
    if (_youTubeAutoPlay) {
		[ element setAttribute: @"autoplay" value: @"true" ];
	} else {
		[ element setAttribute: @"autoplay" value: @"false" ];
	}
    [ element setAttribute: @"cache" value: @"false" ];
	
    if( ! [ element hasAttribute: @"width" ] )
        [ element setAttribute: @"width" value: @"640" ];
	
    if( ! [ element hasAttribute: @"height" ] )
		[ element setAttribute: @"height" value: @"500" ];
	
    [ element setAttribute: @"flashvars" value: nil ];
}

- (void) _convertElementForVideoElement: (DOMElement*) element
{
    [ element setAttribute: @"src" value: [ self _h264VersionUrl ] ];
	[ element setAttribute: @"autobuffer" value:@"autobuffer"];
	if (_youTubeAutoPlay) {
		[ element setAttribute: @"autoplay" value:@"autoplay" ];
	} else {
		if ( [element hasAttribute:@"autoplay"] )
			[ element removeAttribute:@"autoplay" ];
	}
	[ element setAttribute: @"controls" value:@"controls"];
	
	DOMElement* container = [self container];
	
	[ element setAttribute:@"width" value:[ NSString stringWithFormat:@"%dpx", [ container clientWidth ]]];
	[ element setAttribute:@"height" value:[ NSString stringWithFormat:@"%dpx", [ container clientHeight ]]];
}

- (void) _convertToMP4Container
{
	[self _revertToOriginalOpacityAttributes];
	
	// Delay this until the end of the event loop, because it may cause self to be deallocated
	[self _prepareForConversion];
	[self performSelector:@selector(_convertToMP4ContainerAfterDelay) withObject:nil afterDelay:0.0];
}

- (void) _convertToMP4ContainerAfterDelay
{
	DOMElement* newElement;
	if ([ self _isVideoElementAvailable ]) {
		newElement = [[[self container] ownerDocument] createElement:@"video"];
		[ self _convertElementForVideoElement: newElement ];
    } else {
		newElement = (DOMElement*) [ [self container] cloneNode: NO ];
		[ self _convertElementForMP4:newElement ];
	}
    // Just to be safe, since we are about to replace our containing element
    [[self retain] autorelease];
    
    // Replace self with element.
    [[[self container] parentNode] replaceChild:newElement oldChild:[self container]];
    [self setContainer:nil];
}

- (NSString *)launchedAppBundleIdentifier
{
	NSString *appBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	
	if ([appBundleIdentifier isEqualToString:@"com.apple.Safari"]) {
		// additional tests need to be performed, because this can indicate
		// either WebKit *or* Safari; according to @bdash on Twitter, we need
		// to check whether the framework bundle that we're using is 
		// contained within WebKit.app or not
		
		// however, the user may have renamed the bundle, so we have to get
		// its path, then get its bundle identifier
		
		NSString *privateFrameworksPath = [[NSBundle bundleForClass:[WebView class]] privateFrameworksPath];
		
		NSScanner *pathScanner = [[NSScanner alloc] initWithString:privateFrameworksPath];
		NSString *pathString = nil;
		[pathScanner scanUpToString:@".app" intoString:&pathString];
		NSBundle *testBundle = [[NSBundle alloc] initWithPath:[pathString stringByAppendingPathExtension:@"app"]];
		NSString *testBundleIdentifier = [testBundle bundleIdentifier];
		[testBundle release];
		[pathScanner release];
		
		
		// Safari uses the framework inside /System/Library/Frameworks/ , and
		// since there's no ".app" extension in that path, the resulting
		// bundle identifier will be nil; however, if it's WebKit, there *will*
		// be a ".app" in the frameworks path, and we'll get a valid bundle
		// identifier to launch with
		
		if (testBundleIdentifier != nil) appBundleIdentifier = testBundleIdentifier;
	}
	
	return appBundleIdentifier;
}

- (IBAction)downloadH264:(id)sender
{
	NSString* video_id = [self videoId];
    NSString* video_hash = [ self _videoHash ];
    
	NSString *src;
	if ([[CTFUserDefaultsController standardUserDefaults] boolForKey:sUseYouTubeHDH264DefaultsKey] && [self _hasHDH264Version]) {
		src = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=22&video_id=%@&t=%@",
			   video_id, video_hash ];
	} else {
		src = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=18&video_id=%@&t=%@",
			   video_id, video_hash ];
	}
	
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL URLWithString:src]]
					withAppBundleIdentifier:[self launchedAppBundleIdentifier]
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:[NSAppleEventDescriptor nullDescriptor]
						  launchIdentifiers:nil];
}

- (IBAction)loadYouTubePage:(id)sender
{
	NSString* YouTubePageURL = [ NSString stringWithFormat: @"http://www.youtube.com/watch?v=%@", [self videoId] ];
	
    [_webView setMainFrameURL:YouTubePageURL];
}

- (IBAction)openFullscreenInQTPlayer:(id)sender;
{
	NSString* video_id = [self videoId];
    NSString* video_hash = [ self _videoHash ];
    
	NSString *src;
	if ([[CTFUserDefaultsController standardUserDefaults] boolForKey:sUseYouTubeHDH264DefaultsKey] && [self _hasHDH264Version]) {
		src = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=22&video_id=%@&t=%@",
					 video_id, video_hash ];
	} else {
		src = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=18&video_id=%@&t=%@",
			   video_id, video_hash ];
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

- (void)_didRetrieveEmbeddedPlayerFlashVars:(NSDictionary *)flashVars
{
	if (flashVars)
	{
		_flashVars = [flashVars retain];
		NSString *videoId = [self flashvarWithName:@"video_id"];
		[self setVideoId:videoId];
	}
	
	[self _checkForH264VideoVariants];
}

- (void)_retrieveEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:(NSString *)videoId
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *URLString = [NSString stringWithFormat:@"http://youtube.com/watch?v=%@",videoId];
	NSURL *YouTubePageURL = [NSURL URLWithString:URLString];
	NSError *pageSourceError = nil;
	NSString *pageSourceString = [NSString stringWithContentsOfURL:YouTubePageURL
													  usedEncoding:nil
															 error:&pageSourceError];
	NSDictionary *flashVars = nil;
	if (pageSourceString && !pageSourceError) {
		flashVars = [self _flashVarDictionaryFromYouTubePageHTML:pageSourceString];
	}
	
	[self performSelectorOnMainThread:@selector(_didRetrieveEmbeddedPlayerFlashVars:)
						   withObject:flashVars
						waitUntilDone:NO];
	
	[pool drain];
}

- (void)_getEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:(NSString *)videoId
{
	[NSThread detachNewThreadSelector:@selector(_retrieveEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:)
							 toTarget:self
						   withObject:videoId];
}


#pragma mark -
#pragma mark DOM Conversion


- (void) _convertTypesForElement:(DOMElement *)element
{
    NSString *type = [element getAttribute:@"type"];

    if ([type isEqualToString:sFlashOldMIMEType] || [type length] == 0) {
        [element setAttribute:@"type" value:sFlashNewMIMEType];
    }
}

- (void) _convertTypesForContainer
{
    if ([self _useH264Version])
        [self _convertToMP4Container];
    else
        [self _convertTypesForFlashContainer];
}

- (void) _convertTypesForFlashContainer
{
	[self _revertToOriginalOpacityAttributes];
	
	// Delay this until the end of the event loop, because it may cause self to be deallocated
	[self _prepareForConversion];
	[self performSelector:@selector(_convertTypesForFlashContainerAfterDelay) withObject:nil afterDelay:0.0];
}

- (void) _convertTypesForFlashContainerAfterDelay
{
    DOMNodeList *nodeList = nil;
    NSUInteger i;

    [self _convertTypesForElement:[self container]];

    nodeList = [[self container] getElementsByTagName:@"object"];
    for (i = 0; i < [nodeList length]; i++) {
        [self _convertTypesForElement:(DOMElement *)[nodeList item:i]];
    }

    nodeList = [[self container] getElementsByTagName:@"embed"];
    for (i = 0; i < [nodeList length]; i++) {
        [self _convertTypesForElement:(DOMElement *)[nodeList item:i]];
    }
    
    // Remove & reinsert the node to persuade the plugin system to notice the type change:
    id parent = [[self container] parentNode];
    id successor = [[self container] nextSibling];
	
	DOMElement *theContainer = [[self container] retain];
    [parent removeChild:theContainer];
    [parent insertBefore:theContainer refChild:successor];
	[theContainer release];
    [self setContainer:nil];
}

- (void) _prepareForConversion
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// notify that this ClickToFlash plugin is going away
	[[CTFMenubarMenuController sharedController] unregisterView: self];
	
	[ self _abortAlert ];
}

- (void) _revertToOriginalOpacityAttributes
{
	NSString *selfWmode = [[self originalOpacityAttributes] objectForKey:@"self-wmode"];
	if (selfWmode != nil ) {
		[[self container] setAttribute:@"wmode" value:selfWmode];
	}
	
	NSString *currentStyle = [[self container] getAttribute:@"style"];
	NSString *originalSelfStyle = [[self originalOpacityAttributes] objectForKey:@"self-style"];
	if (originalSelfStyle != nil ) {
		if ([currentStyle isEqualToString:[[self originalOpacityAttributes] objectForKey:@"modified-self-style"]]) {
			[[self container] setAttribute:@"style" value:originalSelfStyle];
		}
	}
	
	NSString *parentWmode = [[self originalOpacityAttributes] objectForKey:@"parent-wmode"];
	if (parentWmode != nil ) {
		[(DOMElement *)[[self container] parentNode] setAttribute:@"wmode" value:parentWmode];
	}
	
	NSString *currentParentStyle = [(DOMElement *)[[self container] parentNode] getAttribute:@"style"];
	NSString *originalParentStyle = [[self originalOpacityAttributes] objectForKey:@"parent-style"];
	if (originalParentStyle != nil ) {
		if ([currentParentStyle isEqualToString:[[self originalOpacityAttributes] objectForKey:@"modified-parent-style"]]) {
			[(DOMElement *)[[self container] parentNode] setAttribute:@"style" value:originalParentStyle];
		}
	}
}

- (WebView *)webView
{
    return _webView;
}
- (void)setWebView:(WebView *)newValue
{
    // Not retained, because the WebView owns the plugin, so we'll get a retain cycle.
    _webView = newValue;
}

- (DOMElement *)container
{
    return _container;
}
- (void)setContainer:(DOMElement *)newValue
{
    [newValue retain];
    [_container release];
    _container = newValue;
}

- (NSString *)host
{
    return _host;
}
- (void)setHost:(NSString *)newValue
{
    [newValue retain];
    [_host release];
    _host = newValue;
}

- (NSString *)baseURL
{
    return _baseURL;
}
- (void)setBaseURL:(NSString *)newValue
{
    [newValue retain];
    [_baseURL release];
    _baseURL = newValue;
}

- (NSDictionary *)attributes
{
    return _attributes;
}
- (void)setAttributes:(NSDictionary *)newValue
{
    [newValue retain];
    [_attributes release];
    _attributes = newValue;
}

- (NSDictionary *)originalOpacityAttributes
{
    return _originalOpacityAttributes;
}
- (void)setOriginalOpacityAttributes:(NSDictionary *)newValue
{
    [newValue retain];
    [_originalOpacityAttributes release];
    _originalOpacityAttributes = newValue;
}

- (NSString *)src
{
    return _src;
}
- (void)setSrc:(NSString *)newValue
{
    [newValue retain];
    [_src release];
    _src = newValue;
}

- (NSString *)videoId
{
    return [[_videoId retain] autorelease];
}
- (void)setVideoId:(NSString *)newValue
{
    [newValue retain];
    [_videoId release];
    _videoId = newValue;
}

- (BOOL)_hasH264Version
{
	return (_fromYouTube && _hasH264Version);
}

- (void)_setHasH264Version:(BOOL)newValue
{
	_hasH264Version = newValue;
	[self setNeedsDisplay:YES];
}

- (BOOL)_hasHDH264Version
{
	return (_fromYouTube && _hasHDH264Version);
}

- (void)_setHasHDH264Version:(BOOL)newValue
{
	_hasHDH264Version = newValue;
	[self setNeedsDisplay:YES];
}

- (void)setLaunchedAppBundleIdentifier:(NSString *)newValue
{
    [newValue retain];
    [_launchedAppBundleIdentifier release];
    _launchedAppBundleIdentifier = newValue;
}
@end

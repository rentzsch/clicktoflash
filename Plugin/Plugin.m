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
#import "CTFMenubarMenuController.h"
#import "CTFUtilities.h"
#import "CTFWhitelist.h"
#import "CTFGradient.h"
#import "CTFKiller.h"
#import "CTFLoader.h"
#import "CTFActionButton.h"
#import "CTFMainButton.h"


#define LOGGING_ENABLED 0

// MIME types
static NSString *sFlashOldMIMEType = @"application/x-shockwave-flash";
static NSString *sFlashNewMIMEType = @"application/futuresplash";

// CTFUserDefaultsController keys
static NSString *sAutoLoadInvisibleFlashViewsKey = @"autoLoadInvisibleViews";
static NSString *sPluginEnabled = @"pluginEnabled";
static NSString *sApplicationWhitelist = @"applicationWhitelist";
//static NSString *sDrawGearImageOnlyOnMouseOverHiddenPref = @"drawGearImageOnlyOnMouseOver";

// Info.plist key for app developers
static NSString *sCTFOptOutKey = @"ClickToFlashOptOut";

// Subview Tags
enum subviewTags {
	CTFGradientViewTag,
	CTFImageViewTag,
	CTFMainButtonTag,
	CTFActionButtonTag
};


@interface CTFClickToFlashPlugin (Internal)
- (void) _convertTypesForFlashContainer;
- (void) _convertTypesForFlashContainerAfterDelay;

- (void) _drawBackground;
- (BOOL) _isOptionPressed;
- (BOOL) _isCommandPressed;

- (void) _loadContent: (NSNotification*) notification;
- (void) _loadContentForWindow: (NSNotification*) notification;

- (NSString *)launchedAppBundleIdentifier;
@end



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
		_contextMenuIsVisible = NO;
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
		
        if (![[CTFUserDefaultsController standardUserDefaults] objectForKey:sAutoLoadInvisibleFlashViewsKey]) {
            //  Default to auto-loading invisible flash views.
            [[CTFUserDefaultsController standardUserDefaults] setBool:YES forKey:sAutoLoadInvisibleFlashViewsKey];
        }
		if (![[CTFUserDefaultsController standardUserDefaults] objectForKey:sPluginEnabled]) {
			// Default to enable the plugin
			[[CTFUserDefaultsController standardUserDefaults] setBool:YES forKey:sPluginEnabled];
		}
		
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
		
        
        // Read in flashvars
        
        NSString* flashvars = [[self attributes] objectForKey: @"flashvars" ];
        if( flashvars != nil )
            _flashVars = [ [ CTFClickToFlashPlugin flashVarDictionary: flashvars ] retain ];
		
		
		// Set up the CTFKiller subclass, if appropriate.
		[self setKiller: [CTFKiller killerForURL:[NSURL URLWithString:[self baseURL]] src:[self src] attributes:[self attributes] forPlugin:self]];
		
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
			[self convertTypesForContainer];
			return self;
		}		
		
		// Plugin is enabled and the host is not white-listed. Kick off Sparkle.
		
		/*NSString *pathToRelaunch = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[CTFClickToFlashPlugin launchedAppBundleIdentifier]];
		[[SparkleManager sharedManager] setPathToRelaunch:pathToRelaunch];
		[[SparkleManager sharedManager] startAutomaticallyCheckingForUpdates];*/
		
        // Set up main menus
        
		[ CTFMenubarMenuController sharedController ];	// trigger the menu items to be added

		if ( [ [ CTFUserDefaultsController standardUserDefaults ] boolForKey: sAutoLoadInvisibleFlashViewsKey ]
			&& [ self isConsideredInvisible ] ) {
			// auto-loading is on and this view meets the size constraints
            _isLoadingFromWhitelist = YES;
			[self convertTypesForContainer];
			return self;
		}
		
		
		BOOL loadFromWhiteList = [self _isHostWhitelisted];
		
		// Check the SWF src URL itself against the whitelist (allows embbeded videos from whitelisted sites to play, e.g. YouTube)
		
		if( !loadFromWhiteList ) {
            if (srcAttribute) {
				if( [self _isWhiteListedForHostString:srcAttribute ] ) {
                    loadFromWhiteList = YES;
                }
            }
		}
		
        
        // Handle if this is loading from whitelist
        
        if(loadFromWhiteList && ![self _isOptionPressed]) {
            _isLoadingFromWhitelist = YES;
			[self convertTypesForContainer];

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
		
		// Add main control button
		CTFMainButton * mainButton = [[[CTFMainButton alloc] initWithFrame: [self bounds]] autorelease];
		[mainButton setTag: CTFMainButtonTag];
		[mainButton setAutoresizingMask: (NSViewHeightSizable | NSViewWidthSizable) ];
		[mainButton setButtonType: NSMomentaryPushInButton];
		[mainButton setTarget: self];
		[mainButton setAction: @selector(clicked:)];
		[self addSubview: mainButton];		
		
		/* // Doesn't work for us as NSImageView can only scale proportionally to _fit_ but not to _fit width_
		// Add Image View
		NSImageView * imageView = [[[NSImageView alloc] initWithFrame: [self bounds]] autorelease];
		[imageView setTag: CTFImageViewTag];
		[imageView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
		[imageView setImage: NSImageFrameNone];
		[imageView setImageAlignment: NSImageAlignCenter];
		[imageView setImageScaling: NSImageScaleProportionally];
		[self addSubview: imageView];
		*/
		
		// Add action button control
		CTFActionButton * actionButton = [CTFActionButton actionButton];
		[actionButton setTag: CTFActionButtonTag];
		[actionButton setAutoresizingMask: NSViewMaxXMargin | NSViewMinYMargin];
		[self addSubview: actionButton];
	}

    return self;
}



- (void)webPlugInDestroy
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[self _abortAlert];        // to be on the safe side
	
	// notify that this ClickToFlash plugin is going away
	[[CTFMenubarMenuController sharedController] unregisterView:self];
	
	[self setContainer:nil];
	[self setHost:nil];
	[self setWebView:nil];
	[self setBaseURL:nil];
	[self setBaseURL:nil];
	[self setAttributes:nil];
	[self setOriginalOpacityAttributes:nil];
	[self setKiller:nil];
	[self setPreviewURL:nil];
	[self setPreviewImage:nil];
	
	[_flashVars release];
	_flashVars = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (NSMenuItem *) addContextualMenuItemWithTitle: (NSString*) title action: (SEL) selector {
	return [self addContextualMenuItemWithTitle: title action: selector target: self];
}


- (NSMenuItem *) addContextualMenuItemWithTitle: (NSString*) title action: (SEL) selector target:(id) target {
	NSMenuItem * menuItem = [[[NSMenuItem alloc] initWithTitle: title action:selector keyEquivalent:@""] autorelease];
	[menuItem setTarget: target];
	[[self menu] addItem: menuItem];
	return menuItem;
}



/*
 Build contextual menu
*/
- (NSMenu*) menuForEvent: (NSEvent*) event
{
	NSMenuItem * menuItem;
	
	[self setMenu: [[[NSMenu alloc] initWithTitle:CtFLocalizedString( @"ClickTo Flash Contextual menu", @"Title of Contextual Menu")] autorelease]];
	
	[self addContextualMenuItemWithTitle:CtFLocalizedString( @"Load Flash", @"Contextual Menu Item: Load Flash" ) 
								  action: @selector( loadFlash: )];
	
	if ([self killer] != nil) {
		[[self killer] addPrincipalMenuItemToContextualMenu];
	}
	
	if ([[CTFMenubarMenuController sharedController] multipleFlashViewsExistForWindow:[self window]]) {
		[self addContextualMenuItemWithTitle: CtFLocalizedString( @"Load All on this Page", @"Load All on this Page contextual menu item" )
									  action: @selector( loadAllOnPage: )];
	}
	
	[self addContextualMenuItemWithTitle: CtFLocalizedString( @"Hide Flash", @"Hide Flash contextual menu item (sets display:none)")
								  action: @selector( hideFlash:)];
	menuItem = [self addContextualMenuItemWithTitle: CtFLocalizedString( @"Remove Flash", @"Remove Flash contextual menu item (sets visibility: hidden)")
											 action: @selector( removeFlash: )];
	[menuItem setAlternate:YES];
	[menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
	
	[[self menu] addItem: [NSMenuItem separatorItem]];
	
	if ([self killer]) {
		NSInteger itemCount = [[self menu] numberOfItems];
		[[self killer] addAdditionalMenuItemsForContextualMenu];
		if ([[self menu] numberOfItems] != itemCount) {
			[[self menu] addItem: [NSMenuItem separatorItem]];
		}
	}
	
	if ([self host] && ![self _isHostWhitelisted]) {
		[self addContextualMenuItemWithTitle: [NSString stringWithFormat:CtFLocalizedString( @"Add %@ to Whitelist", @"Add <sitename> to Whitelist contextual menu item" ), [self host]]
									   action: @selector( addToWhitelist: )];
		[[self menu] addItem: [NSMenuItem separatorItem]];
	}
	
	[self addContextualMenuItemWithTitle: CtFLocalizedString( @"ClickToFlash Preferences...", @"Preferences contextual menu item" )
									action: @selector( editWhitelist: )];
	
	
    return [self menu];
}


- (BOOL) validateMenuItem: (NSMenuItem *)menuItem
{
	return YES;
}





#pragma mark -
#pragma mark Loading

- (IBAction) clicked: (id) sender {
	if ([self _isCommandPressed]) {
		if ([self _isOptionPressed]) {
			[self removeFlash:self];
		} else {
			[self hideFlash:self];
		}
	} else if ([self _isOptionPressed] && ![self _isHostWhitelisted]) {
		[self _askToAddCurrentSiteToWhitelist];
	} else {
		[self convertTypesForContainer];
	}
}


- (IBAction)removeFlash: (id) sender;
{
    DOMCSSStyleDeclaration *style = [[self container] style];
	[style setProperty:@"display" value:@"none" priority:@"important"];
}

- (IBAction)hideFlash: (id) sender;
{
    DOMCSSStyleDeclaration *style = [[self container] style];
	[style setProperty:@"visibility" value:@"hidden" priority:@"important"];
}

- (IBAction)loadFlash:(id)sender;
{
    [self _convertTypesForFlashContainer];
}

- (IBAction)loadAllOnPage:(id)sender
{
    [[CTFMenubarMenuController sharedController] loadFlashForWindow: [self window]];
}


- (void) _loadContent: (NSNotification*) notification
{
    [self convertTypesForContainer];
}

- (void) _loadContentForWindow: (NSNotification*) notification
{
	if( [ notification object ] == [ self window ] )
		[ self convertTypesForContainer ];
}

- (void) _loadInvisibleContentForWindow: (NSNotification*) notification
{
	if( [ notification object ] == [ self window ] && [ self isConsideredInvisible ] ) {
		[ self convertTypesForContainer ];
	}
}




#pragma mark -
#pragma mark Helper Methods


+ (NSDictionary*) flashVarDictionary: (NSString*) flashvarString
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


- (NSString*) flashvarWithName: (NSString*) argName
{
    return [[[ _flashVars objectForKey: argName ] retain] autorelease];
}


+ (NSString *)launchedAppBundleIdentifier
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


- (BOOL) _isOptionPressed {
    BOOL isOptionPressed = (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0);
    return isOptionPressed;
}

- (BOOL) _isCommandPressed {
	BOOL isCommandPressed = (([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) != 0);
	return isCommandPressed;
}


- (void) browseToURLString: (NSString*) URLString {
	[_webView setMainFrameURL:URLString];
}

- (void) downloadURLString: (NSString*) URLString {
	[[NSWorkspace sharedWorkspace] openURLs: [NSArray arrayWithObject:[NSURL URLWithString: URLString]]
					withAppBundleIdentifier: [CTFClickToFlashPlugin launchedAppBundleIdentifier]
									options: NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor: [NSAppleEventDescriptor nullDescriptor]
						  launchIdentifiers: nil];		
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


- (void) convertTypesForContainer {
	BOOL success = NO;
	if ([self killer]) {
		success = [[self killer] convertToContainer];
	}

	if (!success) {
        [self _convertTypesForFlashContainer];
	}
}


- (void) _convertTypesForFlashContainer
{
	[self revertToOriginalOpacityAttributes];
	
	// Delay this until the end of the event loop, because it may cause self to be deallocated
	[self prepareForConversion];
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

- (void) prepareForConversion
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// notify that this ClickToFlash plugin is going away
	[[CTFMenubarMenuController sharedController] unregisterView: self];
	
	[ self _abortAlert ];
}

- (void) revertToOriginalOpacityAttributes
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
#pragma mark Accessibility


- (BOOL)accessibilityIsIgnored {
	return NO;
}



- (NSArray *) accessibilityAttributeNames {
	NSMutableArray * attributes = [[[super accessibilityAttributeNames] mutableCopy] autorelease];
	//	[attributes addObject: NSAccessibilityTitleAttribute];
	[attributes addObject: NSAccessibilityDescriptionAttribute];
//	[attributes addObject: NSAccessibilityHelpAttribute];
//	[attributes addObject: NSAccessibilityParentAttribute];
//	[attributes addObject: NSAccessibilityChildrenAttribute];
//	[attributes addObject: NSAccessibilityRoleAttribute];
//	[attributes addObject: NSAccessibilityRoleDescriptionAttribute];
	return attributes;
}



- (id) accessibilityAttributeValue: (NSString *) attribute {
	id value = nil;
	
	if ( [attribute isEqualToString: NSAccessibilityTitleAttribute] ) {
		//	value = [self badgeLabelText];
	}
	else if ( [attribute isEqualToString: NSAccessibilityDescriptionAttribute] ) {
//		value = CtFLocalizedString( @"Blocked Flash content", @"Accessibility: NSAccessibilityDescriptionAttribute for Plugin.m");
	}
	else if ( [attribute isEqualToString: NSAccessibilityHelpAttribute] ) {
//		value = CtFLocalizedString( @"A film or other interactive content is implemented in Flash should appear here. ClickToFlash prevented it from loading automatically.", @"Accessibility: NSAccessibilityHelpAttribute for Plugin.m");
	}
	else if ( [attribute isEqualToString: NSAccessibilityParentAttribute] ){
		value = NSAccessibilityUnignoredAncestor([[[self webView] mainFrame] frameView]); 
	}
	else if ( [attribute isEqualToString: NSAccessibilityChildrenAttribute] ){
		value = [NSArray arrayWithObjects: [self viewWithTag: CTFMainButtonTag], [self viewWithTag:CTFActionButtonTag], nil];
	} 
	else if ( [attribute isEqualToString: NSAccessibilityRoleAttribute] ) {
		value = NSAccessibilityGroupRole;
	}
	else if ( [attribute isEqualToString: NSAccessibilityRoleDescriptionAttribute] ) {
		value = NSAccessibilityRoleDescription(NSAccessibilityGroupRole, nil);
	} 
	else {
		value =  [super accessibilityAttributeValue:attribute];
	}
	
	return value;
}




#pragma mark -
#pragma mark Preferences

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





#pragma mark -
#pragma mark Accessors

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


- (CTFKiller *)killer
{
	return killer;
}

- (void)setKiller:(CTFKiller *)newKiller
{
	[newKiller retain];
	[killer release];
	killer = newKiller;
}


- (NSURL *) previewURL {
	return previewURL;
}

- (void) setPreviewURL:(NSURL *) newPreviewURL {
	[newPreviewURL retain];
	[previewURL release];
	previewURL = newPreviewURL;
	
	if (previewURL != nil) {
		CTFLoader * loader = [[[CTFLoader alloc] initWithURL: newPreviewURL delegate: self selector:@selector(receivedPreviewImage:)] autorelease];
		[loader start];
	}
}


- (NSImage *) previewImage {
    return previewImage;
}

- (void) setPreviewImage: (NSImage *) newPreviewImage {
	[newPreviewImage retain];
	[previewImage release];
	previewImage = newPreviewImage;
	
	[self setNeedsDisplay: YES];
}

- (void) receivedPreviewImage: (CTFLoader*) loader {
	NSImage * image = [[[NSImage alloc] initWithData: [loader data]] autorelease];
	if (image != nil) {
		[self setPreviewImage: image];
	}
}




@end

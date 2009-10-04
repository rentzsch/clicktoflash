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
#import "CTFUtilities.h"
#import "CTFWhitelist.h"
#import "NSBezierPath-RoundedRectangle.h"
#import "CTFGradient.h"
#import "SparkleManager.h"
#import "CTFKiller.h"

#define LOGGING_ENABLED 0

    // MIME types
static NSString *sFlashOldMIMEType = @"application/x-shockwave-flash";
static NSString *sFlashNewMIMEType = @"application/futuresplash";

    // CTFUserDefaultsController keys
static NSString *sAutoLoadInvisibleFlashViewsKey = @"autoLoadInvisibleViews";
static NSString *sPluginEnabled = @"pluginEnabled";
static NSString *sApplicationWhitelist = @"applicationWhitelist";
static NSString *sDrawGearImageOnlyOnMouseOverHiddenPref = @"drawGearImageOnlyOnMouseOver";

	// Info.plist key for app developers
static NSString *sCTFOptOutKey = @"ClickToFlashOptOut";

BOOL usingMATrackingArea = NO;

@interface CTFClickToFlashPlugin (Internal)
- (void) _convertTypesForFlashContainer;
- (void) _convertTypesForFlashContainerAfterDelay;

- (void) _drawBackground;
- (BOOL) _isOptionPressed;
- (BOOL) _isCommandPressed;
- (void) _checkMouseLocation;
- (void) _addTrackingAreaForCTF;
- (void) _removeTrackingAreaForCTF;


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
		
		NSString *pathToRelaunch = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[CTFClickToFlashPlugin launchedAppBundleIdentifier]];
		[[SparkleManager sharedManager] setPathToRelaunch:pathToRelaunch];
		[[SparkleManager sharedManager] startAutomaticallyCheckingForUpdates];
		
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
	[self setAttributes:nil];
	[self setOriginalOpacityAttributes:nil];
	[self setKiller:nil];
	
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
    } else {
		_contextMenuIsVisible = NO;
	}
}

- (BOOL) _isOptionPressed
{
    BOOL isOptionPressed = (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0);
    return isOptionPressed;
}

- (BOOL) _isCommandPressed
{
	BOOL isCommandPressed = (([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) != 0);
	return isCommandPressed;
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
#pragma mark Drawing

- (NSString*) badgeLabelText
{
	NSString * labelText = nil;
	
	if ([self killer] != nil) {
		labelText = [[self killer] badgeLabelText];
	}
	
	if (labelText == nil) {
		labelText = CtFLocalizedString( @"Flash", @"Flash badge text" );
	}
	
	return labelText;
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

@end

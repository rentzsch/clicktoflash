/*

The MIT License

Copyright (c) 2008-2009 Click to Flash Developers

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

#import "MATrackingArea.h"
#import "CTFMenubarMenuController.h"
#import "CTFsIFRSupport.h"
#import "CTFUtilities.h"
#import "CTFWhitelist.h"
#import "NSBezierPath-RoundedRectangle.h"
#import "SparkleManager.h"

#define LOGGING_ENABLED 0

    // MIME types
static NSString *sFlashOldMIMEType = @"application/x-shockwave-flash";
static NSString *sFlashNewMIMEType = @"application/futuresplash";

    // NSUserDefaults keys
static NSString *sUseYouTubeH264DefaultsKey = @"ClickToFlash_useYouTubeH264";
static NSString *sAutoLoadInvisibleFlashViewsKey = @"ClickToFlash_autoLoadInvisibleViews";
static NSString *sPluginEnabled = @"ClickToFlash_pluginEnabled";

BOOL usingMATrackingArea = NO;

@interface NSBezierPath(MRGradientFill)
-(void)linearGradientFill:(NSRect)thisRect
               startColor:(NSColor *)startColor
                 endColor:(NSColor *)endColor;
@end

@interface CTFClickToFlashPlugin (Internal)
- (void) _convertTypesForFlashContainer;
- (void) _convertTypesForFlashContainerAfterDelay;
- (void) _convertToMP4Container;
- (void) _convertToMP4ContainerAfterDelay;
- (void) _prepareForConversion;
- (void) _revertToOriginalOpacityAttributes;

- (void) _drawBackground;
- (BOOL) _isOptionPressed;
- (void) _addTrackingAreaForCTF;
- (void) _removeTrackingAreaForCTF;

- (void) _loadContent: (NSNotification*) notification;
- (void) _loadContentForWindow: (NSNotification*) notification;

- (NSDictionary*) _flashVarDictionary: (NSString*) flashvarString;
- (NSString*) flashvarWithName: (NSString*) argName;
- (BOOL) _hasH264Version;
- (BOOL) _useH264Version;
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
		SparkleManager *sharedSparkleManager = [SparkleManager sharedManager];
		NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
		NSString *pathToRelaunch = [sharedWorkspace absolutePathForAppBundleWithIdentifier:[self launchedAppBundleIdentifier]];
		[sharedSparkleManager setPathToRelaunch:pathToRelaunch];
        [sharedSparkleManager startAutomaticallyCheckingForUpdates];
        
        if (![[NSUserDefaults standardUserDefaults] objectForKey:sAutoLoadInvisibleFlashViewsKey]) {
            //  Default to auto-loading invisible flash views.
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:sAutoLoadInvisibleFlashViewsKey];
        }
		if (![[NSUserDefaults standardUserDefaults] objectForKey:sPluginEnabled]) {
			// Default to enable the plugin
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:sPluginEnabled];
		}
		
		[self setLaunchedAppBundleIdentifier:[self launchedAppBundleIdentifier]];
		
		[self setWebView:[[[arguments objectForKey:WebPlugInContainerKey] webFrame] webView]];
		
        [self setContainer:[arguments objectForKey:WebPlugInContainingElementKey]];
        
        [self _migrateWhitelist];
        
		
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
		
		if ([self src]) [self setToolTip:[self src]];
		
        
        // Read in flashvars (needed to determine YouTube videos)
        
        NSString* flashvars = [[self attributes] objectForKey: @"flashvars" ];
        if( flashvars != nil )
            _flashVars = [ [ self _flashVarDictionary: flashvars ] retain ];
        
#if LOGGING_ENABLED
        NSLog( @"arguments = %@", arguments );
        NSLog( @"flashvars = %@", _flashVars );
#endif
		
		// check whether it's from YouTube and get the video_id
		
        _fromYouTube = [[self host] isEqualToString:@"www.youtube.com"]
		|| ( flashvars != nil && [flashvars rangeOfString: @"www.youtube.com"].location != NSNotFound )
		|| ([self src] != nil && [[self src] rangeOfString: @"youtube.com"].location != NSNotFound );
		
        if (_fromYouTube) {
			NSString *videoId = [ self flashvarWithName: @"video_id" ];
			if (videoId != nil) {
				[self setVideoId:videoId];
			} else {
				// scrub the URL to determine the video_id
				
				NSString *videoIdFromURL = nil;
				NSScanner *URLScanner = [[NSScanner alloc] initWithString:[self src]];
				[URLScanner scanUpToString:@"youtube.com/v/" intoString:nil];
				if ([URLScanner scanString:@"youtube.com/v/" intoString:nil]) {
					// URL is in required format, next characters are the id
					
					[URLScanner scanUpToString:@"&" intoString:&videoIdFromURL];
					if (videoIdFromURL) [self setVideoId:videoIdFromURL];
				}
				[URLScanner release];
			}
		}
		
		
		// check whether plugin is disabled, load all content as normal if so
		
		if ( ![ [ NSUserDefaults standardUserDefaults ] boolForKey: sPluginEnabled ] ) {
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
		
		if ( [ [ NSUserDefaults standardUserDefaults ] boolForKey: sAutoLoadInvisibleFlashViewsKey ]
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
			[self _convertTypesForContainer];
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

        [self _addTrackingAreaForCTF];
    }

    return self;
}

- (void) dealloc
{
    [self _removeTrackingAreaForCTF];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[self _abortAlert];        // to be on the safe side
	
	// notify that this ClickToFlash plugin is going away
	[[CTFMenubarMenuController sharedController] unregisterView: self];
    
    [self setContainer:nil];
    [self setHost:nil];
    [self setWebView:nil];
    [self setBaseURL:nil];
    [self setAttributes:nil];
    
    [_flashVars release];
    [_badgeText release];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
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

- (void) mouseDown:(NSEvent *)event
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
	
	if (xCoordWithinGearImage && yCoordWithinGearImage) {
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
    
    if (mouseInside) {
        if ([self _isOptionPressed] && ![self _isHostWhitelisted]) {
            [self _askToAddCurrentSiteToWhitelist];
        } else {
            [self _convertTypesForContainer];
        }
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

- (NSMenu*) menuForEvent: (NSEvent*) event
{
    // Set up contextual menu
    
    if( ![ self menu ] ) {
        if (![NSBundle loadNibNamed:@"ContextualMenu" owner:self]) {
            NSLog(@"Could not load contextual menu plugin");
        }
        else {
            if ([self _hasH264Version]) {
                [[self menu] insertItemWithTitle: NSLocalizedString( @"Load H.264", "Load H.264 context menu item" )
                                          action: @selector( loadH264: ) keyEquivalent: @"" atIndex: 1];
				[[self menu] insertItemWithTitle: NSLocalizedString( @"Download H.264", "Download H.264 menu item" )
										  action: @selector( downloadH264: ) keyEquivalent: @"" atIndex: 2];
                [[[self menu] itemAtIndex: 1] setTarget: self];
				[[[self menu] itemAtIndex: 2] setTarget: self];
            } else if (_fromYouTube) {
				// has no H.264 version but is from YouTube; it's an embedded view!
				
				[[self menu] insertItemWithTitle: NSLocalizedString ( @"Load YouTube.com page for this video", "Load YouTube page menu item" )
										  action: @selector (loadYouTubePage: ) keyEquivalent: @"" atIndex: 1];
				[[[self menu] itemAtIndex: 1] setTarget: self];
			}
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
        NSString* title = [NSString stringWithFormat:
                NSLocalizedString(@"Add %@ to Whitelist", @"Add <sitename> to Whitelist menu title"), 
                [self host]];
        [menuItem setTitle: title];
        if ([self _isHostWhitelisted])
            enabled = NO;
    }
    else if (action == @selector(removeFromWhitelist:))
    {
        if (![self _isHostWhitelisted])
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
    if( [ self _useH264Version ] )
        return NSLocalizedString( @"H.264", @"H.264 badge text" );
    else if( [ self _hasH264Version ] )
        return NSLocalizedString( @"YouTube", @"YouTube badge text" );
    else if( _badgeText )
        return _badgeText;
    else
        return NSLocalizedString( @"Flash", @"Flash badge text" );
}

- (void) _drawBadgeWithPressed: (BOOL) pressed
{
	// What and how are we going to draw?
	
	const float kFrameXInset = 10;
	const float kFrameYInset =  4;
	const float kMinMargin   = 11;
	const float kMinHeight   =  6;
	
	NSString* str = [ self badgeLabelText ];
	
	NSDictionary* attrs = [ NSDictionary dictionaryWithObjectsAndKeys: 
						   [ NSFont boldSystemFontOfSize: 20 ], NSFontAttributeName,
						   [ NSNumber numberWithInt: -1 ], NSKernAttributeName,
						   [ NSColor blackColor ], NSForegroundColorAttributeName,
						   nil ];
	
	// Set up for drawing.
	
	NSRect bounds = [ self bounds ];
	
	// How large would this text be?
	
	NSSize strSize = [ str sizeWithAttributes: attrs ];
	
	float w = strSize.width  + kFrameXInset * 2;
	float h = strSize.height + kFrameYInset * 2;
	
	// Compute a scale factor based on the view's size.
	
	float maxW = NSWidth( bounds ) - kMinMargin;
	float maxH = NSHeight( bounds ) - kMinMargin;
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
	[ xform translateXBy: NSWidth( bounds ) / 2 yBy: NSHeight( bounds ) / 2 ];
	[ xform scaleBy: scaleFactor ];
	if( rotate )
		[ xform rotateByDegrees: 90 ];
	[ xform concat ];
	
    CGContextRef context = [ [ NSGraphicsContext currentContext ] graphicsPort ];
    
    CGContextSetAlpha( context, pressed ? 0.40 : 0.25 );
    CGContextBeginTransparencyLayer( context, nil );
	
	// Draw everything at full size, centered on the origin.
	
	NSPoint loc = { -strSize.width / 2, -strSize.height / 2 };
	NSRect borderRect = NSMakeRect( loc.x - kFrameXInset, loc.y - kFrameYInset, w, h );
	
	NSBezierPath* fillPath = bezierPathWithRoundedRectCornerRadius( NSInsetRect( borderRect, -2, -2 ), 6 );
	[ [ NSColor colorWithCalibratedWhite: 1.0 alpha: 0.25 ] set ];
	[ fillPath fill ];
	
	NSBezierPath* path = bezierPathWithRoundedRectCornerRadius( borderRect, 4 );
	[ [ NSColor blackColor ] set ];
	[ path setLineWidth: 3 ];
	[ path stroke ];
	
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
                
                [gradient initWithStartingColor:startingColor endingColor:endingColor];
                
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
        [gradient initWithStartingColor:startingColor endingColor:endingColor];

        [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:fillRect] angle:90.0 + ((mouseIsDown && mouseInside) ? 0.0 : 180.0)];

        [gradient release];
    }
    else
    {
        //tweak colors for better compatibility with linearGradientFill
        startingColor = [NSColor colorWithDeviceWhite:0.633 alpha:0.15];
        endingColor = [NSColor colorWithDeviceWhite:0.333 alpha:0.15];
        NSBezierPath *path = [NSBezierPath bezierPath];

        //Draw Gradient
        [path linearGradientFill:fillRect
                      startColor:((mouseIsDown && mouseInside) ? endingColor : startingColor)
                        endColor:((mouseIsDown && mouseInside) ? startingColor : endingColor)];
        [path stroke];
    }

    // Draw stroke
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.50] set];
    [NSBezierPath setDefaultLineWidth:2.0];
    [NSBezierPath setDefaultLineCapStyle:NSSquareLineCapStyle];
    [[NSBezierPath bezierPathWithRect:strokeRect] stroke];

    // Draw label
    [ self _drawBadgeWithPressed: mouseIsDown && mouseInside ];
    
    // Draw the gear icon
    if( mouseInside && !mouseIsDown )
        [ self _drawGearIcon ];
}

- (void) _addTrackingAreaForCTF
{
    if (trackingArea)
        return;
    
    trackingArea = [NSClassFromString(@"NSTrackingArea") alloc];
    if (trackingArea != nil)
    {
        [trackingArea initWithRect:[self bounds]
                           options:MATrackingMouseEnteredAndExited | MATrackingActiveInKeyWindow | MATrackingEnabledDuringMouseDrag | MATrackingInVisibleRect
                             owner:self
                          userInfo:nil];
        [self addTrackingArea:trackingArea];
    }
    else
    {
        trackingArea = [NSClassFromString(@"MATrackingArea") alloc];
        [trackingArea initWithRect:[self bounds]
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

- (NSString*) flashvarWithName: (NSString*) argName
{
    return [ _flashVars objectForKey: argName ];
}

/*- (NSString*) _videoId
{
    return [ self flashvarWithName: @"video_id" ];
}*/

- (NSString*) _videoHash
{
    return [ self flashvarWithName: @"t" ];
}

- (BOOL) _hasH264Version
{
    if( _fromYouTube )
        return [self videoId] != nil && [ self _videoHash ] != nil;
    else
        return NO;
}

- (BOOL) _useH264Version
{
    return [ self _hasH264Version ] 
	&& [ [ NSUserDefaults standardUserDefaults ] boolForKey: sUseYouTubeH264DefaultsKey ] 
	&& [ [ NSUserDefaults standardUserDefaults ] boolForKey: sPluginEnabled ];
}

- (void) _convertElementForMP4: (DOMElement*) element
{
    NSString* video_id = [self videoId];
    NSString* video_hash = [ self _videoHash ];
    
    NSString* src = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=18&video_id=%@&t=%@",
                                                 video_id, video_hash ];
    
    [ element setAttribute: @"src" value: src ];
    [ element setAttribute: @"type" value: @"video/mp4" ];
    [ element setAttribute: @"scale" value: @"aspect" ];
    [ element setAttribute: @"autoplay" value: @"true" ];
    [ element setAttribute: @"cache" value: @"false" ];
   
    if( ! [ element hasAttribute: @"width" ] )
        [ element setAttribute: @"width" value: @"640" ];
   
    if( ! [ element hasAttribute: @"height" ] )
       [ element setAttribute: @"height" value: @"500" ];

    [ element setAttribute: @"flashvars" value: nil ];
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
    DOMElement* newElement = (DOMElement*) [ [self container] cloneNode: NO ];
    
    [ self _convertElementForMP4: newElement ];
    
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
    
    NSString* src = [ NSString stringWithFormat: @"http://www.youtube.com/get_video?fmt=18&video_id=%@&t=%@",
					 video_id, video_hash ];
	
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL URLWithString:src]]
					withAppBundleIdentifier:[self launchedAppBundleIdentifier]
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:[NSAppleEventDescriptor nullDescriptor]
						  launchIdentifiers:nil];
}

- (IBAction)loadYouTubePage:(id)sender
{
	NSString* YouTubePageURL = [ NSString stringWithFormat: @"http://www.youtube.com/watch?v=%@", [self videoId] ];
	
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL URLWithString:YouTubePageURL]]
					withAppBundleIdentifier:[self launchedAppBundleIdentifier]
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:[NSAppleEventDescriptor nullDescriptor]
						  launchIdentifiers:nil];
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
    [parent removeChild:[self container]];
    [parent insertBefore:[self container] refChild:successor];
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
    [newValue retain];
    [_webView release];
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
    return _videoId;
}
- (void)setVideoId:(NSString *)newValue
{
    [newValue retain];
    [_videoId release];
    _videoId = newValue;
}

- (void)setLaunchedAppBundleIdentifier:(NSString *)newValue
{
    [newValue retain];
    [_launchedAppBundleIdentifier release];
    _launchedAppBundleIdentifier = newValue;
}

@end


//### globals
float start_red,
start_green,
start_blue,
start_alpha;
float end_red,
end_green,
end_blue,
end_alpha;
float d_red,
d_green,
d_blue,
d_alpha;

@implementation NSBezierPath(MRGradientFill)

static void
evaluate(void *info, const float *in, float *out)
{
    // red
    *out++ = start_red + *in * d_red;

    // green
    *out++ = start_green + *in * d_green;

    // blue
    *out++ = start_blue + *in * d_blue;

    //alpha
    *out++ = start_alpha + *in * d_alpha;
}

float absDiff(float a, float b);
float absDiff(float a, float b)
{
    return (a < b) ? b-a : a-b;
}

-(void)linearGradientFill:(NSRect)thisRect
               startColor:(NSColor *)startColor
                 endColor:(NSColor *)endColor
{
    CGColorSpaceRef colorspace = nil;
    CGShadingRef shading;
    static CGPoint startPoint = { 0, 0 };
    static CGPoint endPoint = { 0, 0 };
    //int k;
    CGFunctionRef function;
    //CGFunctionRef (*getFunction)(CGColorSpaceRef);
    //CGShadingRef (*getShading)(CGColorSpaceRef, CGFunctionRef);

    // get my context
    CGContextRef currentContext =
        (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];


    NSColor *s = [startColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    NSColor *e = [endColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];

    // set up colors for gradient
    start_red = [s redComponent];
    start_green = [s greenComponent];
    start_blue = [s blueComponent];
    start_alpha = [s alphaComponent];

    end_red = [e redComponent];
    end_green = [e greenComponent];
    end_blue = [e blueComponent];
    end_alpha = [e alphaComponent];

    d_red = absDiff(end_red, start_red);
    d_green = absDiff(end_green, start_green);
    d_blue = absDiff(end_blue, start_blue);
    d_alpha = absDiff(end_alpha ,start_alpha);


    // draw gradient
    colorspace = CGColorSpaceCreateDeviceRGB();

    size_t components;
    static const float domain[2] = { 0.0, 1.0 };
    static const float range[10] = { 0, 1, 0, 1, 0, 1, 0, 1, 0, 1 };
    static const CGFunctionCallbacks callbacks = { 0, &evaluate, NULL };

    components = 1 + CGColorSpaceGetNumberOfComponents(colorspace);
    function = CGFunctionCreate((void *)components, 1, domain, components,
                                range, &callbacks);

    // function = getFunction(colorspace);
    startPoint.x = 0;
    startPoint.y = thisRect.origin.y;
    endPoint.x = 0;
    endPoint.y = NSMaxY(thisRect);


    shading = CGShadingCreateAxial(colorspace,
                                   startPoint, endPoint,
                                   function,
                                   NO, NO);

    CGContextDrawShading(currentContext, shading);

    CGFunctionRelease(function);
    CGShadingRelease(shading);
    CGColorSpaceRelease(colorspace);
}
@end

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

#import "CTFMenubarMenuController.h"
#import "CTFsIFRSupport.h"
#import "CTFUtilities.h"
#import "CTFWhitelist.h"
#import "NSBezierPath-RoundedRectangle.h"


#define LOGGING_ENABLED 0


    // MIME types
static NSString *sFlashOldMIMEType = @"application/x-shockwave-flash";
static NSString *sFlashNewMIMEType = @"application/futuresplash";

    // NSUserDefaults keys
static NSString *sUseYouTubeH264DefaultsKey = @"ClickToFlash_useYouTubeH264";
static NSString *sAutoLoadInvisibleFlashViewsKey = @"ClickToFlash_autoLoadInvisibleViews";


@interface CTFClickToFlashPlugin (Internal)
- (void) _convertTypesForFlashContainer;
- (void) _convertToMP4Container;
- (void) _replaceSelfWithElement: (DOMElement*) newElement;

- (void) _drawBackground;
- (BOOL) _isOptionPressed;

- (void) _loadContent: (NSNotification*) notification;
- (void) _loadContentForWindow: (NSNotification*) notification;

- (NSDictionary*) _flashVarDictionary: (NSString*) flashvarString;
- (BOOL) _hasH264Version;
- (BOOL) _useH264Version;
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
		// get defaults
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		
		self.webView = [[[arguments objectForKey:WebPlugInContainerKey] webFrame] webView];
		
        self.container = [arguments objectForKey:WebPlugInContainingElementKey];
        
        [self _migrateWhitelist];
        
        BOOL loadFromWhiteList = NO;
        
        // Get URL and test against the whitelist
        
        NSURL *base = [arguments objectForKey:WebPlugInBaseURLKey];
		[self setBaseURL:[base absoluteString]];
        if (base) {
            self.host = [base host];

            if ([self _isHostWhitelisted]) {
                loadFromWhiteList = true;
            }
        }

        
        // Check for sIFR
        
        if ([self _isSIFRText: arguments]) {
            _badgeText = NSLocalizedString(@"sIFR Flash", @"sIFR Flash badge text");
            
            if ([self _shouldAutoLoadSIFR])
                loadFromWhiteList = true;
            else if ([self _shouldDeSIFR])
                [self performSelector:@selector(_disableSIFR) withObject:nil afterDelay:0];
        }
        
        // Read in flashvars (needed to determine YouTube videos)
        
        NSString* flashvars = [ [ arguments objectForKey: WebPlugInAttributesKey ] objectForKey: @"flashvars" ];
        if( flashvars != nil )
            _flashVars = [ [ self _flashVarDictionary: flashvars ] retain ];
        
#if LOGGING_ENABLED
        NSLog( @"arguments = %@", arguments );
        NSLog( @"flashvars = %@", _flashVars );
#endif
        
        _fromYouTube = [self.host isEqualToString:@"www.youtube.com"]
                    || [flashvars rangeOfString: @"www.youtube.com"].location != NSNotFound;
        
        // Handle if this is loading from whitelist
        
        if(loadFromWhiteList && ![self _isOptionPressed]) {
            _isLoadingFromWhitelist = YES;
            [self performSelector:@selector(_convertTypesForContainer) withObject:nil afterDelay:0];
        }
        
        // Set up main menus
        
		[ CTFMenubarMenuController sharedController ];	// trigger the menu items to be added
		
        // Set tooltip
        
        NSDictionary *attributes = [arguments objectForKey:WebPlugInAttributesKey];
		NSString *src = nil;
        if (attributes != nil) {
            src = [attributes objectForKey:@"src"];
            if (src)
                [self setToolTip:src];
            else {
                src = [attributes objectForKey:@"data"];
                if (src)
                    [self setToolTip:src];
            }
        }
		
		// send a notification so that all flash objects can be tracked
		
		if ( [ [ NSUserDefaults standardUserDefaults ] boolForKey: sAutoLoadInvisibleFlashViewsKey ]
				&& [ self isConsideredInvisible ] ) {
			// auto-loading is on and this view meets the size constraints
			[self _convertTypesForContainer];
		} else {
			// we only want to track it if we don't auto-load it
			[[CTFMenubarMenuController sharedController] registerView: self];
		}
        
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
    }

    return self;
}

- (void) dealloc
{
    [self _abortAlert];        // to be on the safe side
	
	// notify that this ClickToFlash plugin is going away
	[[CTFMenubarMenuController sharedController] unregisterView: self];
    
    self.container = nil;
    self.host = nil;
	self.webView = nil;
    
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

- (void) mouseDown:(NSEvent *)event
{
    mouseIsDown = YES;
    mouseInside = YES;
    [self setNeedsDisplay:YES];
    
    // Track the mouse so that we can undo our pressed-in look if the user drags the mouse outside the view, and reinstate it if the user drags it back in.
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingEnabledDuringMouseDrag
                                                  owner:self
                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
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
    [self removeTrackingArea:trackingArea];
    [trackingArea release];
    trackingArea = nil;
    
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
	DOMElement* clonedElement = (DOMElement*) [ self.container cloneNode: NO ];
	
	int height = [[clonedElement getAttribute:@"height"] intValue];
	int width = [[clonedElement getAttribute:@"width"] intValue];
	
	return (height <= maxInvisibleDimension) && (width <= maxInvisibleDimension);
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
                self.host];
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

- (void) _drawBackground
{
    NSRect selfBounds = [self bounds];

    NSRect fillRect   = NSInsetRect(selfBounds, 1.0, 1.0);
    NSRect strokeRect = selfBounds;

    NSColor *startingColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.15];
    NSColor *endingColor = [NSColor colorWithDeviceWhite:0.0 alpha:0.15];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
    
    // When the mouse is up or outside the view, we want a convex look, so we draw the gradient downward (90+180=270 degrees).
    // When the mouse is down and inside the view, we want a concave look, so we draw the gradient upward (90 degrees).
    [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:fillRect] angle:90.0 + ((mouseIsDown && mouseInside) ? 0.0 : 180.0)];

    // Draw stroke
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.50] set];
    [NSBezierPath setDefaultLineWidth:2.0];
    [NSBezierPath setDefaultLineCapStyle:NSSquareLineCapStyle];
    [[NSBezierPath bezierPathWithRect:strokeRect] stroke];
  
    [gradient release];

    // Draw label
    [ self _drawBadgeWithPressed: mouseIsDown && mouseInside ];
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

- (NSString*) _videoId
{
    return [ self flashvarWithName: @"video_id" ];
}

- (NSString*) _videoHash
{
    return [ self flashvarWithName: @"t" ];
}

- (BOOL) _hasH264Version
{
    if( _fromYouTube )
        return [ self _videoId ] != nil && [ self _videoHash ] != nil;
    else
        return NO;
}

- (BOOL) _useH264Version
{
    return [ self _hasH264Version ] 
            && [ [ NSUserDefaults standardUserDefaults ] boolForKey: sUseYouTubeH264DefaultsKey ];
}

- (void) _convertElementForMP4: (DOMElement*) element
{
    NSString* video_id = [ self _videoId ];
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
    DOMElement* newElement = (DOMElement*) [ self.container cloneNode: NO ];
    
    [ self _convertElementForMP4: newElement ];
    [ self _replaceSelfWithElement: newElement ];
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
	// notify that this ClickToFlash plugin is going away
	[[CTFMenubarMenuController sharedController] unregisterView: self];
	
    if ([self _useH264Version])
        [self _convertToMP4Container];
    else
        [self _convertTypesForFlashContainer];
}

- (void) _convertTypesForFlashContainer
{
    DOMElement *newElement = (DOMElement *)[self.container cloneNode:YES];

    DOMNodeList *nodeList = nil;
    NSUInteger i;

    [self _convertTypesForElement:newElement];

    nodeList = [newElement getElementsByTagName:@"object"];
    for (i = 0; i < nodeList.length; i++) {
        [self _convertTypesForElement:(DOMElement *)[nodeList item:i]];
    }

    nodeList = [newElement getElementsByTagName:@"embed"];
    for (i = 0; i < nodeList.length; i++) {
        [self _convertTypesForElement:(DOMElement *)[nodeList item:i]];
    }
    
    [self _replaceSelfWithElement: newElement];
}

- (void) _replaceSelfWithElement: (DOMElement *)newElement
{
    [ self _abortAlert ];
    
    // Just to be safe, since we are about to replace our containing element
    [[self retain] autorelease];
    
    [self.container.parentNode replaceChild:newElement oldChild:self.container];
    self.container = nil;
}

@synthesize webView = _webView;
@synthesize container = _container;
@synthesize host = _host;
@synthesize baseURL = _baseURL;

@end

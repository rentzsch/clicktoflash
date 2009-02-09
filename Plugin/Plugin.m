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
#import "NSBezierPath-RoundedRectangle.h"
#import "CTFMenubarMenuController.h"

#define LOGGING_ENABLED 0


    // MIME types
static NSString *sFlashOldMIMEType = @"application/x-shockwave-flash";
static NSString *sFlashNewMIMEType = @"application/futuresplash";

    // NSUserDefaults keys
static NSString *sHostWhitelistDefaultsKey = @"ClickToFlash_whitelist";
static NSString *sAllowSifrDefaultsKey = @"ClickToFlash_allowSifr";
static NSString *sUseYouTubeH264DefaultsKey = @"ClickToFlash_useYouTubeH264";

    // NSNotification names
static NSString *sCTFWhitelistAdditionMade = @"CTFWhitelistAdditionMade";


@interface CTFClickToFlashPlugin (Internal)
- (void) _convertTypesForFlashContainer;
- (void) _convertTypesForContainer;
- (void) _replaceSelfWithElement: (DOMElement*) newElement;
- (void) _drawBackground;
- (BOOL) _isOptionPressed;
- (BOOL) _isHostWhitelisted;
- (NSMutableArray *)_hostWhitelist;
- (void) _alertDone;
- (void) _abortAlert;
- (void) _addHostToWhitelist;
- (void) _removeHostFromWhitelist;
- (void) _askToAddCurrentSiteToWhitelist;
- (void) _whitelistAdditionMade: (NSNotification*) notification;
- (void) _loadContent: (NSNotification*) notification;
- (void) _loadContentForWindow: (NSNotification*) notification;
- (BOOL) _hasH264Version;
- (BOOL) _useH264Version;
- (void) _convertToMP4Container;
- (NSDictionary*) _flashVarDictionary: (NSString*) flashvarString;
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

- (void) _migrateWhitelist
{
    // Migrate from the old location to the new location.  We'll leave
    // this in for a couple builds (being added for 1.4) and then remove
    // it assuming those who care would have upgraded.
    
    NSUserDefaults* defaults = [ NSUserDefaults standardUserDefaults ];
    
    id oldWhitelist = [ defaults objectForKey: @"ClickToFlash.whitelist" ];
    if( oldWhitelist ) {
        id newWhitelist = [ defaults objectForKey: sHostWhitelistDefaultsKey ];
        
        if( newWhitelist == nil ) {
            [ defaults setObject: oldWhitelist forKey: sHostWhitelistDefaultsKey ];
            [ defaults removeObjectForKey: @"ClickToFlash.whitelist"];
        }
    }
}

- (id) initWithArguments:(NSDictionary *)arguments
{
    self = [super init];
    if (self) {
        self.container = [arguments objectForKey:WebPlugInContainingElementKey];
        
        [self _migrateWhitelist];
        
        BOOL loadFromWhiteList = NO;
        
        // Get URL and test against the whitelist
        
        NSURL *base = [arguments objectForKey:WebPlugInBaseURLKey];
        if (base) {
            self.host = [base host];
            if ([self _isHostWhitelisted]) {
                loadFromWhiteList = true;
            }
        }
        
        // Check for sIFR - http://www.mikeindustries.com/sifr/
        
        NSString* classValue = [[arguments objectForKey: WebPlugInAttributesKey] objectForKey: @"class"];
        NSString* sifrValue = [[arguments objectForKey: WebPlugInAttributesKey] objectForKey: @"sifr"];
        if ([classValue isEqualToString: @"sIFR-flash"] || (sifrValue && [sifrValue boolValue])) {
            if([[NSUserDefaults standardUserDefaults] boolForKey: sAllowSifrDefaultsKey])
                loadFromWhiteList = true;
            else
                _isSifr = true;
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
        
        // Set up contextual menu
        
        if (![NSBundle loadNibNamed:@"ContextualMenu" owner:self])
            NSLog(@"Could not load conextual menu plugin");
            // NOTE [tgaul]: we could save memory by not loading the context menu until it was
            // needed by overriding menuForEvent and returning it there.
        
        if ([self _hasH264Version]) {
            [[self menu] insertItemWithTitle: NSLocalizedString( @"Load H.264", "Load H.264 context menu item" )
                                      action: @selector( loadH264: ) keyEquivalent: @"" atIndex: 1];
            [[[self menu] itemAtIndex: 1] setTarget: self];
        }
        
        // Set up main menus
        
		[ CTFMenubarMenuController sharedController ];	// trigger the menu items to be added
		
        // Set tooltip
        
        NSDictionary *attributes = [arguments objectForKey:WebPlugInAttributesKey];
        if (attributes != nil) {
            NSString *src = [attributes objectForKey:@"src"];
            if (src)
                [self setToolTip:src];
            else {
                src = [attributes objectForKey:@"data"];
                if (src)
                    [self setToolTip:src];
            }
        }
        
        // Observe various things:
        
        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        
            // Observe for additions to the whitelist (can't use KVO due to the dot in the pref key):
        [center addObserver: self 
                   selector: @selector( _whitelistAdditionMade: ) 
                       name: sCTFWhitelistAdditionMade 
                     object: nil ];
		
		[center addObserver: self 
				   selector: @selector( _loadContent: ) 
					   name: kCTFLoadAllFlashViews 
					 object: nil ];
		
		[center addObserver: self 
				   selector: @selector( _loadContentForWindow: ) 
					   name: kCTFLoadFlashViewsForWindow 
					 object: nil ];
    }

    return self;
}

- (void) dealloc
{
    [self _abortAlert];        // to be on the safe side
    
    self.container = nil;
    self.host = nil;
    [_flashVars release];
    [[NSNotificationCenter defaultCenter] removeObserver: self];

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

- (void)mouseEntered:(NSEvent *)event
{
    mouseInside = YES;
    [self setNeedsDisplay:YES];
}
- (void)mouseExited:(NSEvent *)event
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

- (BOOL) _isOptionPressed;
{
    BOOL isOptionPressed = (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0);
    return isOptionPressed;
}

- (void) _alertDone
{
	[ _activeAlert release ];
	_activeAlert = nil;
}

- (void) _abortAlert
{
	if( _activeAlert ) {
		[ NSApp endSheet: [ _activeAlert window ] returnCode: NSAlertSecondButtonReturn ];
		[ self _alertDone ];
	}
}

- (void) _askToAddCurrentSiteToWhitelist
{
    NSString *title = NSLocalizedString(@"Always load Flash for this site?", @"Always load Flash for this site? alert title");
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Add %@ to the whitelist?", @"Add <sitename> to the whitelist? alert message"), self.host];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"Add to Whitelist", @"Add to Whitelist button")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(addToWhitelistAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
    _activeAlert = alert;
}

- (void)addToWhitelistAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertFirstButtonReturn)
    {
        [self _addHostToWhitelist];
    }

    [ self _alertDone ];
}

- (BOOL) _isHostWhitelisted
{
    NSArray *hostWhitelist = [[NSUserDefaults standardUserDefaults] stringArrayForKey:sHostWhitelistDefaultsKey];
    return hostWhitelist && [hostWhitelist containsObject:self.host];
}

- (NSMutableArray *)_hostWhitelist
{
    NSMutableArray *hostWhitelist = [[[[NSUserDefaults standardUserDefaults] stringArrayForKey:sHostWhitelistDefaultsKey] mutableCopy] autorelease];
    if (hostWhitelist == nil) {
        hostWhitelist = [NSMutableArray array];
    }
    return hostWhitelist;
}

- (void) _addHostToWhitelist
{
    NSMutableArray *hostWhitelist = [self _hostWhitelist];
    [hostWhitelist addObject:self.host];
    [[NSUserDefaults standardUserDefaults] setObject:hostWhitelist forKey:sHostWhitelistDefaultsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName: sCTFWhitelistAdditionMade object: self];
}

- (void) _removeHostFromWhitelist
{
    NSMutableArray *hostWhitelist = [self _hostWhitelist];
    [hostWhitelist removeObject:self.host];
    [[NSUserDefaults standardUserDefaults] setObject:hostWhitelist forKey:sHostWhitelistDefaultsKey];
}

- (void) _whitelistAdditionMade: (NSNotification*) notification
{
	if ([self _isHostWhitelisted])
		[self _convertTypesForContainer];
}

#pragma mark -
#pragma mark Contextual menu

- (NSString*) addToWhiteListMenuTitle
{
    return [NSString stringWithFormat:NSLocalizedString(@"Add %@ to Whitelist", @"Add <sitename> to Whitelist menu title"), self.host];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL enabled = YES;
    SEL action = [menuItem action];
    if (action == @selector(addToWhitelist:))
    {
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

- (IBAction)addToWhitelist:(id)sender;
{
    if ([self _isHostWhitelisted])
        return;
    
    [self _addHostToWhitelist];
}

- (IBAction)removeFromWhitelist:(id)sender;
{
    if (![self _isHostWhitelisted])
        return;
    
    NSString *title = NSLocalizedString(@"Stop always loading Flash?", @"Stop always loading Flash? alert title");
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Remove %@ from the whitelist?", @"Remove %@ from the whitelist? alert message"), self.host];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"Remove from Whitelist", @"Remove from Whitelist button")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(removeFromWhitelistAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
    _activeAlert = alert;
}

- (void)removeFromWhitelistAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertFirstButtonReturn)
    {
        [self _removeHostFromWhitelist];
    }
    
    [ self _alertDone ];
}

- (IBAction)editWhitelist:(id)sender;
{
	[ [ CTFMenubarMenuController sharedController ] showSettingsWindow: self ];
}

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

#pragma mark -
#pragma mark Drawing

- (NSString*) badgeLabelText
{
    if( [ self _useH264Version ] )
        return NSLocalizedString( @"H.264", @"H.264 badge text" );
    else if( [ self _hasH264Version ] )
        return NSLocalizedString( @"YouTube", @"YouTube badge text" );
    else if( _isSifr )
        return NSLocalizedString( @"sIFR Flash", @"sIFR Flash badge text" );
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
	
	NSColor* badgeColor = [ NSColor colorWithCalibratedWhite: 1.0 alpha: pressed ? 0.40 : 0.25 ];
	
	NSDictionary* attrs = [ NSDictionary dictionaryWithObjectsAndKeys: 
						   [ NSFont boldSystemFontOfSize: 20 ], NSFontAttributeName,
						   [ NSNumber numberWithInt: -1 ], NSKernAttributeName,
						   badgeColor, NSForegroundColorAttributeName,
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
	
	CGContextSetBlendMode([[NSGraphicsContext currentContext] graphicsPort], kCGBlendModeDifference);
	
	NSAffineTransform* xform = [ NSAffineTransform transform ];
	[ xform translateXBy: NSWidth( bounds ) / 2 yBy: NSHeight( bounds ) / 2 ];
	[ xform scaleBy: scaleFactor ];
	if( rotate )
		[ xform rotateByDegrees: 90 ];
	[ xform concat ];
	
	// Draw everything at full size, centered on the origin.
	
	NSPoint loc = { -strSize.width / 2, -strSize.height / 2 };
	NSRect borderRect = NSMakeRect( loc.x - kFrameXInset, loc.y - kFrameYInset, w, h );
	
	[ str drawAtPoint: loc withAttributes: attrs ];

	NSBezierPath* path = bezierPathWithRoundedRectCornerRadius( borderRect, 4 );
	[ badgeColor set ];
	[ path setLineWidth: 3 ];
	[ path stroke ];
	
	// Now restore the graphics state:
	
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
    
    NSEnumerator* objEnum = [ args objectEnumerator ];
    NSString* oneArg;
    while( oneArg = [ objEnum nextObject ] ) {
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


@synthesize container = _container;
@synthesize host = _host;

@end

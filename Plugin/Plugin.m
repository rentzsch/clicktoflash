/*

The MIT License

Copyright (c) 2008 Click to Flash Developers

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

@interface NSBezierPath(MRGradientFill) 
-(void)linearGradientFill:(NSRect)thisRect 
			   startColor:(NSColor *)startColor 
				 endColor:(NSColor *)endColor;
@end

static NSString *sFlashOldMIMEType = @"application/x-shockwave-flash";
static NSString *sFlashNewMIMEType = @"application/futuresplash";
static NSString *sHostWhitelistDefaultsKey = @"ClickToFlash.whitelist";

@interface CTFClickToFlashPlugin (Internal)
- (NSColor *) _backgroundColorOfElement:(DOMElement *)element;
- (void) _convertTypesForContainer;
- (void) _drawBackground;
- (BOOL) _isHostWhitelisted;
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
        [self setContainer:[arguments objectForKey:WebPlugInContainingElementKey]];
    
        NSURL *base = [arguments objectForKey:WebPlugInBaseURLKey];
        if (base) {
            [self setHost:[base host]];
            if ([self _isHostWhitelisted]) {
                [self performSelector:@selector(_convertTypesForContainer) withObject:nil afterDelay:0];
            }
        }

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
    }

    return self;
}


- (void) dealloc
{
    [self setContainer:nil];
    [self setHost:nil];
    [super dealloc];
}


- (void) drawRect:(NSRect)rect
{
    [self _drawBackground];
}


- (BOOL) acceptsFirstMouse
{
    return YES;
}


- (void) mouseDown:(NSEvent *)event
{
    if ([self host] && (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask) && ![self _isHostWhitelisted]) {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Add %@ to the white list?", @"Add %@ to the white list?"), [self host]];
        int val = NSRunAlertPanel(title,
                                  NSLocalizedString(@"Always load flash for this site?", @"Always load flash for this site?"),
                                  @"Always Load", @"Don't Load", nil);
        if (!val) {
            return;
        }
        
        NSMutableArray *hostWhitelist = [[[[NSUserDefaults standardUserDefaults] stringArrayForKey:sHostWhitelistDefaultsKey] mutableCopy] autorelease];
        if (hostWhitelist) {
            [hostWhitelist addObject:[self host]];
        } else {
            hostWhitelist = [NSMutableArray arrayWithObject:[self host]];
        }
        [[NSUserDefaults standardUserDefaults] setObject:hostWhitelist forKey:sHostWhitelistDefaultsKey];
    }
    
    [self _convertTypesForContainer];
}

- (BOOL) _isHostWhitelisted
{
    NSArray *hostWhitelist = [[NSUserDefaults standardUserDefaults] stringArrayForKey:sHostWhitelistDefaultsKey];
    return hostWhitelist && [hostWhitelist containsObject:[self host]];
}


#pragma mark -
#pragma mark Drawing

- (void) _drawBackground
{
    NSRect selfBounds  = [self bounds];

    NSRect fillRect   = NSInsetRect(selfBounds, 1.0, 1.0);
    NSRect strokeRect = selfBounds;

    NSColor *startingColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.15];
    NSColor *endingColor = [NSColor colorWithDeviceWhite:0.0 alpha:0.15];

    // Draw stroke
    [NSBezierPath setDefaultLineWidth:2.0];
    [NSBezierPath setDefaultLineCapStyle:NSRoundLineCapStyle];
	[NSBezierPath setDefaultLineJoinStyle:NSRoundLineJoinStyle];
	
	NSBezierPath *path = [NSBezierPath bezierPath];	
	[path appendBezierPathWithRect:fillRect];
	[path addClip];
	
	//Draw Gradient
	[path linearGradientFill:fillRect 
				startColor:[NSColor lightGrayColor]
				  endColor:[NSColor darkGrayColor]];
	
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.50] set];
	[path stroke];

	// Draw an image on top to make it insanely obvious that this is clickable Flash.
    NSString *containerImageName = [[NSBundle bundleForClass:[self class]] pathForResource:@"ContainerImage" ofType:@"png"];  
    NSImage *containerImage = [[[NSImage alloc] initWithContentsOfFile:containerImageName] autorelease];
	
    NSSize viewSize  = fillRect.size;
    NSSize imageSize = [containerImage size];    
	
    NSPoint viewCenter;
    viewCenter.x = viewSize.width  * 0.50;
    viewCenter.y = viewSize.height * 0.50;
    
    NSPoint imageOrigin = viewCenter;
    imageOrigin.x -= imageSize.width  * 0.50;
    imageOrigin.y -= imageSize.height * 0.50;
    
    NSRect destinationRect;
    destinationRect.origin = imageOrigin;
    destinationRect.size = imageSize;
    
    // Draw the image centered in the view
    [containerImage drawInRect:destinationRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}


#pragma mark -
#pragma mark DOM Conversion

- (void) _convertTypesForElement:(DOMElement *)element
{
    NSString *type = [element getAttribute:@"type"];

    if ([type isEqualToString:sFlashOldMIMEType]) {
        [element setAttribute:@"type" value:sFlashNewMIMEType];
    }
}


- (void) _convertTypesForContainer
{
    DOMElement *newElement = (DOMElement *)[[self container] cloneNode:YES];

    DOMNodeList *nodeList;
    unsigned i;

    [self _convertTypesForElement:newElement];

    nodeList = [newElement getElementsByTagName:@"object"];
    for (i = 0; i < [nodeList length]; i++) {
        [self _convertTypesForElement:(DOMElement *)[nodeList item:i]];
    }

    nodeList = [newElement getElementsByTagName:@"embed"];
    for (i = 0; i < [nodeList length]; i++) {
        [self _convertTypesForElement:(DOMElement *)[nodeList item:i]];
    }

    // Just to be safe, since we are about to replace our containing element
    [[self retain] autorelease];
    
    [[[self container] parentNode] replaceChild:newElement oldChild:[self container]];
    [self setContainer:nil];
}


- (DOMElement *) container
{
	return _container;
}

- (void) setContainer:(DOMElement *)newContainer
{
	[_container autorelease];
	_container = [newContainer retain];
}

- (NSString *) host
{
	return _host;
}

- (void) setHost:(NSString *)newHost
{
	[_host autorelease];
	_host = [newHost retain];
}
@end

//### globals
float	start_red,
start_green,
start_blue,
start_alpha;
float	end_red,
end_green,
end_blue,
end_alpha;
float	d_red,
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
	int k;
	CGFunctionRef function;
	CGFunctionRef (*getFunction)(CGColorSpaceRef);
	CGShadingRef (*getShading)(CGColorSpaceRef, CGFunctionRef);
	
	// get my context
	CGContextRef currentContext = 
		(CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	
	
	NSColor *s = [startColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	NSColor *e = [endColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	// set up colors for gradient
	start_red		= [s redComponent];
	start_green		= [s greenComponent];
	start_blue		= [s blueComponent];
	start_alpha		= [s alphaComponent];
	
	end_red			= [e redComponent];
	end_green		= [e greenComponent];
	end_blue		= [e blueComponent];
	end_alpha		= [e alphaComponent];
	
	d_red		= absDiff(end_red, start_red);
	d_green		= absDiff(end_green, start_green);
	d_blue		= absDiff(end_blue, start_blue);
	d_alpha		= absDiff(end_alpha ,start_alpha);
	
	
	// draw gradient
	colorspace = CGColorSpaceCreateDeviceRGB();
	
    size_t components;
    static const float domain[2] = { 0.0, 1.0 };
    static const float range[10] = { 0, 1, 0, 1, 0, 1, 0, 1, 0, 1 };
    static const CGFunctionCallbacks callbacks = { 0, &evaluate, NULL };
	
    components = 1 + CGColorSpaceGetNumberOfComponents(colorspace);
    function =  CGFunctionCreate((void *)components, 1, domain, components,
								 range, &callbacks);
	
	// function = getFunction(colorspace);	
	startPoint.x=0;
	startPoint.y=thisRect.origin.y;
	endPoint.x=0;
	endPoint.y=NSMaxY(thisRect);
	
	
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

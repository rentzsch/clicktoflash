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
        self.container = [arguments objectForKey:WebPlugInContainingElementKey];
    
        NSURL *base = [arguments objectForKey:WebPlugInBaseURLKey];
        if (base) {
            self.host = [base host];
            if ([self _isHostWhitelisted]) {
                [self performSelector:@selector(_convertTypesForContainer) withObject:nil afterDelay:0];
            }
        }

        NSDictionary *attributes = [arguments objectForKey:WebPlugInAttributesKey];
        if (arguments) {
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
    self.container = nil;
    self.host = nil;
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
    if (self.host && (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask) && ![self _isHostWhitelisted]) {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Add %@ to the white list?", @"Add %@ to the white list?"), self.host];
        int val = NSRunAlertPanel(title,
                                  NSLocalizedString(@"Always load flash for this site?", @"Always load flash for this site?"),
                                  @"Always Load", @"Don't Load", nil);
        if (!val) {
            return;
        }
        
        NSMutableArray *hostWhitelist = [[[[NSUserDefaults standardUserDefaults] stringArrayForKey:sHostWhitelistDefaultsKey] mutableCopy] autorelease];
        if (hostWhitelist) {
            [hostWhitelist addObject:self.host];
        } else {
            hostWhitelist = [NSMutableArray arrayWithObject:self.host];
        }
        [[NSUserDefaults standardUserDefaults] setObject:hostWhitelist forKey:sHostWhitelistDefaultsKey];
    }
    
    [self _convertTypesForContainer];
}

- (BOOL) _isHostWhitelisted
{
    NSArray *hostWhitelist = [[NSUserDefaults standardUserDefaults] stringArrayForKey:sHostWhitelistDefaultsKey];
    return hostWhitelist && [hostWhitelist containsObject:self.host];
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
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
    
    // Draw fill
    [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:fillRect] angle:270.0];

    // Draw stroke
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.50] set];
    [NSBezierPath setDefaultLineWidth:2.0];
    [NSBezierPath setDefaultLineCapStyle:NSSquareLineCapStyle];
    [[NSBezierPath bezierPathWithRect:strokeRect] stroke];

    [gradient release];
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
    DOMElement *newElement = (DOMElement *)[self.container cloneNode:YES];

    DOMNodeList *nodeList;
    unsigned i;

    [self _convertTypesForElement:newElement];

    nodeList = [newElement getElementsByTagName:@"object"];
    for (i = 0; i < nodeList.length; i++) {
        [self _convertTypesForElement:(DOMElement *)[nodeList item:i]];
    }

    nodeList = [newElement getElementsByTagName:@"embed"];
    for (i = 0; i < nodeList.length; i++) {
        [self _convertTypesForElement:(DOMElement *)[nodeList item:i]];
    }

    // Just to be safe, since we are about to replace our containing element
    [[self retain] autorelease];
    
    [self.container.parentNode replaceChild:newElement oldChild:self.container];
    self.container = nil;
}


@synthesize container = _container;
@synthesize host = _host;

@end

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

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class CTFKiller;

@interface CTFClickToFlashPlugin : NSView <WebPlugInViewFactory> {
	NSArray *defaultWhitelist;
	
    DOMElement *_container;
    NSString *_host;
    NSDictionary* _flashVars;
    id trackingArea;
    NSAlert* _activeAlert;
    BOOL mouseIsDown;
    BOOL mouseInside;
    BOOL _isLoadingFromWhitelist;
    BOOL _fromYouTube;
    BOOL _fromFlickr;
	WebView *_webView;
	NSString *_baseURL;
	NSDictionary *_attributes;
	NSDictionary *_originalOpacityAttributes;
	NSString *_src;

	BOOL _contextMenuIsVisible;
	NSTimer *_delayingTimer;
	
	CTFKiller * killer;
}

+ (NSView *)plugInViewWithArguments:(NSDictionary *)arguments;

- (void) revertToOriginalOpacityAttributes;
- (void) prepareForConversion;

- (NSMenuItem*) addContextualMenuItemWithTitle: (NSString*) title action: (SEL) selector;
- (NSMenuItem *) addContextualMenuItemWithTitle: (NSString*) title action: (SEL) selector target:(id) target;

- (IBAction)loadFlash:(id)sender;
- (IBAction)loadAllOnPage:(id)sender;
- (IBAction)removeFlash: (id) sender;
- (IBAction)hideFlash: (id) sender;
- (void) convertTypesForContainer;

+ (NSDictionary*) flashVarDictionary: (NSString*) flashvarString;
+ (NSString *)launchedAppBundleIdentifier;
- (void) browseToURLString: (NSString*) URLString;
- (void) downloadURLString: (NSString*) URLString;

- (BOOL) isConsideredInvisible;

- (id) initWithArguments:(NSDictionary *)arguments;
- (void)_migratePrefsToExternalFile;
- (void)_uniquePrefsFileWhitelist;
- (void) _addApplicationWhitelistArrayToPrefsFile;

- (CTFKiller *) killer;
- (void)setKiller:(CTFKiller *)newKiller;
- (DOMElement *)container;
- (void)setContainer:(DOMElement *)newValue;
- (NSString *)host;
- (void)setHost:(NSString *)newValue;
- (WebView *)webView;
- (void)setWebView:(WebView *)newValue;
- (NSString *)baseURL;
- (void)setBaseURL:(NSString *)newValue;
- (NSDictionary *)attributes;
- (void)setAttributes:(NSDictionary *)newValue;
- (NSDictionary *)originalOpacityAttributes;
- (void)setOriginalOpacityAttributes:(NSDictionary *)newValue;
- (NSString *)src;
- (void)setSrc:(NSString *)newValue;
@end

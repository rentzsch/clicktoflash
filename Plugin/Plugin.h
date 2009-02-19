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


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface CTFClickToFlashPlugin : NSView <WebPlugInViewFactory> {
    DOMElement *_container;
    NSString *_host;
    NSDictionary* _flashVars;
    NSTrackingArea *trackingArea;
    NSAlert* _activeAlert;
    NSString* _badgeText;
    BOOL mouseIsDown;
    BOOL mouseInside;
    BOOL _isLoadingFromWhitelist;
    BOOL _fromYouTube;
	WebView *_webView;
	NSUInteger _sifrVersion;
	NSString *_baseURL;
}

+ (NSView *)plugInViewWithArguments:(NSDictionary *)arguments;

- (id) initWithArguments:(NSDictionary *)arguments;

@property (nonatomic, retain) DOMElement *container;
@property (nonatomic, retain) NSString *host;
@property (nonatomic, retain) WebView *webView;
@property (retain) NSString *baseURL;

- (IBAction)loadFlash:(id)sender;
- (IBAction)loadH264:(id)sender;
- (IBAction)loadAllOnPage:(id)sender;

- (BOOL) isConsideredInvisible;

- (void) _convertTypesForContainer;

@end

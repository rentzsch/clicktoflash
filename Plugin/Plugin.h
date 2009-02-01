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

@class CTFWhitelistWindowController;

@interface CTFClickToFlashPlugin : NSView <WebPlugInViewFactory> {
    DOMElement *_container;
    NSString *_host;
    CTFWhitelistWindowController *_whitelistWindowController;
    NSTrackingArea *trackingArea;
    BOOL mouseIsDown;
    BOOL mouseInside;
}

+ (NSView *)plugInViewWithArguments:(NSDictionary *)arguments;

- (id) initWithArguments:(NSDictionary *)arguments;

@property (nonatomic, retain) DOMElement *container;
@property (nonatomic, retain) NSString *host;
@property (readonly, nonatomic, retain) NSString *addToWhiteListMenuTitle;

- (IBAction)addToWhitelist:(id)sender;
- (IBAction)removeFromWhitelist:(id)sender;
- (IBAction)editWhitelist:(id)sender;
- (IBAction)loadFlash:(id)sender;

@end

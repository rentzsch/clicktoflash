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

#import "CTFsIFRSupport.h"

typedef enum {
	CTFSifrModeDoNothing	= 0, 
	CTFSifrModeAutoLoadSifr	= 1, 
	CTFSifrModeDeSifr		= 2
} CTFSifrMode;

static NSString *sSifrModeDefaultsKey = @"ClickToFlash_sifrMode";

static NSString *sSifr2Test		= @"sIFR != null && typeof sIFR == \"function\"";
static NSString *sSifr3Test		= @"sIFR != null && typeof sIFR == \"object\"";
static NSString *sSifrAddOnTest	= @"sIFR.rollback == null || typeof sIFR.rollback != \"function\"";
static NSString *sSifrRollbackJS	= @"sIFR.rollback()";
static NSString *sSifr2AddOnJSFilename = @"sifr2-addons";
static NSString *sSifr3AddOnJSFilename = @"sifr3-addons";

@implementation CTFClickToFlashPlugin( sIFRSupport )

- (NSUInteger) _sifrVersionInstalled
{	
	// get the container's WebView
	WebView *sifrWebView = [self webView];
	NSUInteger version = 0;
    
	if (sifrWebView) {
		if ([[sifrWebView stringByEvaluatingJavaScriptFromString: sSifr2Test] isEqualToString: @"true"])        // test for sIFR v.2
			version = 2;
		else if([[sifrWebView stringByEvaluatingJavaScriptFromString: sSifr3Test] isEqualToString: @"true"])    // test for sIFR v.3
			version = 3;
	}
	
	return version;
}

- (BOOL) _shouldDeSIFR
{
    if ([[NSUserDefaults standardUserDefaults] integerForKey: sSifrModeDefaultsKey] == CTFSifrModeDeSifr) {
        _sifrVersion = [self _sifrVersionInstalled];
        
        if( _sifrVersion != 0 )
            return YES;
    }
    
    return NO;
}

- (BOOL) _shouldAutoLoadSIFR
{
    return [[NSUserDefaults standardUserDefaults] integerForKey: sSifrModeDefaultsKey] == CTFSifrModeAutoLoadSifr;
}        

- (void) _disableSIFR
{	
	// get the container's WebView
	WebView *sifrWebView = [self webView];
	
	// if sifr add-ons are not installed, load version-appropriate version into page
	if ([[sifrWebView stringByEvaluatingJavaScriptFromString: sSifrAddOnTest] isEqualToString: @"true"]) {
		NSBundle *clickBundle = [NSBundle bundleForClass: [self class]];
		
		NSString *jsFileName = _sifrVersion == 2 ? sSifr2AddOnJSFilename : sSifr3AddOnJSFilename;
		
		NSString *addOnPath = [clickBundle pathForResource: jsFileName ofType: @"js"];
		
		if( addOnPath ) {
            NSStringEncoding enc ;
			NSString *sifrAddOnJS = [NSString stringWithContentsOfFile: addOnPath usedEncoding: &enc error: nil];
			
			if (sifrAddOnJS && ![sifrAddOnJS isEqualToString: @""])
				[[sifrWebView windowScriptObject] evaluateWebScript: sifrAddOnJS];
		}
	}
	
	// implement rollback
	[[sifrWebView windowScriptObject] evaluateWebScript: sSifrRollbackJS];
}

- (BOOL) _isSIFRText: (NSDictionary*) arguments
{
    // Check for sIFR - http://www.mikeindustries.com/sifr/
    
    NSString* classValue = [[arguments objectForKey: WebPlugInAttributesKey] objectForKey: @"class"];
    NSString* sifrValue = [[arguments objectForKey: WebPlugInAttributesKey] objectForKey: @"sifr"];
   
    return [classValue isEqualToString: @"sIFR-flash"] || (sifrValue && [sifrValue boolValue]);
}

@end

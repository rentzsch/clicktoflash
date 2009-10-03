//
//  CTFKillerSiFR.m
//  ClickToFlash
//
//  Created by  Sven on 02.10.09.
//  Copyright 2009 earthlingsoft. All rights reserved.
//

#import "CTFKillersIFR.h"
#import "CTFUtilities.h"
#import "CTFUserDefaultsController.h"
#import "CTFPreferencesDictionary.h"
#import "Plugin.h"
#import <WebKit/WebKit.h>

typedef enum {
	CTFSifrModeDoNothing	= 0, 
	CTFSifrModeAutoLoadSifr	= 1, 
	CTFSifrModeDeSifr		= 2
} CTFSifrMode;

static NSString *sSifrModeDefaultsKey = @"sifrMode";

static NSString *sSifr2Test		= @"sIFR != null && typeof sIFR == \"function\"";
static NSString *sSifr3Test		= @"sIFR != null && typeof sIFR == \"object\"";
static NSString *sSifrAddOnTest	= @"sIFR.rollback == null || typeof sIFR.rollback != \"function\"";
static NSString *sSifrRollbackJS	= @"sIFR.rollback()";
static NSString *sSifr2AddOnJSFilename = @"sifr2-addons";
static NSString *sSifr3AddOnJSFilename = @"sifr3-addons";



@implementation CTFKillerSIFR


# pragma mark CTFKiller subclassing

+ (BOOL) canHandleFlashAtURL: (NSURL*) theURL src: (NSString*) theSrc attributes: (NSDictionary*) attributes forPlugin:(CTFClickToFlashPlugin*) thePlugin {
	return [CTFKillerSIFR isSIFRText: attributes];
}
	
+ (BOOL) isSIFRText: (NSDictionary*) attributes
{
    // Check for sIFR - http://www.mikeindustries.com/sifr/
    
    NSString* classValue = [attributes objectForKey: @"class"];
    NSString* sifrValue = [attributes objectForKey: @"sifr"];
	
    return [classValue isEqualToString: @"sIFR-flash"] || (sifrValue && [sifrValue boolValue]);
}


	
- (void) setup {
	if ([CTFKillerSIFR shouldAutoLoadSIFR]) {
//		_isLoadingFromWhitelist = YES;
		[[self plugin] convertTypesForContainer];
	}
	else if ([self shouldDeSIFR]) {
//		_isLoadingFromWhitelist = YES;
		[self performSelector:@selector(disableSIFR) withObject:nil afterDelay:0];
	}

}


- (NSString*) badgeLabelText {
	return CtFLocalizedString( @"sIFR Flash", @"sIFR Flash badge text" );
}


- (void) addPrincipalMenuItemToContextualMenu {
	[[self plugin] addContextualMenuItemWithTitle: CtFLocalizedString( @"Don't use Text Replacement", @"Don't use Text Replacement (CTFKillerSIFR)" )	
										   action: @selector( disableSIFR )
										   target: self ];
}


- (void) addAdditionalMenuItemsForContextualMenu {
}




#pragma mark Support Methods (formerly CTFsIFRSupport)

- (NSUInteger) sifrVersionInstalled {	
	// get the container's WebView
	WebView *sifrWebView = [[self plugin] webView];
	NSUInteger version = 0;
    
	if (sifrWebView) {
		if ([[sifrWebView stringByEvaluatingJavaScriptFromString: sSifr2Test] isEqualToString: @"true"])        // test for sIFR v.2
			version = 2;
		else if([[sifrWebView stringByEvaluatingJavaScriptFromString: sSifr3Test] isEqualToString: @"true"])    // test for sIFR v.3
			version = 3;
	}
	
	return version;
}


- (BOOL) shouldDeSIFR {
    BOOL result = NO;

	if ([[CTFUserDefaultsController standardUserDefaults] integerForKey: sSifrModeDefaultsKey] == CTFSifrModeDeSifr) {
		result = ([self sifrVersionInstalled] != 0);
    }
    
    return result;
}


+ (BOOL) shouldAutoLoadSIFR {
    return [[CTFUserDefaultsController standardUserDefaults] integerForKey: sSifrModeDefaultsKey] == CTFSifrModeAutoLoadSifr;
}        


- (void) disableSIFR {	
	// get the container's WebView
	WebView *sifrWebView = [[self plugin] webView];
	
	// if sifr add-ons are not installed, load version-appropriate version into page
	if ([[sifrWebView stringByEvaluatingJavaScriptFromString: sSifrAddOnTest] isEqualToString: @"true"]) {
		NSBundle *clickBundle = [NSBundle bundleForClass: [self class]];
		
		NSString *jsFileName = sifrVersion == 2 ? sSifr2AddOnJSFilename : sSifr3AddOnJSFilename;
		
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


@end

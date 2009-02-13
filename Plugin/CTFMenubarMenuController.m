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

#import "CTFMenubarMenuController.h"
#import "CTFWhitelistWindowController.h"
#import <OSAKit/OSAKit.h>
#import <WebKit/WebKit.h>


NSString* kCTFLoadAllFlashViews = @"CTFLoadAllFlashViews";
NSString* kCTFLoadFlashViewsForWindow = @"CTFLoadFlashViewsForWindow";
NSString* kCTFLoadInvisibleFlashViewsForWindow = @"CTFLoadInvisibleFlashViewsForWindow";
NSString *sCTFNewViewNotification = @"CTFNewFlashView";
NSString *sCTFDestroyedViewNotification = @"CTFDestroyedFlashView";
NSUInteger maxInvisibleDimension = 50;

static CTFMenubarMenuController* sSingleton = nil;

static NSString* kApplicationsToInstallMenuInto[] = {
    @"com.apple.Safari",
    nil
};


static NSMenu* appMenu()
{
    return [ [ [ NSApp mainMenu ] itemAtIndex: 0 ] submenu ];
}


@implementation CTFMenubarMenuController


#pragma mark -
#pragma mark Main menu item setup


- (BOOL) shouldLoadMainMenuItemIntoCurrentProcess
{
    NSBundle* appBundle = [ NSBundle mainBundle ];
    NSString* currentAppId = [ appBundle bundleIdentifier ];
    
    if( [ appBundle objectForInfoDictionaryKey: @"ClickToFlashPrefsAppMenuItemIndex" ] != nil )
        return YES;
    
    int i;
    NSString* appId = kApplicationsToInstallMenuInto[ 0 ];
    for( i = 0 ; appId != nil ; appId = kApplicationsToInstallMenuInto[ ++i ] ) {
        if( [ appId isEqualToString: currentAppId ] )
            return YES;
    }
    
    return NO;
}


- (int) applicationMenuPrefsInsertionLocation
{
    NSBundle* appBundle = [ NSBundle mainBundle ];
    NSNumber* indx = [ appBundle objectForInfoDictionaryKey: @"ClickToFlashPrefsAppMenuItemIndex" ];
    if( indx )
        return [ indx intValue ];

	NSMenu* applicationMenu = appMenu();
    int insertLocation = -1, showPrefsItem = -1, lastSeenSep = -1;
    int i, count = [ applicationMenu numberOfItems ];
    for( i = 0 ; i < count ; ++i ) {
        // Put it before the first separator after the preferences item.
        
        NSMenuItem* item = [ applicationMenu itemAtIndex: i ];
        
        if( [ item action ] == @selector( showPreferences: ) )
            showPrefsItem = i;
        
        if( showPrefsItem >= 0 && [ item isSeparatorItem ] ) {
            insertLocation = i;
            break;
        }
    }
    
    if( insertLocation == -1 ) {
        if( showPrefsItem >= 0 )
            insertLocation = showPrefsItem + 1;
        else
            insertLocation = 4;  // didn't find it, assume it's item 3 (the default for most apps)
    }
    
    return insertLocation;
}


#pragma mark -
#pragma mark Lifetime management


- (id) init
{
	if( sSingleton ) {
		[ self release ];
		return sSingleton;
	}
    
	self = [ super init ];
    
	sSingleton = self;
	
	if( self ) {
		if( ! [ NSBundle loadNibNamed: @"MenubarMenu" owner: self ] )
			NSLog( @"ClickToFlash: Could not load menubar menu nib" );
	}
	
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver: self 
			   selector: @selector( _trackNewView: ) 
				   name: sCTFNewViewNotification
				 object: nil ];
	
	[center addObserver: self 
			   selector: @selector( _stopTrackingView: ) 
				   name: sCTFDestroyedViewNotification
				 object: nil ];
	
	return self;
}


- (void) dealloc
{
	[ _whitelistWindowController release ];
    
	[ super dealloc ];
}


- (void) awakeFromNib
{
    if( ![ self shouldLoadMainMenuItemIntoCurrentProcess ] )
        return;
    
	if( !menu ) {
		NSLog( @"ClickToFlash: Could not load menubar menu" );
		return;
	}
    
    // We need a submenu item to wrap this loaded menu:
    
	NSMenuItem* ctfMenuItem = [ [ [ NSMenuItem alloc ] initWithTitle: [ menu title ]
															  action: nil
													   keyEquivalent: @"" ] autorelease ];
	[ ctfMenuItem setSubmenu: menu ];
	
    // Find the location to insert the item:
    
    int insertLocation = [ self applicationMenuPrefsInsertionLocation ];
    
    // Insert the submenu there:
    
	NSMenu* applicationMenu = appMenu();
	
    [ applicationMenu insertItem: ctfMenuItem atIndex: insertLocation ];
}


+ (CTFMenubarMenuController*) sharedController
{
	if( !sSingleton )
		[ [ CTFMenubarMenuController alloc ] init ];
	
	return sSingleton;
}


#pragma mark -
#pragma mark View Management

- (void) _trackNewView: (NSNotification*) notification
{
	NSMutableDictionary *flashViewsDict = nil;
	if ([self flashViews])
		flashViewsDict = [[self flashViews] copy];
	
	if (! flashViewsDict) flashViewsDict = [NSMutableDictionary dictionary];
	
	NSString *newViewBaseURL = [[[notification userInfo] objectForKey:@"baseURL"] absoluteString];
	NSString *newViewSrc = [[notification userInfo] objectForKey:@"src"];
	NSNumber *newViewHeight = [[notification userInfo] objectForKey:@"height"];
	NSNumber *newViewWidth = [[notification userInfo] objectForKey:@"width"];
	id newTarget = [notification object];
	
	NSDictionary *newTargetDict = [NSDictionary dictionaryWithObjectsAndKeys:newTarget,@"target",newViewSrc,@"src",newViewHeight,@"height",newViewWidth,@"width",nil];
	
	NSMutableArray *baseURLArray = [flashViewsDict objectForKey:newViewBaseURL];
	
	if (! baseURLArray) {
		baseURLArray = [NSMutableArray arrayWithObject:newTargetDict];
		[flashViewsDict setObject:baseURLArray forKey:newViewBaseURL];
	} else {
		[baseURLArray addObject:newTargetDict];
	}
	
	[self setFlashViews:flashViewsDict];
	
	// not sure why, but the following lines causes crashes and unexpected behavior
	//[flashViewsDict release];
}

- (void) _stopTrackingView: (NSNotification*) notification
{
	NSMutableDictionary *flashViewsDict = nil;
	if ([self flashViews])
		flashViewsDict = [[self flashViews] copy];
	
	if (! flashViewsDict) flashViewsDict = [NSMutableDictionary dictionary];
	
	NSString *baseURL = [[notification userInfo] objectForKey:@"baseURL"];
	NSMutableArray *baseURLArray = [flashViewsDict objectForKey:baseURL];
	id flashView = [notification object];
	
	if (! baseURLArray) {
		// we're apparently not tracking this view
		return;
	}
	
	NSDictionary *currentDictionary;
	BOOL foundView = NO;
	for (currentDictionary in baseURLArray) {
		if ([currentDictionary objectForKey:@"target"] == flashView) {
			foundView = YES;
			break;
		}
	}
	
	if (foundView) {
		// only do this stuff if we actually find the view we want to stop tracking
		
		[baseURLArray removeObject:currentDictionary];
		if ([baseURLArray count] == 0) [flashViewsDict removeObjectForKey:baseURL];
		[self setFlashViews:flashViewsDict];
	}
}

- (NSString *)_baseURLOfKeyWindow;
{
	// [[NSBundle mainBundle] bundleIdentifier|executablePath|bundlePath] all return stuff for Safari
	// even if called from WebKit
	
	// the following line crashes WebKit, so we can't use the Scripting Bridge until that is fixed
	// SafariApplication *safari = [SBApplication applicationWithProcessIdentifier:getpid()];
	
	NSString *webKitFrameworkBundlePath = [[NSBundle bundleForClass:[WebView class]] bundlePath];
	
	BOOL isWebKit = NO;
	if (! [webKitFrameworkBundlePath hasPrefix:@"/System/Library/Frameworks"]) {
		// we're not using the system version of WebKit, so it's the WebKit app
		isWebKit = YES;
	};
	
	// the following line doesn't seem to work reliably
	// BOOL isWebKit = [[[NSProcessInfo processInfo] arguments] containsObject:@"-WebKitDeveloperExtras"];
	NSString *appString = @"";
	if (isWebKit) {
		appString = @"WebKit";
	} else {
		appString = @"Safari";
	}
	
	NSString *appleScriptSourceString = [NSString stringWithFormat:@"tell application \"%@\"\nURL of current tab of front window\nend tell",appString];
	
	
	// I didn't want to bring OSACrashyScript into this, but I had to; sorry guys, Scripting Bridge
	// just totally crashes WebKit and that's unacceptable
	
	NSDictionary *errorDict = nil;
	OSAScript *browserNameScript = [[OSAScript alloc] initWithSource:appleScriptSourceString];
	NSAppleEventDescriptor *aeDesc = [browserNameScript executeAndReturnError:&errorDict];
	[browserNameScript release];
	
	NSString *baseURL = nil;
	
	if (! errorDict) baseURL = [aeDesc stringValue];
	
	return baseURL;
}

- (BOOL) _atLeastOneFlashViewExists;
{
	NSLog(@"%@",[self flashViews]);
	return ([[[self flashViews] allKeys] count] >= 1);
}


- (BOOL) _flashViewExistsForKeyWindow;
{
	NSString *baseURL = [self _baseURLOfKeyWindow];
	
	// if there's an array for the base URL, there is at least one view
	// with that base URL
	return ([[self flashViews] objectForKey:baseURL] != nil);
}

- (BOOL) _invisibleFlashViewExistsForKeyWindow;
{
	BOOL returnValue = NO;
	NSString *baseURL = [self _baseURLOfKeyWindow];
	
	NSMutableArray *baseURLArray = [[self flashViews] objectForKey:baseURL];
	
	if (baseURLArray) {
		NSDictionary *currentDictionary = nil;
		
		for (currentDictionary in baseURLArray) {
			NSUInteger height = [[currentDictionary objectForKey:@"height"] intValue];
			NSUInteger width = [[currentDictionary objectForKey:@"width"] intValue];
			
			if ((height <= maxInvisibleDimension) && (width <= maxInvisibleDimension)) {
				returnValue = YES;
				break;
			}
		}
	}
	
	return returnValue;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	BOOL returnValue = YES;
	
	if ([item action] == @selector(loadAllFlash:)) {
		returnValue = [self _atLeastOneFlashViewExists];
	} else if ([item action] == @selector(loadKeyWindowFlash:)) {
		returnValue = [self _flashViewExistsForKeyWindow];
	} else if ([item action] == @selector(loadKeyWindowInvisibleFlash:)) {
		returnValue = [self _invisibleFlashViewExistsForKeyWindow];
	}
	
	return returnValue;
}

#pragma mark -
#pragma mark Actions


- (void) loadFlashForWindow: (NSWindow*) window
{
    [ [ NSNotificationCenter defaultCenter ] postNotificationName: kCTFLoadFlashViewsForWindow 
                                                           object: window ];
}


- (void) loadInvisibleFlashForWindow: (NSWindow*) window
{
    [ [ NSNotificationCenter defaultCenter ] postNotificationName: kCTFLoadInvisibleFlashViewsForWindow 
                                                           object: window ];
}


- (IBAction) loadAllFlash: (id) sender
{
	[ [ NSNotificationCenter defaultCenter ] postNotificationName: kCTFLoadAllFlashViews 
														   object: self ];
}


- (IBAction) loadKeyWindowFlash: (id) sender
{
	NSWindow* window = [ NSApp keyWindow ];
	if( window )
		[ self loadFlashForWindow: window ];
}


- (IBAction) loadKeyWindowInvisibleFlash: (id) sender
{
	NSWindow* window = [ NSApp keyWindow ];
	if( window )
		[ self loadInvisibleFlashForWindow: window ];
}


- (IBAction) showSettingsWindow: (id) sender
{
	if( _whitelistWindowController == nil )
		_whitelistWindowController = [ [ CTFWhitelistWindowController alloc ] init ];
	
	[ _whitelistWindowController showWindow: sender ];
}

@synthesize flashViews = _flashViews;

@end

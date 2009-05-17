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

#import "Plugin.h"

NSString* kCTFLoadAllFlashViews = @"CTFLoadAllFlashViews";
NSString* kCTFLoadFlashViewsForWindow = @"CTFLoadFlashViewsForWindow";
NSString* kCTFLoadInvisibleFlashViewsForWindow = @"CTFLoadInvisibleFlashViewsForWindow";

NSInteger maxInvisibleDimension = 8;

static NSString* kApplicationsToInstallMenuInto[] = {
    @"com.apple.Safari",
    @"uk.co.opencommunity.vienna2",
#if 0
    @"com.panic.Coda", // for debugging an app that includes its own old Sparkle framework.
#endif
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
	
	NSMenu* applicationMenu = appMenu();
	int insertLocation = -1, count = [ applicationMenu numberOfItems ];
    if( indx ) {
        insertLocation = [ indx intValue ];
	} else {
		int showPrefsItem = -1;
		int i;
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
	}
	
	if ((insertLocation > count) || (insertLocation < 0))
		insertLocation = count;
    
    return insertLocation;
}


#pragma mark -
#pragma mark Lifetime management


static CTFMenubarMenuController* sSingleton = nil;


- (id) init
{
	if( sSingleton ) {
		[ self release ];
		return sSingleton;
	}
    
	self = [ super init ];
	
	if( self ) {
		if( ! [ NSBundle loadNibNamed: @"MenubarMenu" owner: self ] )
			NSLog( @"ClickToFlash: Could not load menubar menu nib" );
		
		_views = NSCreateHashTable( NSNonRetainedObjectHashCallBacks, 0 );
	}
	
	return self;
}


- (void) dealloc
{
	[ _whitelistWindowController release ];
    NSFreeHashTable( _views );
	
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
	
    // Find the location to insert the item:
    
    int insertLocation = [ self applicationMenuPrefsInsertionLocation ];
	
	// Sanity check the location
    
	NSMenu* applicationMenu = appMenu();
	
	if ( ( insertLocation < 0 ) || ( insertLocation > [ applicationMenu numberOfItems ] ) ) {
		NSLog( @"ClickToFlash: Could not insert menu at location %i", insertLocation );
		return;
	}
    
    // We need a submenu item to wrap this loaded menu:
    
	NSMenuItem* ctfMenuItem = [ [ [ NSMenuItem alloc ] initWithTitle: [ menu title ]
															  action: nil
													   keyEquivalent: @"" ] autorelease ];
	[ ctfMenuItem setSubmenu: menu ];
    
    // Insert the submenu there:
    
	[ applicationMenu insertItem: ctfMenuItem atIndex: insertLocation ];
}


+ (CTFMenubarMenuController*) sharedController
{
	if( !sSingleton )
		sSingleton = [ [ CTFMenubarMenuController alloc ] init ];
	
	return sSingleton;
}


#pragma mark -
#pragma mark View Management


- (void) registerView: (NSView*) view
{
	NSHashInsertIfAbsent( _views, view );
}


- (void) unregisterView: (NSView*) view
{
	NSHashRemove( _views, view );
}


- (BOOL) _atLeastOneFlashViewExists
{
	return NSCountHashTable( _views ) > 0;
}


- (BOOL) _flashViewExistsForKeyWindowWithInvisibleOnly: (BOOL) mustBeInvisible
{
	BOOL rslt = NO;
	
	NSWindow* keyWindow = [ NSApp keyWindow ];
	
	NSHashEnumerator enumerator = NSEnumerateHashTable( _views );
	CTFClickToFlashPlugin* item;
	while( ( item = NSNextHashEnumeratorItem( &enumerator ) ) ) {
		if( [ item window ] == keyWindow ) {
			if( !mustBeInvisible || [ item isConsideredInvisible ] ) {
				rslt = YES;
				break;
			}
		}
	}
	NSEndHashTableEnumeration( &enumerator );
	
	return rslt;
}

- (BOOL) _flashViewExistsForKeyWindow
{
	return [ self _flashViewExistsForKeyWindowWithInvisibleOnly: NO ];
}

- (BOOL) _invisibleFlashViewExistsForKeyWindow;
{
	return [ self _flashViewExistsForKeyWindowWithInvisibleOnly: YES ];
}

- (BOOL) validateMenuItem: (NSMenuItem*) item
{
	if ( [ item action ] == @selector( loadAllFlash: ) ) {
		return [ self _atLeastOneFlashViewExists ];
	}
	else if( [ item action ] == @selector( loadKeyWindowFlash: ) ) {
		return [ self _flashViewExistsForKeyWindow ];
	}
	else if( [ item action ] == @selector(loadKeyWindowInvisibleFlash: ) ) {
		return [ self _invisibleFlashViewExistsForKeyWindow ];
	}
	
	return YES;
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

@end

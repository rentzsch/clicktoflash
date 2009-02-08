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


NSString* kCTFLoadAllFlashViews = @"CTFLoadAllFlashViews";
NSString* kCTFLoadFlashViewsForWindow = @"CTFLoadFlashViewsForWindow";

static CTFMenubarMenuController* sSingleton = nil;


@implementation CTFMenubarMenuController


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
	
	return self;
}


- (void) dealloc
{
	[ _whitelistWindowController release ];

	[ super dealloc ];
}


- (void) awakeFromNib
{
	if( !menu ) {
		NSLog( @"ClickToFlash: Could not load menubar menu" );
		return;
	}
    
    // We need a submenu item to wrap this loaded menu:
    
	NSMenuItem* ctfMenuItem = [ [ [ NSMenuItem alloc ] initWithTitle: [ menu title ]
															  action: nil
													   keyEquivalent: @"" ] autorelease ];
	[ ctfMenuItem setSubmenu: menu ];
	
	NSMenu* applicationMenu = [ [ [ NSApp mainMenu ] itemAtIndex: 0 ] submenu ];
	
    // Find the location to insert the item:
    
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
    
    // Insert the submenu there:
    
    [ applicationMenu insertItem: ctfMenuItem atIndex: insertLocation ];
}


+ (CTFMenubarMenuController*) sharedController
{
	if( !sSingleton )
		[ [ CTFMenubarMenuController alloc ] init ];
	
	return sSingleton;
}


#pragma mark -
#pragma mark Actions


- (IBAction) loadAllFlash: (id) sender
{
	[ [ NSNotificationCenter defaultCenter ] postNotificationName: kCTFLoadAllFlashViews 
														   object: self ];
}


- (IBAction) loadKeyWindowFlash: (id) sender
{
	NSWindow* window = [ NSApp keyWindow ];
	if( window )
		[ [ NSNotificationCenter defaultCenter ] postNotificationName: kCTFLoadFlashViewsForWindow 
															   object: window ];
}


- (IBAction) showSettingsWindow: (id) sender
{
	if( _whitelistWindowController == nil )
		_whitelistWindowController = [ [ CTFWhitelistWindowController alloc ] init ];
	
	[ _whitelistWindowController showWindow: sender ];
}


@end

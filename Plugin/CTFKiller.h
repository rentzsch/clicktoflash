/*
  CTFKiller.h
  ClickToFlash

 The MIT License
 
 Copyright (c) 2009 ClickToFlash Developers
 
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

@class CTFClickToFlashPlugin;

@interface CTFKiller : NSObject {
	NSURL * pageURL;
	NSString * srcURLString;
	NSDictionary * attributes;
	NSDictionary * flashVars;
	
	CTFClickToFlashPlugin * plugin;
}

// Come and go

// Class method returns an instantiated CTFKiller class for the URL/data/plugin passed to it. This is the call to use.
+ (CTFKiller*) killerForURL: (NSURL*) theURL src: (NSString*) theSrc attributes: (NSDictionary*) attributes forPlugin:(CTFClickToFlashPlugin*) thePlugin;
// Initialiser method doing the basic setup. There should be no need to use this. The +killerForULR:src:attributes:forPlugin class method should handle everything.
- (id) initWithURL: (NSURL*) theURL src:(NSString*) theSrc attributes: (NSDictionary*) attributes forPlugin:(CTFClickToFlashPlugin*) thePlugin;

// To be implemented by subclasses

// Return whether this class can handle the Flash for the given URL and other data.
+ (BOOL) canHandleFlashAtURL: (NSURL*) theURL src: (NSString*) theSrc attributes: (NSDictionary*) attributes forPlugin:(CTFClickToFlashPlugin*) thePlugin;
// Set up the subclass. If further data is needed, fetching it is started here.
- (void) setup;
// The label displayed in the plug-in. Subclasses can provide their own name here which is read whenever the plug-in view is redrawn.
- (NSString*) badgeLabelText;
// Called when building the Contextual menu to add a single item at the second position.
- (void) addPrincipalMenuItemToContextualMenu;
// Called when building the contextual menu to add further items afte the basic Load/Hide Flash items. 
- (void) addAdditionalMenuItemsForContextualMenu;
// Called when the user clicks the CtF view. Replace content here.
- (BOOL) convertToContainer;


// Accessors
- (NSURL *)pageURL;
- (void)setPageURL:(NSURL *)newPageURL;
- (NSString *)srcURLString;
- (void)setSrcURLString:(NSString *)newSrcURLString;
- (NSDictionary *)attributes;
- (void)setAttributes:(NSDictionary *)newAttributes;
- (NSDictionary *)flashVars;
- (void)setFlashVars:(NSDictionary *)newFlashVars;
// get a specific flash variable
- (NSString*) flashVarWithName: (NSString*) argName;
- (CTFClickToFlashPlugin *)plugin;
- (void)setPlugin:(CTFClickToFlashPlugin *)newPlugin;

@end

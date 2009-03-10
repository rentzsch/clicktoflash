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

#import "CTFWhitelist.h"

#import "CTFUtilities.h"
#import "CTFMenubarMenuController.h"


    // NSNotification names
static NSString *sCTFWhitelistAdditionMade = @"CTFWhitelistAdditionMade";

    // NSUserDefaults keys
static NSString *sHostSiteInfoDefaultsKey = @"ClickToFlash_siteInfo";

typedef enum {
    CTFSiteKindWhitelist = 0
} CTGSiteKind;


static NSUInteger indexOfItemForSite( NSArray* arr, NSString* site )
{
    int i = 0;
    CTFForEachObject( NSDictionary, item, arr ) {
        if( [ [ item objectForKey: @"site" ] isEqualToString: site ] )
            return i;
        ++i;
    }
    
    return NSNotFound;
}

static NSDictionary* itemForSite( NSArray* arr, NSString* site )
{
    NSUInteger index = indexOfItemForSite( arr, site );
    
    if( index != NSNotFound )
        return [ arr objectAtIndex: index ];
    
	return nil;
}

static NSDictionary* whitelistItemForSite( NSString* site )
{
    return [ NSDictionary dictionaryWithObjectsAndKeys: site, @"site",
            [ NSNumber numberWithInt: CTFSiteKindWhitelist ], @"kind",
            nil ];
}


@implementation CTFClickToFlashPlugin( Whitelist )

- (void) _migrateWhitelist
{
    // Migrate from the old location to the new location.  We'll leave
    // this in for a couple builds (being added for 1.4) and then remove
    // it assuming those who care would have upgraded.
    
    NSUserDefaults* defaults = [ NSUserDefaults standardUserDefaults ];
    
    id oldWhitelist = [ defaults objectForKey: @"ClickToFlash.whitelist" ];
    if( oldWhitelist ) {
        id newWhitelist = [ defaults objectForKey: sHostSiteInfoDefaultsKey ];
        
        if( newWhitelist == nil ) {
            NSMutableArray* newWhitelist = [ NSMutableArray arrayWithCapacity: [ oldWhitelist count ] ];
            CTFForEachObject( NSString, site, oldWhitelist ) {
                [ newWhitelist addObject: whitelistItemForSite( site ) ];
            }
            [ defaults setObject: newWhitelist forKey: sHostSiteInfoDefaultsKey ];
        }
        
        [ defaults removeObjectForKey: @"ClickToFlash.whitelist"];
    }
}

- (void) _addWhitelistObserver
{
    [[NSNotificationCenter defaultCenter] addObserver: self 
                                             selector: @selector( _whitelistAdditionMade: ) 
                                                 name: sCTFWhitelistAdditionMade 
                                               object: nil];
}

- (void) _alertDone
{
	[ _activeAlert release ];
	_activeAlert = nil;
}

- (void) _abortAlert
{
	if( _activeAlert ) {
		[ NSApp endSheet: [ _activeAlert window ] returnCode: NSAlertSecondButtonReturn ];
		[ self _alertDone ];
	}
}

- (void) _askToAddCurrentSiteToWhitelist
{
    NSString *title = NSLocalizedString(@"Always load Flash for this site?", @"Always load Flash for this site? alert title");
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Add %@ to the whitelist?", @"Add <sitename> to the whitelist? alert message"), self.host];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"Add to Whitelist", @"Add to Whitelist button")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(_addToWhitelistAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
    _activeAlert = alert;
}

- (void) _addToWhitelistAlertDidEnd: (NSAlert *)alert returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
    if (returnCode == NSAlertFirstButtonReturn)
    {
        [self _addHostToWhitelist];
    }
    
    [ self _alertDone ];
}

- (BOOL) _isHostWhitelisted
{
	// Nil hosts whitelisted by default (e.g. Dashboard)
	if (!self.host)
	{
		return YES;
	}
	
	return [self _isWhiteListedForHostString: self.host];
}

- (BOOL) _isWhiteListedForHostString:(NSString *)hostString
{
	NSArray *hostWhitelist = [[NSUserDefaults standardUserDefaults] arrayForKey: sHostSiteInfoDefaultsKey];
    return hostWhitelist && itemForSite(hostWhitelist, hostString) != nil;
}

- (NSMutableArray *) _mutableSiteInfo
{
    NSMutableArray *hostWhitelist = [[[[NSUserDefaults standardUserDefaults] arrayForKey: sHostSiteInfoDefaultsKey] mutableCopy] autorelease];
    if (hostWhitelist == nil) {
        hostWhitelist = [NSMutableArray array];
    }
    return hostWhitelist;
}

- (void) _addHostToWhitelist
{
    NSMutableArray *siteInfo = [self _mutableSiteInfo];
    [siteInfo addObject: whitelistItemForSite(self.host)];
    [[NSUserDefaults standardUserDefaults] setObject: siteInfo forKey: sHostSiteInfoDefaultsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName: sCTFWhitelistAdditionMade object: self];
}

- (void) _removeHostFromWhitelist
{
    NSMutableArray *siteInfo = [self _mutableSiteInfo];
    NSUInteger foundIndex = indexOfItemForSite(siteInfo, self.host);
    
    if(foundIndex != NSNotFound) {
        [siteInfo removeObjectAtIndex: foundIndex];
        [[NSUserDefaults standardUserDefaults] setObject: siteInfo forKey: sHostSiteInfoDefaultsKey];
    }
}

- (void) _whitelistAdditionMade: (NSNotification*) notification
{
	if ([self _isHostWhitelisted])
		[self _convertTypesForContainer];
}

- (IBAction)addToWhitelist:(id)sender;
{
    if ([self _isHostWhitelisted])
        return;
    
    [self _addHostToWhitelist];
}

- (IBAction) removeFromWhitelist: (id)sender
{
    if (![self _isHostWhitelisted])
        return;
    
    NSString *title = NSLocalizedString(@"Stop always loading Flash?", @"Stop always loading Flash? alert title");
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Remove %@ from the whitelist?", @"Remove %@ from the whitelist? alert message"), self.host];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"Remove from Whitelist", @"Remove from Whitelist button")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(_removeFromWhitelistAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
    _activeAlert = alert;
}

- (void) _removeFromWhitelistAlertDidEnd: (NSAlert *)alert returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
    if (returnCode == NSAlertFirstButtonReturn)
    {
        [self _removeHostFromWhitelist];
    }
    
    [ self _alertDone ];
}

- (IBAction) editWhitelist: (id)sender;
{
	[ [ CTFMenubarMenuController sharedController ] showSettingsWindow: self ];
}

@end

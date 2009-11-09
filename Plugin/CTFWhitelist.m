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

#import "CTFWhitelist.h"

#import "CTFUtilities.h"
#import "CTFMenubarMenuController.h"

#import "CTFUserDefaultsController.h"
#import "CTFPreferencesDictionary.h"


    // NSNotification names
static NSString *sCTFWhitelistAdditionMade = @"CTFWhitelistAdditionMade";

    // CTFUserDefaultsController keys
static NSString *sHostSiteInfoDefaultsKey = @"siteInfo";

typedef enum {
    CTFSiteKindWhitelist = 0
} CTGSiteKind;


static BOOL nameMatchesDomainName ( NSString* name, NSString* domainName ) {
	BOOL result = NO;
	if ( name != nil && domainName != nil ) {
		NSRange domainRange = [name rangeOfString: domainName options: NSCaseInsensitiveSearch || NSAnchoredSearch || NSBackwardsSearch];
		if ( domainRange.location != NSNotFound ) {
			// if the match doesn't reach to the beginning of the string, make sure that the preceding character is a dot, to avoid matching other domain names
			if ( domainRange.location == 0 ) {
				result = YES;
			}
			else {
				if ( [[name substringWithRange:NSMakeRange(domainRange.location - 1, 1)] isEqualToString:@"."] ) {
					result = YES;
				}
			}
		}
	}	
	return result;
}

static NSDictionary* itemForSite( NSSet* set, NSString* site )
{
	NSDictionary *specificWhitelistItem = nil;
	if (site != nil) {
		
 		NSURL * siteURL = [NSURL URLWithString:site];
		NSString * host = [siteURL host];
		
		if (siteURL != nil) {
			CTFForEachObject( NSDictionary, item, set ) {
				NSString * whitelistItem = [ item objectForKey: @"site" ];
				NSInteger slashPosition = [whitelistItem rangeOfString:@"/"].location;
				if( slashPosition == NSNotFound ) {
					// no slash => just check host name
					if ( nameMatchesDomainName(host, whitelistItem) ) {
						specificWhitelistItem = item;
						break;
					}
				}
				else {
					// there is a slash => match the host name and path (make sure we really get to use both of the host and the path and don't just match strings in the path only
					NSString * hostSubstring = [whitelistItem substringToIndex:slashPosition];
					NSString * pathSubstring = [whitelistItem substringFromIndex:slashPosition];
					if ( nameMatchesDomainName(host, hostSubstring)
						&& ([[siteURL path] rangeOfString: pathSubstring options: NSAnchoredSearch].location != NSNotFound) ){
						specificWhitelistItem = item;
						break;
					}
				}
			}
		}
	}	
	
	return specificWhitelistItem;
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
    NSString *title = [NSString stringWithFormat:CtFLocalizedString(@"Always load Flash for '%@'?", @"Always load Flash for '%@'? alert title"), [self host]];
    NSString *message = [NSString stringWithFormat:CtFLocalizedString(@"Add %1$@ to the whitelist? This can be undone by opening ClickToFlash Prefrences from the %2$@ menu and removing the site from the list.", @"Add <sitename> to the whitelist? alert message including removal instruction. %1$@ is the page's host name, %2$@ is the application name."), [self host], [[NSProcessInfo processInfo] processName]];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:CtFLocalizedString(@"Add to Whitelist", @"Add to Whitelist button")];
    [alert addButtonWithTitle:CtFLocalizedString(@"Cancel", @"Cancel button")];
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
	if ( [[self baseURL] hasPrefix:@"about:"] ) {
		// encountered an ad on addictinggames.com where it loaded an
		// about:blank page and then inserted ads there
		return NO;
	} else if ( ![self host] ) {
		// Nil hosts whitelisted by default (e.g. Dashboard)
		return YES;
	}
	
	return [self _isWhiteListedForHostString: [self baseURL]];
}

- (BOOL) _isWhiteListedForHostString:(NSString *)hostString
{
	NSArray *hostWhitelistArray = [[CTFUserDefaultsController standardUserDefaults] arrayForKey: sHostSiteInfoDefaultsKey];
	NSSet *hostWhitelistSet = [NSSet setWithArray:hostWhitelistArray];
	return hostWhitelistArray && itemForSite(hostWhitelistSet, hostString) != nil;
}

- (NSMutableSet *) _mutableSiteInfo
{
    NSMutableArray *hostWhitelistArray = [[[[CTFUserDefaultsController standardUserDefaults] arrayForKey: sHostSiteInfoDefaultsKey] mutableCopy] autorelease];
	
	NSMutableSet *hostWhitelist;
    if (hostWhitelistArray == nil) {
        hostWhitelist = [NSMutableSet setWithCapacity:0];
    } else {
		hostWhitelist = [NSMutableSet setWithArray:hostWhitelistArray];
	}
	
    return hostWhitelist;
}

- (void) _addHostToWhitelist
{
    NSMutableSet *siteInfo = [self _mutableSiteInfo];
    [siteInfo addObject: whitelistItemForSite([self host])];
	
	[[CTFUserDefaultsController standardUserDefaults] setValue:[siteInfo allObjects] forKeyPath:@"values.siteInfo"];
	
    [[NSNotificationCenter defaultCenter] postNotificationName: sCTFWhitelistAdditionMade object: self];
}

- (void) _whitelistAdditionMade: (NSNotification*) notification
{
	if ([self _isHostWhitelisted])
		[self convertTypesForContainer];
}

- (IBAction)addToWhitelist:(id)sender;
{
    if ([self _isHostWhitelisted])
        return;
    
    [self _addHostToWhitelist];
}

- (IBAction) editWhitelist: (id)sender;
{
	[ [ CTFMenubarMenuController sharedController ] showSettingsWindow: self ];
}

@end

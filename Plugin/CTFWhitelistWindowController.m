#import "CTFWhitelistWindowController.h"

extern NSString *sHostWhitelistDefaultsKey;
extern NSString *sCTFWhitelistAdditionMade;

@implementation CTFWhitelistWindowController

- (id)init
{
    NSBundle * myBundle = [NSBundle bundleForClass:[self class]];
    NSString * nibPath = [myBundle pathForResource:@"WhitelistPanel" ofType:@"nib"];
    if (nibPath == nil)
    {
        [self dealloc];
        return nil;
    }
    
    self = [super initWithWindowNibPath: nibPath owner: self];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(whitelistChanged:) name: sCTFWhitelistAdditionMade object: nil];
	_sites = [[NSMutableArray array] retain];
	
	[self whitelistChanged: nil];

    return self;
}

- (void) dealloc {
	[_sites release];
	[super dealloc];
}

- (void) whitelistChanged: (NSNotification *) note {
	NSArray							*currentSites = [[NSUserDefaults standardUserDefaults] valueForKey: sHostWhitelistDefaultsKey];
	NSEnumerator					*enumerator = [currentSites objectEnumerator];
	NSString						*site;
	
	[_sites removeAllObjects];
	
	while (site = [enumerator nextObject]) {
		[_sites addObject: [NSMutableDictionary dictionaryWithObject: site forKey: @"description"]];
	}
	[_controller setContent: _sites];
}

- (IBAction) removeWhitelistSite: (id) sender {
	[_controller remove: nil];
	[self saveWhitelist: nil];
}

- (IBAction) addWhitelistSite: (id) sender {
	[_controller insertObject: [NSMutableDictionary dictionaryWithObject: @"" forKey: @"description"] atArrangedObjectIndex: _sites.count];
	[_controller setSelectionIndex: _sites.count - 1];
	[self saveWhitelist: nil];
}

- (void) saveWhitelist: (id) sender {
	NSMutableArray					*sites = [NSMutableArray array];
	NSEnumerator					*enumerator = [_sites  objectEnumerator];
	NSDictionary					*site;
	
	while (site = [enumerator nextObject]) {
		[sites addObject: [site valueForKey: @"description"]];
	}
	
	NSUserDefaults					*defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setValue: sites forKey: sHostWhitelistDefaultsKey];
}

- (void) windowWillClose: (NSNotification *) notification {
	[self saveWhitelist: nil];
}

@end

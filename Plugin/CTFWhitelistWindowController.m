#import "CTFWhitelistWindowController.h"
#import <Sparkle/Sparkle.h>

NSString *kCTFCheckForUpdates = @"CTFCheckForUpdates";

@implementation CTFWhitelistWindowController

- (id)init
{
    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    NSString *nibPath = [myBundle pathForResource:@"WhitelistPanel" ofType:@"nib"];
    if (nibPath == nil) {
        [self dealloc];
        return nil;
    }
    
    self = [super initWithWindowNibPath: nibPath owner: self];

    return self;
}

- (IBAction)checkForUpdates:(id)sender;
{
	// this code is put here, because if it's code that's owned by the plugin object, then initiating
	// an update will silently fail when no ClickToFlash view is loaded; putting it in the whitelist window
	// object allows Sparkle to always check for updates
	
	NSBundle *clickToFlashBundle = [NSBundle bundleWithIdentifier:@"com.github.rentzsch.clicktoflash"];
	NSAssert(clickToFlashBundle, nil);
	SUUpdater *updater = [SUUpdater updaterForBundle:clickToFlashBundle];
	NSAssert(updater, nil);
	[updater checkForUpdates:self];
}

@end

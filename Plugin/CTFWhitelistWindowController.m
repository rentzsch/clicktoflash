#import "CTFWhitelistWindowController.h"
#import "SparkleManager.h"

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

- (void)windowDidLoad
{
    [_checkNowButton setEnabled:[[SparkleManager sharedManager] canUpdate]];
}

- (IBAction)checkForUpdates:(id)sender;
{
	[[SparkleManager sharedManager] checkForUpdates];
}

- (NSString *)versionString
{
	NSBundle *CTFBundle = [NSBundle bundleWithIdentifier:@"com.github.rentzsch.clicktoflash"];
	return [CTFBundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

@end

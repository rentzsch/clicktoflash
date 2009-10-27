#import <Cocoa/Cocoa.h>
#import "SparkleManager.h"

extern NSString* kCTFCheckForUpdates;

@interface CTFWhitelistWindowController : NSWindowController {
	NSString * successInformation;

	IBOutlet NSArrayController *_controller;
    IBOutlet NSButton *_checkNowButton;
	
	IBOutlet NSPanel *confirmUninstallSheet;
	IBOutlet NSPanel *successfulUninstallationSheet;
	IBOutlet NSPanel *failedUninstallationSheet;
}

- (IBAction)checkForUpdates:(id)sender;
- (IBAction)automaticallyCheckForUpdatesDidChange:(id)sender;
- (IBAction)uninstallClickToFlash:(id)sender;

- (IBAction)cancelUninstall:(id)sender;
- (IBAction)approveUninstall:(id)sender;

- (IBAction)dismissSuccessSheet:(id)sender;
- (IBAction)dismissFailureSheet:(id)sender;

- (IBAction)quitApplication:(id)sender;
@end


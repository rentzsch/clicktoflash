#import <Cocoa/Cocoa.h>

extern NSString* kCTFCheckForUpdates;

@interface CTFWhitelistWindowController : NSWindowController {
	IBOutlet NSArrayController *_controller;
    IBOutlet NSButton *_checkNowButton;
}

- (IBAction)checkForUpdates:(id)sender;

@end


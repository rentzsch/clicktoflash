#import <Cocoa/Cocoa.h>

extern NSString* kCTFCheckForUpdates;

@interface CTFWhitelistWindowController : NSWindowController {
	IBOutlet NSArrayController *_controller;
}

- (IBAction)checkForUpdates:(id)sender;

@end


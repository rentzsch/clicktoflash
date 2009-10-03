#import "CTFWhitelistWindowController.h"
#import "SparkleManager.h"
#import "Plugin.h"
#import "CTFUtilities.h"


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

- (IBAction)automaticallyCheckForUpdatesDidChange:(id)sender;
{
	[[SparkleManager sharedManager] setAutomaticallyChecksForUpdates:[sender state]];
}

- (NSString *)versionString
{
	NSBundle *CTFBundle = [NSBundle bundleWithIdentifier:@"com.github.rentzsch.clicktoflash"];
	return [CTFBundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

- (NSString *)pathToBundle {
	NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
	return [myBundle bundlePath];
}



- (IBAction)uninstallClickToFlash:(id)sender;
{
	[NSApp beginSheet:confirmUninstallSheet
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (IBAction)cancelUninstall:(id)sender;
{
    [confirmUninstallSheet orderOut:sender];
    
    [NSApp endSheet:confirmUninstallSheet returnCode:0];
}

- (IBAction)approveUninstall:(id)sender;
{
    [confirmUninstallSheet orderOut:sender];
    
    [NSApp endSheet:confirmUninstallSheet returnCode:1];
}

- (void)sheetDidEnd:(NSWindow *)sheet
		 returnCode:(int)returnCode
		contextInfo:(void *)contextInfo;
{
	if (returnCode == 1) {
		NSString *userPluginPath = [self pathToBundle];
		BOOL isDirectory = NO;
		BOOL userPluginExists = [[NSFileManager defaultManager] fileExistsAtPath:userPluginPath
																	 isDirectory:&isDirectory];
		BOOL succeeded = NO;
		if (userPluginExists && isDirectory) {
			// we'll move the plugin to the trash, instead of just obstinately deleting it
			succeeded = [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
																	 source:[userPluginPath stringByDeletingLastPathComponent]
																destination:nil
																	  files:[NSArray arrayWithObject:[userPluginPath lastPathComponent]]
																		tag:nil];
		}
		
		if (succeeded) {
			NSString * message = [NSString stringWithFormat:CtFLocalizedString(@"Please quit and relaunch '%@' for the change to take effect.", @"Successful uninstallation Sheet informational message with application name"), [[NSProcessInfo processInfo] processName]];
			[self setValue:message forKey:@"successInformation"];
			
			[NSApp beginSheet:successfulUninstallationSheet
			   modalForWindow:[self window]
				modalDelegate:self
			   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
				  contextInfo:nil];
		} else {
			// there are three ways to get here:
			
			// 1. either userPluginExists equals NO, in which case the plugin is
			// installed for all users and we can't guarantee that we can
			// uninstall it, so we'll just fail
			
			// 2. an item exists at the correct path, but it's a file not a
			// folder, so it's not ClickToFlash
			
			// 3. the plugin exists, but for some reason we couldn't move
			// it to the trash
			
			[NSApp beginSheet:failedUninstallationSheet
			   modalForWindow:[self window]
				modalDelegate:self
			   didEndSelector:@selector(resultSheetDidEnd:returnCode:contextInfo:)
				  contextInfo:nil];
		}
	} else {
		// uninstallation was cancelled
	}
}

- (IBAction)dismissSuccessSheet:(id)sender;
{
	[successfulUninstallationSheet orderOut:sender];
    
    [NSApp endSheet:successfulUninstallationSheet returnCode:0];
}

- (IBAction)dismissFailureSheet:(id)sender;
{
	[failedUninstallationSheet orderOut:sender];
    
    [NSApp endSheet:failedUninstallationSheet returnCode:0];
}

- (void)returnSheetDidEnd:(NSWindow *)sheet
		 returnCode:(int)returnCode
		contextInfo:(void *)contextInfo;
{
	// nothing to see here!
}


- (IBAction)quitApplication:(id)sender {
	[successfulUninstallationSheet orderOut:sender];
	[NSApp endSheet:successfulUninstallationSheet];

	[NSApp performSelectorOnMainThread:@selector(terminate:) withObject:self waitUntilDone:NO];
}


@end

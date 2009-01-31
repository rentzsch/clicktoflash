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

/*
 - INSTALL missing ~/Library/Internet Plug-Ins
 - INSTALL file where "Internet Plug-Ins" folder should be
 - INSTALL no ClickToFlash
 - UPDATE ClickToFlash 1.0 installed
 - UPDATE ClickToFlash 1.0+rentzsch
 - REMOVE ClickToFlash 1.1
*/

#import "CTFInstaller.h"

#define kInternetPlugins @"~/Library/Internet Plug-Ins"

@interface CTFInstaller (Internal)

- (NSString *) pathToClickToFlash;
- (id) installClickToFlash;
- (id) removeClickToFlash;
- (id) updateClickToFlash;

@end
 

@implementation CTFInstaller

- (void)finishLaunching
{
    NSString *pathToClickToFlash = [self pathToClickToFlash];

    if (!pathToClickToFlash) {
        NSString *title = NSLocalizedString(@"Install ClickToFlash", @"Install ClickToFlash");
        NSString *message = NSLocalizedString(@"ClickToFlash is not installed. Would you like to install it for this user?", @"ClickToFlash is not installed. Would you like to install it for this user?");
        
        int result = NSRunAlertPanel(title, message, NSLocalizedString(@"Install", @"Install"), NSLocalizedString(@"Cancel", @"Cancel"), nil);

        if (result == NSAlertDefaultReturn) {
            [self installClickToFlash];
        }

    } else {
        NSString *thisVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *installedVersion = [[[NSBundle bundleWithPath:pathToClickToFlash] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        
        if([installedVersion isEqualToString:thisVersion]) {
            NSString *title = NSLocalizedString(@"Remove ClickToFlash", @"Remove ClickToFlash");
            NSString *message = NSLocalizedString(@"ClickToFlash is currently installed. Would you like to remove it?", @"ClickToFlash is currently installed. Would you like to remove it?");
            
            int result = NSRunAlertPanel(title, message, NSLocalizedString(@"Remove", @"Remove"), NSLocalizedString(@"Cancel", @"Cancel"), nil);

            if (result == NSAlertDefaultReturn) {
                [self removeClickToFlash];
            }
        } else {
            NSString *title = NSLocalizedString(@"Update ClickToFlash", @"Update ClickToFlash");
            NSString *message = NSLocalizedString(@"An older version of ClickToFlash is currently installed. Would you like to update it?", @"An older version of ClickToFlash is currently installed. Would you like to update it?");
            
            int result = NSRunAlertPanel(title, message, NSLocalizedString(@"Update", @"Update"), NSLocalizedString(@"Cancel", @"Cancel"), nil);
            
            if (result == NSAlertDefaultReturn) {
                [self updateClickToFlash];
            }
        }
    }
    
    [self terminate:nil];
}


- (NSString *) pathToClickToFlash
{
    NSString *path = [kInternetPlugins @"/ClickToFlash.plugin" stringByStandardizingPath];
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    NSString *bundleID = [bundle bundleIdentifier];
    
    if ([bundleID isEqualToString:@"com.google.code.p.clicktoflash"] || [bundleID isEqualToString:@"com.github.rentzsch.clicktoflash"]) {
        return path;
    }

    return nil;
}


- (id) installClickToFlash
{
    NSString *fromPath = [[NSBundle mainBundle] pathForResource:@"ClickToFlash" ofType:@"plugin"];
    
    NSString *toPath = [kInternetPlugins stringByStandardizingPath];
    
    BOOL isDirectory = NO;
    BOOL doesPluginsExist = [[NSFileManager defaultManager] fileExistsAtPath:toPath isDirectory:&isDirectory];
    
    if (!doesPluginsExist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:toPath attributes:nil];
    } else if (doesPluginsExist && !isDirectory) {
        [[NSFileManager defaultManager] removeFileAtPath:toPath handler:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:toPath attributes:nil];
    }

    toPath = [toPath stringByAppendingPathComponent:@"ClickToFlash.plugin"];
    
    if ([[NSFileManager defaultManager] copyPath:fromPath toPath:toPath handler:nil]) {
        NSString *message = NSLocalizedString(@"Quit and relaunch Safari to activate ClickToFlash.", nil);
        NSRunAlertPanel(NSLocalizedString(@"ClickToFlash Installed", nil),
                        message, nil, nil, nil);    
    } else {
        NSString *message = NSLocalizedString(@"ClickToFlash could not be installed.", nil);
        NSRunAlertPanel(NSLocalizedString(@"Installed Failed", nil),
                        message, nil, nil, nil);
    }
}


- (id) removeClickToFlash
{
    NSString *path = [self pathToClickToFlash];

    if ([[NSFileManager defaultManager] removeFileAtPath:path handler:nil]) {
        NSString *message = NSLocalizedString(@"ClickToFlash has been removed.", nil);
        NSRunAlertPanel(NSLocalizedString(@"ClickToFlash Removed", nil), message, nil, nil, nil);
    }
}


- (id) updateClickToFlash
{
    NSString *installedPluginPath = [self pathToClickToFlash];
    
    BOOL success = [[NSFileManager defaultManager] removeFileAtPath:installedPluginPath handler:nil];
    
    if (success) {
        NSString *fromPath = [[NSBundle mainBundle] pathForResource:@"ClickToFlash" ofType:@"plugin"];
        success = [[NSFileManager defaultManager] copyPath:fromPath toPath:installedPluginPath handler:nil];
    }
    
    NSString *message = success
        ? NSLocalizedString(@"ClickToFlash has been updated. Please quit and relaunch Safari.", nil)
        : NSLocalizedString(@"ClickToFlash could not be updated.", nil);
    NSRunAlertPanel(NSLocalizedString(@"Update ClickToFlash", nil), message, nil, nil, nil);
}


@end


int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}

/*

The MIT License

Copyright (c) 2008 Click to Flash Developers

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


#import "CTFInstaller.h"

#define kInternetPlugins @"~/Library/Internet Plug-Ins"

@interface CTFInstaller (Internal)

- (NSString *) pathToClickToFlash;
- (id) installClickToFlash;
- (id) removeClickToFlash;

@end
 

@implementation CTFInstaller

- (void)finishLaunching
{
    NSString *pathToClickToFlash = [self pathToClickToFlash];

    if (!pathToClickToFlash) {
        NSInteger result = NSRunAlertPanel(@"Install ClickToFlash", @"ClickToFlash is not installed.  Would you like to install it for this user?", @"Install", @"Cancel", nil);

        if (result == NSAlertDefaultReturn) {
            [self installClickToFlash];
        }

    } else {
        NSInteger result = NSRunAlertPanel(@"Remove ClickToFlash", @"ClickToFlash is currently installed.  Would you like to remove it?", @"Remove", @"Cancel", nil);    

        if (result == NSAlertDefaultReturn) {
            [self removeClickToFlash];
        }
    }
}


- (NSString *) pathToClickToFlash
{
    NSString *path = [kInternetPlugins @"/ClickToFlash.plugin" stringByStandardizingPath];
    NSBundle *bundle = [NSBundle bundleWithPath:path];

    if ([[bundle bundleIdentifier] isEqualToString:@"com.google.code.p.clicktoflash"]) {
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

    if (doesPluginsExist && !isDirectory) {
        [[NSFileManager defaultManager] removeFileAtPath:toPath handler:nil];
    }
    
    if (!doesPluginsExist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:toPath attributes:nil];
    }

    toPath = [toPath stringByAppendingPathComponent:@"ClickToFlash.plugin"];

    if ([[NSFileManager defaultManager] copyPath:fromPath toPath:toPath handler:nil]) {
        NSRunAlertPanel(@"Install ClickToFlash", @"ClickToFlash has been installed.  Quit and relaunch Safari to activate ClickToFlash.", @"OK", nil, nil);    
    } else {
        NSRunAlertPanel(@"Install ClickToFlash", @"ClickToFlash could not be installed.", @"OK", nil, nil);    
    }

    [self terminate:self];
}


- (id) removeClickToFlash
{
    NSString *path = [self pathToClickToFlash];

    if ([[NSFileManager defaultManager] removeFileAtPath:path handler:nil]) {
        NSRunAlertPanel(@"Remove ClickToFlash", @"ClickToFlash has been removed", @"OK", nil, nil);    
        [self terminate:self];
    }
}


@end


int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}

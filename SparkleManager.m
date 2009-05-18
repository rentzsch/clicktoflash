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

#import "SparkleManager.h"
#import <Sparkle/Sparkle.h>

// NSUserDefaults keys
static NSString *sAutomaticallyCheckForUpdates = @"ClickToFlash_checkForUpdatesOnFirstLoad";

@implementation SparkleManager

+ (id)sharedManager {
    static SparkleManager *result = nil;
    if (!result) {
        result = [[SparkleManager alloc] init];
    }
    return result;
}

- (id)init {
    self = [super init];
    if (self) {
        _canUpdate = NO;
    }
    return self;
}

- (void)dealloc {
    [_updater setDelegate:nil];
    [super dealloc];
}

- (BOOL)canUpdate {
    return _canUpdate;
}

- (SUUpdater*)_updater {
    if (_updater)
        return _updater;
    
    NSString *frameworksPath = [[NSBundle bundleForClass:[self class]] privateFrameworksPath];
    NSAssert(frameworksPath, nil);
    
    NSString *sparkleFrameworkPath = [NSBundle pathForResource:@"Sparkle" ofType:@"framework" inDirectory:frameworksPath];
    NSAssert(sparkleFrameworkPath, nil);
    
    NSBundle *sparkleFramework = [NSBundle bundleWithPath:sparkleFrameworkPath];
    NSAssert(sparkleFramework, nil);
    
    NSError *error = nil;
    BOOL loaded = [sparkleFramework loadAndReturnError:&error];
    if (loaded) {
        NSBundle *clickToFlashBundle = [NSBundle bundleWithIdentifier:@"com.github.rentzsch.clicktoflash"];
        NSAssert(clickToFlashBundle, nil);
        
        Class updaterClass = objc_getClass("SUUpdater");
        NSAssert(updaterClass, nil);
        
		if ([updaterClass respondsToSelector:@selector(updaterForBundle:)]) {
			_canUpdate = YES;
			_updater = [updaterClass updaterForBundle:clickToFlashBundle];
			NSAssert(_updater, nil);
			
			[_updater setDelegate:self];
		}
    }
    
    if (error) NSLog(@"error loading ClickToFlash's Sparkle: %@", error);
    
    return _updater;
}

- (void)startAutomaticallyCheckingForUpdates {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:sAutomaticallyCheckForUpdates]) {
        // If the key isn't set yet, default to YES, automatically check for updates.
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:sAutomaticallyCheckForUpdates];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:sAutomaticallyCheckForUpdates]) {
        static BOOL checkedForUpdate = NO;
        if (!checkedForUpdate) {
            checkedForUpdate = YES;
            
			SUUpdater *updater = [self _updater];
            if (_canUpdate) {
                [updater checkForUpdatesInBackground];
                [updater setAutomaticallyChecksForUpdates:YES];
            }
        }
    }
}

- (void)checkForUpdates {
    [[self _updater] checkForUpdates:nil];
}

- (NSString*)pathToRelaunchForUpdater:(SUUpdater*)updater {
    return _pathToRelaunch;
}

- (NSString *)pathToRelaunch
{
	return _pathToRelaunch;
}
- (void)setPathToRelaunch:(NSString *)newValue
{
	[newValue retain];
	[_pathToRelaunch release];
	_pathToRelaunch = newValue;
}

@end

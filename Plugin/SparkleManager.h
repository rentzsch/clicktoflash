//
//  SparkleManager.h
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-10-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Plugin.h"
#import "CTFUserDefaultsController.h"


@interface SparkleManager : NSObject {
	NSTimer *updaterTimer;
}

+ (id)sharedManager;

- (void)automaticallyCheckForUpdates;
- (void)checkForUpdatesNow;
- (void)setAutomaticallyChecksForUpdates:(BOOL)autoChecks;

@end

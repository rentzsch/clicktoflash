//
//  HarnessAppDelegate.h
//  ClickToFlash
//
//  Created by Ben Gottlieb on 2/9/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CTFWhitelistWindowController.h"


@interface HarnessAppDelegate : NSObject {
	CTFWhitelistWindowController				*_whitelistWindow;
}


- (IBAction) showWhitelistWindow: (id) sender;
@end

//
//  HarnessAppDelegate.m
//  ClickToFlash
//
//  Created by Ben Gottlieb on 2/9/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "HarnessAppDelegate.h"

@implementation HarnessAppDelegate

- (void) awakeFromNib {
	[self showWhitelistWindow: nil];
}

- (IBAction) showWhitelistWindow: (id) sender {
	if (_whitelistWindow == nil) _whitelistWindow = [[CTFWhitelistWindowController alloc] init];
	
	[[_whitelistWindow window] makeKeyAndOrderFront: nil];
}


@end

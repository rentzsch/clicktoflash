//
//  CTFInvisibleItemMenuController.h
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-02-02.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CTFClickToFlashPlugin;

@interface CTFInvisibleItemMenuController : NSObject {
	IBOutlet NSMenuItem *theMenu;
	IBOutlet NSMenuItem *loadInvisibleContentMenuItem;
	id plugin;
	NSMutableArray *targets;
}

@property (retain) CTFClickToFlashPlugin *plugin;
@property (retain) NSMutableArray *targets;

- (IBAction)loadInvisibleFlashContent:(id)sender;
- (NSMenuItem *)menu;
- (NSMenuItem *)loadInvisibleContentMenuItem;

@end

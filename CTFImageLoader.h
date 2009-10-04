//
//  CTFKillerImageLoader.h
//  ClickToFlash
//
//  Created by  Sven on 04.10.09.
//  Copyright 2009 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CTFClickToFlashPlugin;

@interface CTFImageLoader : NSObject {
	NSMutableData * data;
	CTFClickToFlashPlugin * plugin;
}

- (id) initWithURL: (NSURL *) theURL forPlugin: (CTFClickToFlashPlugin *) thePlugin;
- (void) cleanup;

@end

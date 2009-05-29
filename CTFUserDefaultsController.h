//
//  CTFUserDefaultsController.h
//  ClickToFlash
//
//  Created by Simone Manganelli on 2009-05-23.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CTFPreferencesDictionary.h"


@interface CTFUserDefaultsController : NSUserDefaultsController {
	CTFPreferencesDictionary *userDefaultsDict;
}

- (void)pluginDefaultsDidChange:(NSNotification *)notification;
- (void)setValues:(CTFPreferencesDictionary *)newUserDefaultsDict;

@end

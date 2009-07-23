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
	BOOL hasInited;
}

+ (CTFUserDefaultsController *)standardUserDefaults;
- (void)setUpExternalPrefsDictionary;

- (void)pluginDefaultsDidChange:(NSNotification *)notification;
- (CTFPreferencesDictionary *)values;
- (CTFPreferencesDictionary *)dictionaryRepresentation;
- (void)setValues:(CTFPreferencesDictionary *)newUserDefaultsDict;

- (id)objectForKey:(NSString *)defaultName;
- (void)setObject:(id)value forKey:(NSString *)defaultName;
- (int)integerForKey:(NSString *)defaultName;
- (void)setIntegerForKey:(int)value forKey:(NSString *)defaultName;
- (BOOL)boolForKey:(NSString *)defaultName;
- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;
- (NSArray *)arrayForKey:(NSString *)defaultName;
- (void)removeObjectForKey:(NSString *)defaultName;


@end

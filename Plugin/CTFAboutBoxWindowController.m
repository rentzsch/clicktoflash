/*
  CTFAboutBoxWindowController.m
  ClickToFlash

  Created by Sven on 04.09.09.
  Copyright 2009 earthlingsoft. All rights reserved.
*/

#import "CTFAboutBoxWindowController.h"


@implementation CTFAboutBoxWindowController

- (id)init
{
    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    NSString *nibPath = [myBundle pathForResource:@"AboutBox" ofType:@"nib"];
    if (nibPath == nil) {
        [self dealloc];
        return nil;
    }
    
    self = [super initWithWindowNibPath: nibPath owner: self];
	
    return self;
}


- (NSString*) versionString {
	NSBundle * myBundle = [NSBundle bundleForClass:[self class]];
	return [myBundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}


- (NSAttributedString*) aboutText {
	NSBundle * myBundle = [NSBundle bundleForClass:[self class]];
	NSString * creditsPath = [myBundle pathForResource:@"Credits" ofType:@"html"];
	NSDictionary * attributes;
	NSAttributedString * credits = [[[NSAttributedString alloc] initWithURL:[NSURL fileURLWithPath:creditsPath] documentAttributes:&attributes] autorelease];
	return credits;
}


- (NSString*) copyright {
	NSBundle * myBundle = [NSBundle bundleForClass:[self class]];
	NSString * copyright = [[myBundle localizedInfoDictionary] objectForKey:@"NSHumanReadableCopyright"];
	return copyright;
}


@end

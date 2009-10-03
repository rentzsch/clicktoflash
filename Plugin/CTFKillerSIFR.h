//
//  CTFKillerSiFR.h
//  ClickToFlash
//
//  Created by  Sven on 02.10.09.
//  Copyright 2009 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CTFKiller.h"


@interface CTFKillerSIFR : CTFKiller {
	NSUInteger sifrVersion;
}


+ (BOOL) isSIFRText: (NSDictionary*) attributes;

- (NSUInteger) sifrVersionInstalled;
- (BOOL) shouldDeSIFR;
+ (BOOL) shouldAutoLoadSIFR;
- (void) disableSIFR;

@end

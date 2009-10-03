//
//  CTFKillerVimeo.h
//  ClickToFlash
//
//  Created by  Sven on 03.10.09.
//  Copyright 2009 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CTFKillerVideo.h"

@interface CTFKillerVimeo : CTFKillerVideo {
	NSString * clipID;
	NSString * clipSignature;
	NSString * clipExpires;
	
	BOOL clipIsMP4;
	BOOL clipIsHD;
	
	NSMutableData * downloadData;
}


- (void) getXML;
- (void) finishXMLFetching;
- (void) finishHEADFetching: (NSURLConnection *) connection;
- (BOOL) isFetchingXML;
- (BOOL) isFetchingHEAD;
- (BOOL) isProcessing;

- (BOOL) hasMP4URL;
- (NSString *) MP4URLString;
- (NSString *) MP4HDURLString;
- (BOOL) hasHDVersion;
- (BOOL) useHDVersion;

- (NSString *)clipID;
- (void)setClipID:(NSString *)newClipID;
- (NSString *)clipSignature;
- (void)setClipSignature:(NSString *)newClipSignature;
- (NSString *)clipExpires;
- (void)setClipExpires:(NSString *)newClipExpires;


@end

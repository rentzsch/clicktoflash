//
//  CTFKillerYouTube.h
//  ClickToFlash
//
//  Created by  Sven on 02.10.09.
//  Copyright 2009 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CTFKillerVideo.h"


@interface CTFKillerYouTube : CTFKillerVideo {
	NSString * videoID;
	NSString * videoHash;
	BOOL hasH264Version;
	BOOL hasH264HDVersion;
		
	NSURLConnection *connections[2];
	unsigned expectedResponses;
	BOOL receivedAllResponses;
}


+ (BOOL) isYouTubeSiteURL: (NSURL*) theURL;
- (BOOL) youTubeAutoPlay;

- (void) _checkForH264VideoVariants;
- (void) _didRetrieveEmbeddedPlayerFlashVars:(NSDictionary *)flashVars;
- (void) _retrieveEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:(NSString *)videoId;
- (NSDictionary*) _flashVarDictionaryFromYouTubePageHTML: (NSString*) youTubePageHTML;
- (void) _getEmbeddedPlayerFlashVarsAndCheckForVariantsWithVideoId:(NSString *)videoId;

- (IBAction) loadH264:(id)sender;
- (IBAction) loadH264SD:(id)sender;
- (IBAction) loadH264HD:(id)sender;
- (void) downloadH264UsingHD: (BOOL) useHD;
- (IBAction) downloadH264:(id)sender;
- (IBAction) downloadH264SD:(id)sender;
- (IBAction) downloadH264HD:(id)sender;

- (void) convertToMP4ContainerUsingHD: (NSNumber*) useHD;

- (NSString *) H264URLString;
- (NSString *) H264HDURLString;
- (BOOL) hasH264Version;
- (void) setHasH264Version:(BOOL)newValue;
- (BOOL) hasH264HDVersion;
- (void) setHasH264HDVersion:(BOOL)newValue;
- (BOOL) useH264Version;
- (BOOL) useH264HDVersion;

- (NSString *) videoID;
- (void) setVideoID:(NSString *)newVideoID;
- (NSString *) videoHash;

@end

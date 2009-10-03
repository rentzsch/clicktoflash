/*
 CTFKillerYouTube.h
 ClickToFlash
 
 The MIT License
 
 Copyright (c) 2009 ClickToFlash Developers
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */ 


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

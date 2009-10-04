/*
 CTFKillerVideo.h
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
#import "CTFKiller.h"

static NSString *sUseYouTubeH264DefaultsKey = @"useYouTubeH264";
static NSString *sUseYouTubeHDH264DefaultsKey = @"useYouTubeHDH264";
static NSString *sYouTubeAutoPlay = @"enableYouTubeAutoPlay";


@class DOMElement;

enum CTFKVLookupStatus {
	nothing = 0,
	inProgress = 1,
	finished = 2,
	failed = 3
};

@interface CTFKillerVideo : CTFKiller {
	BOOL autoPlay;
	BOOL hasVideo;
	BOOL hasVideoHD;
	
	enum CTFKVLookupStatus lookupStatus;
	BOOL requiresConversion;
	
	NSSize videoSize;
	NSURL * previewURL;
}

/*
 Subclasses use setHasVideo and setHasVideoHD to indicate when they have determined movie paths.
 They set lookupStatus to indicate whether they are still busy doing lookups. Doing this will cause a redraw which can then alter the label text.
*/


// to be implemented by subclasses if they want to

// Name of the video service that can be used for automatic link text generation 
- (NSString*) siteName;

// URL to the video file used for loading it in the player.
- (NSString*) videoURLString;
- (NSString*) videoHDURLString;

// URL for downloading the video file. Return nil to use the same URL the video element uses.
- (NSString *) videoDownloadURLString;
- (NSString *) videoHDDownloadURLString;

// Text used for video file download link. Return nil to use standard text.
- (NSString *) videoDownloadLinkText;

// URL of the web page displaying the video. Return nil if there is none.
- (NSString *) videoPageURLString;

// Text used for link to video page. Return nil to use standard text.
- (NSString *) videoPageLinkText;

// Edit or replace the markup that is added for the links beneath the video. The descriptionElement passed to the method already conatins Go to Webpage and Download Video File links.
- (DOMElement *) enhanceVideoDescriptionElement: (DOMElement*) descriptionElement;

// Indicate whether the current web page is the 'canonical' web page for the video. The default implementation compares the videoPageURLString with the current page's URL for that
- (BOOL) isOnVideoPage;



// Actions
- (IBAction) loadVideo:(id)sender;
- (IBAction) loadVideoSD:(id)sender;
- (IBAction) loadVideoHD:(id)sender;
- (void) downloadVideoUsingHD: (BOOL) useHD;
- (IBAction) downloadVideo: (id) sender;
- (IBAction) downloadVideoSD: (id) sender;
- (IBAction) downloadVideoHD: (id) sender;

// Internal stuff
- (void) _convertElementForMP4: (DOMElement*) element atURL: (NSString*) URLString;
- (void) _convertElementForVideoElement: (DOMElement*) element atURL: (NSString*) URLString;
- (void) convertToMP4ContainerUsingHD: (NSNumber*) useHD;
- (void) _convertToMP4ContainerAfterDelayUsingHD: (NSNumber*) useHDNumber;
- (void) convertToMP4ContainerAtURL: (NSString*) URLString;
- (DOMElement*) linkContainerElementForURL: (NSString*) URLString;

// Helpers
- (BOOL) useVideo;
- (BOOL) useVideoHD;
- (NSString *) videoURLStringForHD: (BOOL) useHD;
- (NSString *) cleanURLString: (NSString*) URLString;
- (BOOL) isVideoElementAvailable;
- (void) finishedLookups;

// Accessors
- (BOOL) autoPlay;
- (void) setAutoPlay:(BOOL)newAutoPlay;
- (BOOL) hasVideo;
- (void) setHasVideo:(BOOL)newHasVideo;
- (BOOL) hasVideoHD;
- (void) setHasVideoHD:(BOOL)newHasVideoHD;
- (enum CTFKVLookupStatus) lookupStatus;
- (void) setLookupStatus: (enum CTFKVLookupStatus) newLookupStatus;
- (BOOL)requiresConversion;
- (void)setRequiresConversion:(BOOL)newRequiresConversion;
- (NSURL *) previewURL;
- (void) setPreviewURL: (NSURL *) newPreviewURL;


@end

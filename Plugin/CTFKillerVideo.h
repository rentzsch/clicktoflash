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

// static NSString *sDisableVideoElement;
static NSString *sUseYouTubeH264DefaultsKey = @"useYouTubeH264";
static NSString *sUseYouTubeHDH264DefaultsKey = @"useYouTubeHDH264";
static NSString *sYouTubeAutoPlay = @"enableYouTubeAutoPlay";


@class DOMElement;

@interface CTFKillerVideo : CTFKiller {
	BOOL autoPlay;
	
	NSSize videoSize;
	NSURL * previewURL;
}

// to be implemented by subclasses if appropriate
- (NSString *) videoPageURLString;
- (NSString *) videoPageLinkText;
- (NSString *) videoDownloadURLString;
- (NSString *) videoDownloadLinkText;
- (DOMElement *) enhanceVideoDescriptionElement: (DOMElement*) descriptionElement;

//
- (BOOL) isOnVideoPage;


// internal stuff
- (void) _convertElementForMP4: (DOMElement*) element atURL: (NSString*) URLString;
- (void) _convertElementForVideoElement: (DOMElement*) element atURL: (NSString*) URLString;
- (void) convertToMP4ContainerAtURL: (NSString*) URLString;
- (DOMElement*) linkContainerElementForURL: (NSString*) URLString;

- (BOOL) isVideoElementAvailable;

- (NSURL *)previewURL;
- (void)setPreviewURL:(NSURL *)newPreviewURL;


@end

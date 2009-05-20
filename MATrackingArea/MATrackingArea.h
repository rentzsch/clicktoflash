//
//  MATrackingArea.h
//  MATrackingArea
//
//  Created by Matt Gemmell on 25/09/2007.
//

#import <Cocoa/Cocoa.h>

/*
 Type of tracking area. You must specify one or more types from this list in the
 MATrackingAreaOptions argument of -initWithRect:options:owner:userInfo:
 */
enum {
    // Owner receives mouseEntered when mouse enters area, and mouseExited when mouse leaves area.
    MATrackingMouseEnteredAndExited     = 0x01,

    // Owner receives mouseMoved while mouse is within area. Note that mouseMoved events do not
    // contain userInfo.
    MATrackingMouseMoved                = 0x02,
};

/*
 When the tracking area is active. You must specify exactly one of the following in the
 MATrackingAreaOptions argument of -initWithRect:options:owner:userInfo:
 */
enum {
    // Owner receives mouseEntered/Exited or mouseMoved when view is first responder.
    MATrackingActiveWhenFirstResponder 	= 0x10,

    // Owner receives mouseEntered/Exited or mouseMoved when view is in key window.
    MATrackingActiveInKeyWindow         = 0x20,

    // Owner receives mouseEntered/Exited or mouseMoved when app is active.
    MATrackingActiveInActiveApp 	= 0x40,

    // Owner receives mouseEntered/Exited or mouseMoved regardless of activation.
    MATrackingActiveAlways 		= 0x80,
};

/*
 Behavior of tracking area. You may specify any number of the following in the
 MATrackingAreaOptions argument of -initWithRect:options:owner:userInfo:
 */
enum {
    // If set, generate mouseExited event when mouse leaves area (same as assumeInside argument
    // in NSView's addtrackingArea:owner:userData:assumeInside: method).
    MATrackingAssumeInside              = 0x100,

    // If set, tracking occurs in visibleRect of view and rect is ignored.
    MATrackingInVisibleRect             = 0x200,

    // If set, mouseEntered events will be generated as mouse is dragged. If not set, mouseEntered
    // events will be generated as mouse is moved, and on mouseUp after a drag.  mouseExited
    // events are paired with mouseEntered events so their delivery is affected indirectly.
    // That is, if a mouseEntered event is generated and the mouse subsequently moves out of the
    // trackingArea, a mouseExited event will be generated whether the mouse is being moved or
    // dragged, independent of this flag.
    MATrackingEnabledDuringMouseDrag    = 0x400
};

typedef unsigned int MATrackingAreaOptions;

@interface MATrackingArea : NSObject <NSCopying, NSCoding>
{
    @private
    NSRect _rect;
    MATrackingAreaOptions _options;
    __weak id _owner;
    NSDictionary * _userInfo;
    NSPoint _lastMovedPoint;
    BOOL _inside;
}

+ (void)addTrackingArea:(MATrackingArea *)trackingArea toView:(NSView *)view;
+ (void)removeTrackingArea:(MATrackingArea *)trackingArea fromView:(NSView *)view;
+ (NSArray *)trackingAreasForView:(NSView *)view;

- (MATrackingArea *)initWithRect:(NSRect)rect
                         options:(MATrackingAreaOptions)options
                           owner:(id)owner
                        userInfo:(NSDictionary *)userInfo;
- (NSRect)rect;
- (void)setRect:(NSRect)newRect;
- (MATrackingAreaOptions)options;
- (id)owner;
- (NSDictionary *)userInfo;

@end

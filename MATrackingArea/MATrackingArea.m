//
//  MATrackingArea.m
//  MATrackingArea
//
//  Created by Matt Gemmell on 25/09/2007.
//  Copyright 2007 Magic Aubergine.
//

#import "MATrackingArea.h"
#import <Carbon/Carbon.h>

#define MA_POLLING_INTERVAL 0.1

static NSTimer *_pollingTimer;
static NSMutableArray *_views;
static NSMutableArray *_trackingAreas; // 2-dimensional

/* NSWindow category by Jonathan 'Wolf' Rentzsch http://rentzsch.com */
@interface NSWindow (liveFrame)
- (NSRect)liveFrame;
- (NSRect)convertLiveBaseRectToScreen:(NSRect)rect;
@end
@implementation NSWindow (liveFrame)
// This method is because -[NSWindow frame] isn't updated continually during a drag.
- (NSRect)liveFrame {
    Rect qdRect;
    GetWindowBounds([self windowRef], kWindowStructureRgn, &qdRect);

    return NSMakeRect(qdRect.left,
                      (float)CGDisplayPixelsHigh(kCGDirectMainDisplay) - qdRect.bottom,
                      qdRect.right - qdRect.left,
                      qdRect.bottom - qdRect.top);
}
- (NSRect)convertLiveBaseRectToScreen:(NSRect)rect {
    NSRect liveFrame = [self liveFrame];
    return NSMakeRect(liveFrame.origin.x + rect.origin.x,
                      liveFrame.origin.y + rect.origin.y,
                      rect.size.width,
                      rect.size.height);
}
@end

@interface MATrackingArea (PrivateMethods)

+ (void)checkMouseLocation:(NSTimer *)theTimer;
- (NSPoint)_lastMovedPoint;
- (void)_setLastMovedPoint:(NSPoint)pt;
- (BOOL)_inside;
- (void)_setInside:(BOOL)inside;
- (void)_setNotInside;

@end

@implementation MATrackingArea


#pragma mark Class methods


+ (void)initialize
{
    _views = [[NSMutableArray alloc] initWithCapacity:0];
    _trackingAreas = [[NSMutableArray alloc] initWithCapacity:0];
}


+ (void)checkMouseLocation:(NSTimer*)theTimer
{
    // This is where the action happens.
    NSPoint mouseLoc = [NSEvent mouseLocation];
    NSEnumerator *viewsEnumerator = [_views objectEnumerator];
    NSView *view;
    int index = 0;

    while ((view = [viewsEnumerator nextObject])) {
        NSWindow *window = [view window];
        if (!window) {
            // Pointer can't be inside a view with no window.
            int viewIndex = [_views indexOfObject:view];
            [[_trackingAreas objectAtIndex:viewIndex] makeObjectsPerformSelector:@selector(_setNotInside)];
            continue;
        }

        NSPoint mouseInWindow = [window convertScreenToBase:mouseLoc];
        NSPoint mouseInView = [view convertPoint:mouseInWindow fromView:nil];
        NSEnumerator *trackingAreaEnumerator = [[_trackingAreas objectAtIndex:index] objectEnumerator];
        MATrackingArea *area;

        while ((area = [trackingAreaEnumerator nextObject])) {
            MATrackingAreaOptions options = [area options];
            NSRect trackingRect = (options & MATrackingInVisibleRect)
                ? [view visibleRect]
                : [area rect];
            BOOL nowInside = NSPointInRect(mouseLoc, [window convertLiveBaseRectToScreen:[view convertRect:trackingRect toView:nil]]);
            BOOL wasInside = [area _inside];
            NSEventType eventType = NSApplicationDefined;

            // Determine whether to inform the view.
            if (!(options & MATrackingActiveAlways)) {
                if (options & MATrackingActiveInActiveApp) {
                    if (![NSApp isActive]) {
                        continue;
                    }
                } else if (options & MATrackingActiveInKeyWindow) {
                    if (![NSApp isActive] || ![window isKeyWindow]) {
                        continue;
                    }
                } else if (options & MATrackingActiveWhenFirstResponder) {
                    if (![NSApp isActive] || ![window isKeyWindow] ||
                        !([window firstResponder] == view)) {
                        continue;
                    }
                }
            }
            // Check whether the mouse is currently being dragged
            UInt32 state;
            BOOL dragging = NO;
            if ([NSApp isActive]) {
                state = GetCurrentEventButtonState();
            } else {
                state = GetCurrentButtonState();
            }
            if ((state & 0x01) || (state & 0x02) || (state & 0x03)) {
                dragging = YES;
            }
            if (!(options & MATrackingEnabledDuringMouseDrag) && dragging) {
                continue;
            }

            // Determine what happened.
            if (nowInside && !wasInside && (options & MATrackingMouseEnteredAndExited)) {
                // Entered
                eventType = NSMouseEntered;
                [area _setInside:YES];
            } else if (!nowInside && wasInside && (options & MATrackingMouseEnteredAndExited)) {
                // Exited
                eventType = NSMouseExited;
                [area _setInside:NO];
            } else if (nowInside && (options & MATrackingMouseMoved)) {
                if (wasInside && !NSEqualPoints(mouseInView, [area _lastMovedPoint])) {
                    // Moved
                    eventType = NSMouseMoved;
                    [area _setLastMovedPoint:mouseInView];
                } else if (!wasInside) {
                    // Make sure we get a moved event next time
                    [area _setInside:YES];
                }
            }

            // Construct an appropriate event.
            NSEvent *event = nil;
            switch (eventType) {
                case NSMouseEntered:
                case NSMouseExited:
                    event = [NSEvent enterExitEventWithType:eventType
                                                   location:mouseInWindow
                                              modifierFlags:eventType
                                                  timestamp:0
                                               windowNumber:[window windowNumber]
                                                    context:nil
                                                eventNumber:0
                                             trackingNumber:0
                                                   userData:[area userInfo]];
                    break;
                case NSMouseMoved:
                    event = [NSEvent mouseEventWithType:eventType
                                               location:mouseInWindow
                                          modifierFlags:eventType
                                              timestamp:0
                                           windowNumber:[window windowNumber]
                                                context:nil
                                            eventNumber:0
                                             clickCount:0
                                               pressure:0.0];
                    break;
            }

            // Send event.
            id owner = [area owner];
            switch (eventType) {
                case NSMouseEntered:
                    [owner mouseEntered:event];
                    break;
                case NSMouseExited:
                    [owner mouseExited:event];
                    break;
                case NSMouseMoved:
                    [owner mouseMoved:event];
                    break;
            }
        }

        index++;
    }
}


+ (void)addTrackingArea:(MATrackingArea *)trackingArea toView:(NSView *)view
{
    if (!trackingArea || !view) {
        return;
    }

    // Validate options
    MATrackingAreaOptions options = [trackingArea options];
    if (!(options & MATrackingMouseEnteredAndExited) &&
        !(options & MATrackingMouseMoved)) {
        // trackingArea's options don't contain any of the 'type' masks.
        return;
    } else if (!(options & MATrackingActiveAlways) &&
               !(options & MATrackingActiveInActiveApp) &&
               !(options & MATrackingActiveInKeyWindow) &&
               !(options & MATrackingActiveWhenFirstResponder)) {
        // trackingArea's options don't contain any of the 'when' masks.
        return;
    }

    int index = [_views indexOfObject:view];
    if (index == NSNotFound) {
        // Add view to _views and create appropriate entry in _trackingAreas.
        [_views addObject:view];
        NSMutableArray *trackingAreasForView = [NSMutableArray arrayWithCapacity:1];
        [trackingAreasForView addObject:trackingArea];
        [_trackingAreas addObject:trackingAreasForView];
    } else {
        // Add trackingArea to appropriate entry in _trackingAreas.
        NSMutableArray *trackingAreasForView = [_trackingAreas objectAtIndex:index];
        if (![trackingAreasForView containsObject:trackingArea]) {
            [trackingAreasForView addObject:trackingArea];
        }
    }

    // Support for MATrackingAssumeInside
    if (options & MATrackingAssumeInside) {
        [trackingArea _setInside:YES];
    }

    // Create Polling Timer Of Extreme Evil if appropriate.
    if (!_pollingTimer) {
        _pollingTimer = [[NSTimer scheduledTimerWithTimeInterval:MA_POLLING_INTERVAL
                                                          target:[self class]
                                                        selector:@selector(checkMouseLocation:)
                                                        userInfo:nil
                                                         repeats:YES] retain];
    }
}


+ (void)removeTrackingArea:(MATrackingArea *)trackingArea fromView:(NSView *)view
{
    if (!trackingArea || !view) {
        return;
    }

    int index = [_views indexOfObject:view];
    if (index == NSNotFound) {
        // We don't have any trackingAreas for that view.
        return;
    }

    NSMutableArray *trackingAreasForView = [_trackingAreas objectAtIndex:index];
    if (![trackingAreasForView containsObject:trackingArea]) {
        // We don't know anything about that trackingArea.
        return;
    } else {
        // Remove the trackingArea as requested.
        [trackingAreasForView removeObject:trackingArea];
    }

    // If there are no more trackingAreas for this view, remove it.
    if ([trackingAreasForView count] == 0) {
        [_trackingAreas removeObjectAtIndex:index];
        [_views removeObjectAtIndex:index];
    }

    // Destroy timer if appropriate.
    if ([_views count] == 0) {
        [_pollingTimer invalidate];
        [_pollingTimer release];
        _pollingTimer = nil;
    }
}


+ (NSArray *)trackingAreasForView:(NSView *)view
{
    if (view) {
        int index = [_views indexOfObject:view];
        if (index != NSNotFound) {
            return [NSArray arrayWithArray:[_trackingAreas objectAtIndex:index]];
        }
    }
    return nil;
}


#pragma mark Instance methods


- (MATrackingArea *)initWithRect:(NSRect)rect
                         options:(MATrackingAreaOptions)options
                           owner:(id)owner
                        userInfo:(NSDictionary *)userInfo
{
    if ((self = [super init])) {
        _rect = rect;
        _options = options;
        _owner = owner;
        _userInfo = [userInfo retain];
        _lastMovedPoint = NSZeroPoint;
        _inside = NO;
    }
    return self;
}


- (void)dealloc
{
    [_userInfo release];
    [super dealloc];
}


- (NSRect)rect
{
    return _rect;
}


- (void)setRect:(NSRect)newRect
{
    _rect = newRect;
    [MATrackingArea checkMouseLocation:nil];
}


- (MATrackingAreaOptions)options
{
    return _options;
}


- (id)owner
{
    return _owner;
}


- (NSDictionary *)userInfo
{
    return [[_userInfo retain] autorelease];
}


- (NSPoint)_lastMovedPoint
{
    return _lastMovedPoint;
}


- (void)_setLastMovedPoint:(NSPoint)pt
{
    _lastMovedPoint = pt;
}


- (BOOL)_inside
{
    return _inside;
}


- (void)_setInside:(BOOL)inside
{
    _inside = inside;
}


- (void)_setNotInside
{
    [self _setInside:NO];
}


#pragma mark NSCopying


- (id)copyWithZone:(NSZone *)zone
{
    MATrackingArea *copy = (MATrackingArea *)[[[self class] allocWithZone:zone]
                            initWithRect:[self rect]
                                 options:[self options]
                                   owner:[self owner]
                                userInfo:[self userInfo]];
    return copy;
}


#pragma mark NSCoding


- (id)initWithCoder:(NSCoder *)coder
{
    NSRect rect = [coder decodeRectForKey:@"_rect"];
    MATrackingAreaOptions options = [coder decodeIntForKey:@"_options"];
    NSDictionary *userInfo = [coder decodeObjectForKey:@"_userInfo"];
    id owner = [coder decodeObjectForKey:@"_owner"];

    self = (MATrackingArea *)[[MATrackingArea alloc] initWithRect:rect
                                        options:options
                                          owner:owner
                                       userInfo:userInfo];
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeRect:_rect forKey:@"_rect"];
    [coder encodeInt:_options forKey:@"_options"];
    [coder encodeObject:_userInfo forKey:@"_userInfo"];
    [coder encodeConditionalObject:_owner forKey:@"_owner"];
}


@end

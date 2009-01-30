//
//  NSBezierPath-RoundedRectangle.h
//	Based on http://www.cocoadev.com/index.pl?RoundedRectangles
//	Switched to a function instead of a category class method for use in a plug-in.
//

#import <Cocoa/Cocoa.h>

/**
 Returns a closed bezier path describing a rectangle with curved corners
 The corner radius will be trimmed to not exceed half of the lesser rectangle dimension.
 */
NSBezierPath* bezierPathWithRoundedRectCornerRadius( NSRect aRect, double radius );
